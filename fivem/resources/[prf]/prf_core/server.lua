-- Nucleo standalone: a autorizacao do serviço vem do ACE do FXServer.
-- Eventos do cliente nunca podem conceder permissao, dinheiro ou XP.
local onDuty = {}
local calls = {}
local completed = {}
local lastCallIndex = {}
local lastAction = {}

local function notify(src, message)
  TriggerClientEvent('prfrp:notify', src, tostring(message))
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
    notify(src, 'Sem permissao PRF. Configure o ACE prfrp.officer no server.cfg.')
    return false
  end
  if not onDuty[src] then
    notify(src, 'Entre em servico com /prfservico.')
    return false
  end
  return true
end

local function clearCall(src)
  calls[src] = nil
  TriggerClientEvent('prfrp:setCall', src, false)
end

local function resourceReady(name)
  return not name or name == '' or GetResourceState(name) == 'started'
end

local function requestPatrol(src, fleetId)
  if not requireDuty(src) then return end
  local entry = Config.Fleet[fleetId]
  if not entry or type(entry.model) ~= 'string' or entry.model == '' then
    notify(src, 'Modelo ainda nao instalado/configurado: ' .. (entry and entry.label or fleetId) .. '.')
    return
  end
  if not resourceReady(entry.resource) then
    notify(src, 'Inicie o resource do veiculo: ' .. entry.resource .. '.')
    return
  end
  -- Mesmo intervalo para moto e SUV: alternar comandos nao contorna o limite.
  if throttle(src, 'vehicle', 8) then return end
  TriggerClientEvent('prfrp:spawnPatrol', src, fleetId)
end

RegisterCommand('prfajuda', function(src)
  if src == 0 then
    print('PRF RP: /prfservico /prfviatura /prfmoto /prfbase /prfchamado /prfcancelar /prfstatus /prfajuda')
    return
  end
  notify(src, '/prfservico | /prfviatura | /prfmoto | /prfbase | /prfchamado | /prfcancelar | /prfstatus')
end, false)

RegisterCommand('prfservico', function(src)
  if src == 0 then return end
  if throttle(src, 'duty', 2) then return end
  if not authorized(src) then
    notify(src, 'Acesso PRF negado. Configure seu identificador com add_ace.')
    return
  end
  local enabled = not onDuty[src]
  if enabled and not resourceReady(Config.Base.mapResource) then
    notify(src, 'Inicie o mapa da base antes de entrar em servico: ' .. Config.Base.mapResource .. '.')
    return
  end
  onDuty[src] = enabled or nil
  if not enabled then clearCall(src) end
  TriggerClientEvent('prfrp:setDuty', src, enabled)
  notify(src, enabled and 'Turno iniciado. Use /prfviatura, /prfmoto e /prfchamado.' or 'Turno encerrado.')
end, false)

RegisterCommand('prfviatura', function(src)
  requestPatrol(src, 'viatura')
end, false)

RegisterCommand('prfmoto', function(src)
  requestPatrol(src, 'moto')
end, false)

RegisterCommand('prfbase', function(src)
  if not requireDuty(src) then return end
  if not resourceReady(Config.Base.mapResource) then
    notify(src, 'Mapa da base indisponivel: ' .. Config.Base.mapResource .. '.')
    return
  end
  TriggerClientEvent('prfrp:routeBase', src)
end, false)

RegisterCommand('prfchamado', function(src)
  if not requireDuty(src) or throttle(src, 'call', 3) then return end
  if calls[src] then
    notify(src, 'Voce ja possui um chamado ativo. Veja o GPS ou use /prfcancelar.')
    return
  end
  local total = #Config.Calls
  if total == 0 then
    notify(src, 'Nao ha chamados configurados.')
    return
  end
  local index = math.random(total)
  if total > 1 and index == lastCallIndex[src] then index = index % total + 1 end
  lastCallIndex[src] = index
  local c = Config.Calls[index]
  calls[src] = { index = index, id = c.id, started = os.time() }
  TriggerClientEvent('prfrp:setCall', src, c)
  notify(src, c.id .. ' | ' .. c.name .. '. Local marcado no GPS.')
end, false)

RegisterCommand('prfcancelar', function(src)
  if not requireDuty(src) then return end
  if not calls[src] then
    notify(src, 'Nenhuma ocorrencia ativa.')
    return
  end
  clearCall(src)
  notify(src, 'Ocorrencia cancelada.')
end, false)

RegisterCommand('prfstatus', function(src)
  if src == 0 then return end
  if not authorized(src) then
    notify(src, 'Sem permissao PRF.')
    return
  end
  local status = onDuty[src] and 'EM SERVICO' or 'FORA DE SERVICO'
  notify(src, 'PRF RP: ' .. status .. ' | Chamados concluidos: ' .. (completed[src] or 0))
end, false)

RegisterNetEvent('prfrp:completeCall', function(id)
  local src = source
  if not requireDuty(src) or throttle(src, 'finish', 2) then return end
  local current = calls[src]
  if not current or type(id) ~= 'string' or id ~= current.id then return end
  local c = Config.Calls[current.index]
  if not c or c.id ~= id then return end

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
