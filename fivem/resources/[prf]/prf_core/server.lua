-- PRF RP standalone: somente o servidor controla turno, frota e ocorrências.
local onDuty, lastAction = {}, {}
local function notify(src, value)
  TriggerClientEvent('prfrp:notify', src, tostring(value))
end
local function authorized(src)
  return type(src) == 'number' and src > 0 and IsPlayerAceAllowed(src, 'prfrp.officer')
end
local function throttle(src, action, interval)
  local now = os.time()
  local key = tostring(src) .. ':' .. action
  if lastAction[key] and now - lastAction[key] < interval then return true end
  lastAction[key] = now
  return false
end
local function requireDuty(src)
  if not authorized(src) then
    notify(src, 'Sem permissao PRF. Configure ACE prfrp.officer no server.cfg.')
    return false
  end
  if not onDuty[src] then
    notify(src, 'Entre em servico pela tecla F5 ou /prfservico.')
    return false
  end
  return true
end
-- Disponivel apenas aos scripts de servidor deste recurso; nao e evento de rede.
PrfHasDuty = function(src) return authorized(src) and onDuty[src] == true end
local function clearCall(src) if PrfCancelCopom then PrfCancelCopom(src,true) end end
local function toggleDuty(src)
  if src == 0 or throttle(src, 'duty', 2) then return end
  if not authorized(src) then
    notify(src, 'Acesso PRF negado. Configure seu identificador com add_ace.')
    return
  end
  local enabled = not onDuty[src]
  if enabled then
    local profile,err=PrfLoadProfile(src)
    if not profile then notify(src,err);return end
  end
  onDuty[src] = enabled or nil
  if not enabled then
    clearCall(src)
    TriggerEvent('prfrp:ops:dutyEnded', src)
  end
  TriggerClientEvent('prfrp:setDuty', src, enabled)
  notify(src, enabled and 'Turno iniciado. T > viatura | abordar | documento | revistar | ajuda' or 'Turno encerrado.')
end
local function selectVehicle(src, model)
  if not requireDuty(src) or throttle(src, 'vehicle', 5) then return end
  local selected = Config.Vehicle
  if model ~= nil then
    if type(model) ~= 'string' then return end
    local found = false
    for _, vehicle in ipairs(Config.Fleet or {}) do
      if model == vehicle.model then selected = model; found = true; break end
    end
    if not found then notify(src, 'Viatura nao cadastrada na frota.'); return end
  end
  for _, vehicle in ipairs(Config.Fleet or {}) do
    if vehicle.model == selected and vehicle.resource
      and GetResourceState(vehicle.resource) ~= 'started'
      and (not vehicle.alternateResource or GetResourceState(vehicle.alternateResource) ~= 'started') then
      notify(src, 'Viatura PRF nao iniciou. Reinicie o servidor apos executar setup-prf-update.cmd.')
      return
    end
  end
  TriggerClientEvent('prfrp:spawnPatrol', src, selected, Config.Plate)
end
local function assignCall(src)
  if requireDuty(src) and not throttle(src,'call',3) then PrfAssignCopom(src) end
end
local function cancelCall(src)
  if requireDuty(src) then PrfCancelCopom(src) end
end
local function showStatus(src)
  if src == 0 then return end
  if not authorized(src) then notify(src, 'Sem permissao PRF.'); return end
  local profile=PrfLoadProfile(src)
  notify(src, (onDuty[src] and 'EM SERVICO' or 'FORA DE SERVICO') ..
    ' | Ocorrencias concluidas: ' .. (profile and profile.stats.calls or 0))
end
RegisterCommand('prfajuda', function(src)
  if src == 0 then
    print('PRF RP: T > servico, viatura, abordar, documento, revistar, ajuda')
    return
  end
  TriggerClientEvent('prfrp:chatCommand',src,'ajuda')
end, false)
RegisterCommand('prfservico', function(src) toggleDuty(src) end, false)
RegisterCommand('prfviatura', function(src, args) selectVehicle(src, args and args[1]) end, false)
RegisterCommand('prfchamado', function(src) assignCall(src) end, false)
RegisterCommand('prfcancelar', function(src) cancelCall(src) end, false)
RegisterCommand('prfstatus', function(src) showStatus(src) end, false)
RegisterCommand('prfassets', function(src)
  if src == 0 then return end
  if not authorized(src) then notify(src, 'Sem permissao PRF.'); return end
  notify(src, 'Base LN3D3V: ' .. GetResourceState('prfMiniLN3d3v') ..
    ' | Equinox PRF: ' .. GetResourceState('prf_equinox_replace') ..
    ' | Trailblazer PRF: ' .. GetResourceState('prf_trailblazer') ..
    ' | Farda PRF: ' .. GetResourceState('prf_skin_replace'))
end, false)


-- Ações de tecla/menu: a permissão é sempre conferida no servidor.
RegisterNetEvent('prfrp:requestAction', function(action, data)
  local src = source
  if type(action) ~= 'string' or #action > 32 then return end
  if action == 'duty' then toggleDuty(src)
  elseif action == 'vehicle' then selectVehicle(src, data)
  elseif action == 'call' then assignCall(src)
  elseif action == 'cancel' then cancelCall(src)
  elseif action == 'status' then showStatus(src)
  elseif action == 'uniform' or action == 'weapon' then
    if not requireDuty(src) or throttle(src, action, 1) then return end
    TriggerClientEvent(action == 'uniform' and 'prfrp:toggleUniform' or 'prfrp:toggleWeapon', src)
  end
end)

-- Os eventos antigos advanceCall/completeCall nao concedem mais progresso.
-- A resolucao das cenas e feita por copom_server.lua com evidencias de jogo.
AddEventHandler('playerDropped', function()
  local src = source
  onDuty[src] = nil
  for key in pairs(lastAction) do
    if key:sub(1, #tostring(src) + 1) == tostring(src) .. ':' then lastAction[key] = nil end
  end
end)
