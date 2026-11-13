-- Operacoes ficticias. Nao consulta documentos reais, inventarios ou bancos externos.
local inspections, missions, cooldowns, missionIndex = {}, {}, {}, {}
local owners = { 'Carlos Pereira', 'Ana Souza', 'Joao Oliveira', 'Marcos Lima' }
local enemyModels = { 'g_m_y_ballaeast_01', 'g_m_y_mexgoon_02' }

local function notify(src, message)
  TriggerClientEvent('prfrp:operationsNotify', src, message)
end
local function allowed(src)
  if type(src) ~= 'number' or src <= 0 or not PrfHasDuty or not PrfHasDuty(src) then
    notify(src, 'Entre em servico autorizado com F5 para usar as operacoes.')
    return false
  end
  return true
end
local function throttle(src, action, seconds)
  cooldowns[src] = cooldowns[src] or {}
  local previous = cooldowns[src][action]
  if previous and os.time() - previous < seconds then return true end
  cooldowns[src][action] = os.time()
  return false
end
local function near(src, point, radius)
  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return false end
  local p = GetEntityCoords(ped)
  return (p.x-point.x)^2 + (p.y-point.y)^2 + (p.z-point.z)^2 <= radius^2
end
local function vehicle(src, netId, radius)
  if type(netId) ~= 'number' or netId % 1 ~= 0 or netId <= 0 then return nil end
  local entity = NetworkGetEntityFromNetworkId(netId)
  if not entity or entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then
    notify(src, 'Veiculo indisponivel. Aproxime-se e solicite nova abordagem.')
    return nil
  end
  if not near(src, GetEntityCoords(entity), radius) then
    notify(src, 'Aproxime-se do veiculo para esta acao.')
    return nil
  end
  return entity
end
local function clearMission(src)
  local mission = missions[src]
  for _, id in ipairs(mission and mission.enemies or {}) do
    local enemy = NetworkGetEntityFromNetworkId(id)
    if enemy and enemy ~= 0 and DoesEntityExist(enemy)
      and mission.enemyEntities and mission.enemyEntities[id] == enemy then DeleteEntity(enemy) end
  end
  missions[src] = nil
  TriggerClientEvent('prfrp:ops:mission', src, false)
end

