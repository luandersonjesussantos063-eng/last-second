-- Operacoes ficticias. Nao consulta documentos reais, inventarios ou bancos externos.
local inspections, missions, cooldowns, missionIndex = {}, {}, {}, {}
local stoppedVehicles, vehicleLocks = {}, {}
local owners = { 'Carlos Pereira', 'Ana Souza', 'Joao Oliveira', 'Marcos Lima' }
local enemyModels = { 'g_m_y_ballaeast_01', 'g_m_y_mexgoon_02' }

local function notify(src, message)
  TriggerClientEvent('prfrp:operationsNotify', src, message)
end
local function allowed(src)
  if type(src) ~= 'number' or src <= 0 or not PrfHasDuty or not PrfHasDuty(src) then
    notify(src, 'Digite servico no T para usar as operacoes.')
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
local function releaseTraffic(src,id)
  local stopped=stoppedVehicles[src] or {}
  for netId,record in pairs(stopped) do
    if not id or id==netId then
      local car=NetworkGetEntityFromNetworkId(netId)
      if car~=0 and DoesEntityExist(car) and car==record.entity then
        local driverId=record.driverId
        if driverId and NetworkGetEntityFromNetworkId(driverId)~=record.driver then driverId=0 end
        TriggerClientEvent('prfrp:traffic:resume',-1,netId,driverId or 0)
      end
      stopped[netId],vehicleLocks[netId]=nil,nil
    end
  end
  if not id then stoppedVehicles[src]=nil end
  if not id or (inspections[src] and inspections[src].netId==id) then inspections[src]=nil end
  TriggerClientEvent('prfrp:ops:release',src,id or false)
end

RegisterNetEvent('prfrp:ops:action', function(action, data)
  local src = source
  if not allowed(src) or type(action) ~= 'string' or #action > 24 then return end
  if action=='release' then
    if PrfPersonAction then PrfPersonAction(src,action) end
    releaseTraffic(src)
    return
  elseif action=='releaseVehicle' then
    if inspections[src] then releaseTraffic(src,inspections[src].netId)
    else notify(src,'Aborde o carro que deseja liberar.');end
    return
  elseif action=='cancelPursuit' then
    if type(data)=='number' and stoppedVehicles[src] and stoppedVehicles[src][data] then
      releaseTraffic(src,data);notify(src,'Perseguicao cancelada.')
    end
    return
  end
  if PrfPersonAction and PrfPersonAction(src,action) then return end
  if action == 'backup' then
    PrfRequestBackup(src,data)
    return
  elseif action == 'dismissBackup' then
    PrfDismissBackup(src)
    notify(src,'Reforco dispensado e chamadas pendentes canceladas.')
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
  end
  if action ~= 'stop' and action ~= 'documents' and action ~= 'search' and action ~= 'tow'
    and action~='exit' and action~='breathalyzer' then return end
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
    local locked=vehicleLocks[id]
    if locked and locked~=src then
      local prior=stoppedVehicles[locked] and stoppedVehicles[locked][id]
      if prior and prior.entity==target then notify(src,'Esse veiculo ja esta em abordagem por outra equipe.');return end
      vehicleLocks[id]=nil
    end
    if PrfReleasePerson then PrfReleasePerson(src) end
    stoppedVehicles[src]=stoppedVehicles[src] or {}
    local record=stoppedVehicles[src][id]
    if not record or record.entity~=target then
      local driver=GetPedInVehicleSeat(target,-1)
      local human=false
      for _,player in ipairs(GetPlayers()) do if GetPlayerPed(tonumber(player))==driver then human=true;break end end
      record = { netId = id, entity=target,owner = owners[math.random(#owners)],
      driver=driver,driverId=driver~=0 and NetworkGetNetworkIdFromEntity(driver) or 0,
      regular = math.random(6) ~= 1, cargo = math.random(5) == 1,
      alcohol=math.random(8)==1 and '0.34 mg/L' or '0.00 mg/L',
      flee=driver~=0 and not human and math.random(100)<=(Config.Operations.nonComplianceChance or 15) }
      stoppedVehicles[src][id]=record
    end
    inspections[src],vehicleLocks[id]=record,src
    TriggerClientEvent('prfrp:ops:stop', src, id,{flee=record.flee})
    return
  end
  local ped = GetPlayerPed(src)
  if GetVehiclePedIsIn(ped, false) ~= 0 then notify(src, 'Desembarque para realizar a fiscalizacao.'); return end
  if GetEntitySpeed(target) > 1.0 then notify(src, 'Aguarde o veiculo parar.'); return end
  if action=='exit' then
    PrfOrderExitVehicle(src,target)
  elseif action=='breathalyzer' then
    notify(src,'BAFOMETRO SIMULADO | '..current.owner..' | '..current.alcohol..' (resultado ficticio).')
  elseif action == 'documents' then
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

RegisterNetEvent('prfrp:ops:pursuitEnded',function(id)
  local src=source
  if not allowed(src) then return end
  local record=stoppedVehicles[src] and stoppedVehicles[src][id]
  if not record then return end
  local car=vehicle(src,id,35)
  if not car or car~=record.entity or GetEntitySpeed(car)>1.0 then return end
  record.flee=false
  TriggerClientEvent('prfrp:traffic:resolved',src,id)
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
      notify(src, 'COPOM: equipe sob ataque. Proteja-se e digite reforco no T.')
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
    notify(src, 'Ronda concluida. Retorne a base ou digite ronda no T.')
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
  releaseTraffic(src)
  clearMission(src)
end)
AddEventHandler('playerDropped', function()
  local src = source
  releaseTraffic(src)
  clearMission(src)
  inspections[src], missions[src], cooldowns[src], missionIndex[src] = nil, nil, nil, nil
end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for src in pairs(stoppedVehicles) do releaseTraffic(src) end
end)
