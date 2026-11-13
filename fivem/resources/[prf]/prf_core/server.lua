-- PRF RP standalone: somente o servidor controla turno, frota e ocorrências.
local onDuty, calls, completed, lastCallIndex, lastAction = {}, {}, {}, {}, {}
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
local function clearCall(src)
  calls[src] = nil
  TriggerClientEvent('prfrp:setCall', src, false)
end
local function toggleDuty(src)
  if src == 0 or throttle(src, 'duty', 2) then return end
  if not authorized(src) then
    notify(src, 'Acesso PRF negado. Configure seu identificador com add_ace.')
    return
  end
  local enabled = not onDuty[src]
  onDuty[src] = enabled or nil
  if not enabled then
    clearCall(src)
    TriggerEvent('prfrp:ops:dutyEnded', src)
  end
  TriggerClientEvent('prfrp:setDuty', src, enabled)
  notify(src, enabled and 'Turno iniciado. F6: menu | F9: viatura | F7: COPOM.' or 'Turno encerrado.')
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
  TriggerClientEvent('prfrp:spawnPatrol', src, selected, Config.Plate)
end
local function assignCall(src)
  if not requireDuty(src) or throttle(src, 'call', 3) then return end
  if calls[src] then
    notify(src, 'Ocorrencia em andamento. Confira o GPS ou cancele pelo menu F6.')
    return
  end
  local total = #Config.Calls
  if total == 0 then notify(src, 'Nao ha ocorrencias configuradas.'); return end
  local index = math.random(total)
  if total > 1 and index == lastCallIndex[src] then index = index % total + 1 end
  lastCallIndex[src] = index
  local incident = Config.Calls[index]
  calls[src] = { index = index, id = incident.id, stage = 1, started = os.time() }
  local payload = {}
  for k, value in pairs(incident) do payload[k] = value end
  payload.stage = 1
  TriggerClientEvent('prfrp:setCall', src, payload)
  notify(src, 'COPOM: ' .. incident.id .. ' | ' .. incident.name .. ' | GPS marcado.')
end
local function cancelCall(src)
  if not requireDuty(src) then return end
  if not calls[src] then notify(src, 'Nenhuma ocorrencia ativa.'); return end
  clearCall(src)
  notify(src, 'Ocorrencia cancelada.')
end
local function showStatus(src)
  if src == 0 then return end
  if not authorized(src) then notify(src, 'Sem permissao PRF.'); return end
  notify(src, (onDuty[src] and 'EM SERVICO' or 'FORA DE SERVICO') ..
    ' | Ocorrencias concluidas: ' .. (completed[src] or 0))
end
RegisterCommand('prfajuda', function(src)
  if src == 0 then
    print('PRF RP: F5 turno, F6 menu, F7 COPOM, F9 viatura, K fuzil')
    return
  end
  notify(src, 'F5 turno | F6 menu | F7 COPOM | F9 viatura | K arma | E interagir')
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

local function nearIncident(src, incident)
  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return false end
  local coords = GetEntityCoords(ped)
  if not coords then return false end
  local dx, dy, dz = coords.x - incident.x, coords.y - incident.y, coords.z - incident.z
  if dx * dx + dy * dy + dz * dz > 35 * 35 then
    notify(src, 'Aproxime-se do ponto da ocorrencia para concluir.')
    return false
  end
  return true
end

RegisterNetEvent('prfrp:advanceCall', function(id, stage)
  local src = source
  if not requireDuty(src) or throttle(src, 'stage', 2) then return end
  local current = calls[src]
  if not current or type(id) ~= 'string' or id ~= current.id then return end
  if type(stage) ~= 'number' or stage ~= current.stage then return end
  local incident = Config.Calls[current.index]
  if not incident or incident.id ~= id or not nearIncident(src, incident) then return end
  local total = #incident.steps
  if current.stage >= total then return end
  current.stage = current.stage + 1
  TriggerClientEvent('prfrp:setCallStage', src, id, current.stage)
  notify(src, 'Etapa concluida. Proximo: ' .. incident.steps[current.stage])
end)

RegisterNetEvent('prfrp:completeCall', function(id)
  local src = source
  if not requireDuty(src) or throttle(src, 'finish', 2) then return end
  local current = calls[src]
  if not current or type(id) ~= 'string' or id ~= current.id then return end
  local c = Config.Calls[current.index]
  if not c or c.id ~= id then return end
  if current.stage < #c.steps then
    notify(src, 'Conclua as etapas do atendimento antes de finalizar.')
    return
  end
  -- Distancia checada NO SERVIDOR; cliente nao pode forjar a posicao enviada.
  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return end
  local coords = GetEntityCoords(ped)
  if not coords then return end
  local dx, dy, dz = coords.x - c.x, coords.y - c.y, coords.z - c.z
  if dx * dx + dy * dy + dz * dz > 35 * 35 then
    notify(src, 'Aproxime-se do ponto da ocorrencia para concluir.')
    return
  end
  completed[src] = (completed[src] or 0) + 1
  clearCall(src)
  notify(src, c.id .. ' concluida! Total neste turno: ' .. completed[src])
end)
AddEventHandler('playerDropped', function()
  local src = source
  onDuty[src], calls[src], completed[src], lastCallIndex[src] = nil, nil, nil, nil
  for key in pairs(lastAction) do
    if key:sub(1, #tostring(src) + 1) == tostring(src) .. ':' then lastAction[key] = nil end
  end
end)