RegisterNetEvent('prfrp:ops:action', function(action, data)
  local src = source
  if not allowed(src) or type(action) ~= 'string' or #action > 24 then return end
  if action == 'backup' then
    if throttle(src, 'backup', 45) then notify(src, 'O apoio ainda esta em deslocamento ou reorganizacao.'); return end
    TriggerClientEvent('prfrp:ops:backup', src)
    return
  elseif action == 'mission' then
    if missions[src] then notify(src, 'Conclua a ronda atual ou use /prfcancelarronda.'); return end
    if throttle(src, 'mission', 5) then return end
    local list = Config.Operations.missions
    missionIndex[src] = (missionIndex[src] or 0) % #list + 1
    local definition = list[missionIndex[src]]
    if definition.resource and GetResourceState(definition.resource) ~= 'started' then
      notify(src, 'Inicie o mapa da favela antes desta ronda: '..definition.resource)
      return
    end
    local encounter = definition.encounter == true or math.random(100) <= Config.Operations.encounterChance
    missions[src] = { definition = definition, stage = 1,
      encounterStage = encounter and math.min(2, #definition.points) or false }
    TriggerClientEvent('prfrp:ops:mission', src, {
      name = definition.name, stage = 1, total = #definition.points, point = definition.points[1] })
    return
  elseif action == 'cancelMission' then
    clearMission(src)
    notify(src, 'Ronda cancelada.')
    return
  elseif action == 'release' then
    inspections[src] = nil
    TriggerClientEvent('prfrp:ops:release', src)
    return
  end
  if action ~= 'stop' and action ~= 'documents' and action ~= 'search' and action ~= 'tow' then return end
  if throttle(src, action, action == 'tow' and 30 or 1) then return end
  local current = inspections[src]
  if action ~= 'stop' and not current then
    notify(src, 'Selecione um veiculo com ABORDAR antes de fiscalizar ou chamar o guincho.')
    return
  end
  local id = action == 'stop' and data or current and current.netId
  local target = vehicle(src, id, action == 'stop' and 35 or 10)
  if not target then return end
  if action == 'stop' then
    inspections[src] = { netId = id, owner = owners[math.random(#owners)],
      regular = math.random(6) ~= 1, cargo = math.random(5) == 1 }
    TriggerClientEvent('prfrp:ops:stop', src, id)
    return
  end
  local ped = GetPlayerPed(src)
  if GetVehiclePedIsIn(ped, false) ~= 0 then notify(src, 'Desembarque para realizar a fiscalizacao.'); return end
  if GetEntitySpeed(target) > 1.0 then notify(src, 'Aguarde o veiculo parar.'); return end
  if action == 'documents' then
    current.documents = true
    TriggerClientEvent('prfrp:ops:inspectionAction', src, current.netId, action)
    notify(src, 'DOCUMENTOS SIMULADOS | Condutor: '..current.owner..' | Placa: '..
      tostring(GetVehicleNumberPlateText(target))..' | '..(current.regular and 'Licenciamento regular.' or 'Licenciamento vencido nesta simulacao.'))
  elseif action == 'search' then
    current.searched = true
    TriggerClientEvent('prfrp:ops:inspectionAction', src, current.netId, action)
    notify(src, 'REVISTA SIMULADA | '..(current.cargo and 'Mercadoria sem comprovante no porta-malas.' or 'Nenhuma irregularidade encontrada.'))
  elseif action == 'tow' then
    for _, other in ipairs(GetPlayers()) do
      if GetVehiclePedIsIn(GetPlayerPed(tonumber(other)), false) == target then
        notify(src, 'Guincho aguarda todos os jogadores desembarcarem.'); return
      end
    end
    TriggerClientEvent('prfrp:ops:tow', src, current.netId)
  end
end)

RegisterNetEvent('prfrp:ops:missionStep', function()
  local src = source
  if not allowed(src) or throttle(src, 'step', 2) then return end
  local mission = missions[src]
  if not mission then return end
  local point = mission.definition.points[mission.stage]
  if not near(src, point, 30) then return end
  if not mission.arrived then mission.arrived = os.time(); return end
  if os.time() - mission.arrived < 3 then return end
  if mission.encounterStage == mission.stage then
    if not mission.encounterRequested then
      mission.encounterRequested = true
      TriggerClientEvent('prfrp:ops:encounter', src, point, enemyModels)
      notify(src, 'COPOM: equipe sob ataque. Proteja-se e solicite reforco pelo F11.')
      return
    end
    if not mission.enemies then return end
    for _, id in ipairs(mission.enemies) do
      local enemy = NetworkGetEntityFromNetworkId(id)
      if enemy ~= 0 and DoesEntityExist(enemy) and mission.enemyEntities[id] == enemy
        and GetEntityHealth(enemy) > 0 then return end
    end
  end
  mission.stage = mission.stage + 1
  mission.arrived = nil
  if mission.stage > #mission.definition.points then
    clearMission(src)
    notify(src, 'Ronda concluida. Retorne a base ou solicite outra operacao no F11.')
  else
    TriggerClientEvent('prfrp:ops:mission', src, { name = mission.definition.name,
      stage = mission.stage, total = #mission.definition.points,
      point = mission.definition.points[mission.stage] })
  end
end)

RegisterNetEvent('prfrp:ops:registerEnemies', function(ids)
  local src = source
  if not allowed(src) then return end
  local mission = missions[src]
  if not mission or not mission.encounterRequested or mission.enemies
    or type(ids) ~= 'table' or #ids ~= 3 then return end
  local seen, registered = {}, {}
  for _, id in ipairs(ids) do
    if type(id) ~= 'number' or id % 1 ~= 0 or id <= 0 or seen[id] then return end
    seen[id] = true
    local entity = NetworkGetEntityFromNetworkId(id)
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 1
      or NetworkGetEntityOwner(entity) ~= src then return end
    local model = GetEntityModel(entity)
    if model ~= GetHashKey(enemyModels[1]) and model ~= GetHashKey(enemyModels[2]) then return end
    local p, target = GetEntityCoords(entity), mission.definition.points[mission.stage]
    if (p.x-target.x)^2+(p.y-target.y)^2+(p.z-target.z)^2 > 40^2 then return end
    registered[id] = entity
  end
  mission.enemies = ids
  mission.enemyEntities = registered
  TriggerClientEvent('prfrp:ops:enemiesRegistered', src)
end)

AddEventHandler('prfrp:ops:dutyEnded', function(src)
  inspections[src] = nil
  clearMission(src)
end)
AddEventHandler('playerDropped', function()
  local src = source
  clearMission(src)
  inspections[src], missions[src], cooldowns[src], missionIndex[src] = nil, nil, nil, nil
end)
