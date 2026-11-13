-- Blitz, fiscalizacao e rondas ficticias. Documentos/revista sao gerados no servidor.
local onDuty = false
local generation = 0
local selected, driver = 0, 0
local enemies = {}
local towTruck, towDriver, towing = 0, 0, false
local mission, missionBlip = nil, nil
local requestingStep = 0
local encounterRegistered = false
local missionGeneration = 0

local function inform(message)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName('PRF RP: '..tostring(message))
  EndTextCommandThefeedPostTicker(false, false)
  TriggerEvent('prfrp:chatNotice',message)
end
RegisterNetEvent('prfrp:operationsNotify', inform)
local function valid(token) return onDuty and token == generation end
local function model(name, token)
  local hash = GetHashKey(name)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local start = GetGameTimer()
  while valid(token) and not HasModelLoaded(hash) and GetGameTimer()-start < 6000 do Wait(0) end
  if valid(token) and HasModelLoaded(hash) then return hash end
  SetModelAsNoLongerNeeded(hash)
end
local function control(entity, token)
  local start = GetGameTimer()
  while valid(token) and DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity)
    and GetGameTimer()-start < 1500 do
    NetworkRequestControlOfEntity(entity)
    Wait(0)
  end
  return valid(token) and DoesEntityExist(entity) and NetworkHasControlOfEntity(entity)
end
local function remove(entity)
  if entity ~= 0 and DoesEntityExist(entity) then
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
  end
end
local function release()
  TriggerEvent('prfrp:traffic:releaseLocal')
  selected, driver = 0, 0
end
AddEventHandler('prfrp:traffic:selected',function(car,ped) selected,driver=car,ped end)
local inspecting = false
RegisterNetEvent('prfrp:ops:inspectionAction', function(id, action)
  if not onDuty or inspecting or (action ~= 'documents' and action ~= 'search') then return end
  local target = NetworkGetEntityFromNetworkId(id)
  if target ~= selected or not DoesEntityExist(target) or IsPedInAnyVehicle(PlayerPedId(),false) then return end
  local ped, token = PlayerPedId(), generation
  if action=='documents' then return end
  local scenario = 'PROP_HUMAN_BUM_BIN'
  inspecting = true
  CreateThread(function()
    local opened = action == 'search' and control(target,token)
    if not valid(token) then inspecting=false; return end
    if opened then SetVehicleDoorOpen(target,5,false,false) end
    TaskStartScenarioInPlace(ped,scenario,0,true)
    Wait(2500)
    if DoesEntityExist(ped) and IsPedUsingScenario(ped,scenario) then ClearPedTasks(ped) end
    if opened and DoesEntityExist(target) and NetworkHasControlOfEntity(target) then SetVehicleDoorShut(target,5,false) end
    inspecting = false
  end)
end)
local function clearEnemies()
  for _, ped in ipairs(enemies) do if not (PrfIsPersonStopped and PrfIsPersonStopped(ped)) then remove(ped) end end
  enemies = {}
  encounterRegistered = false
end
local function clearMission()
  missionGeneration = missionGeneration + 1
  if missionBlip then RemoveBlip(missionBlip) end
  missionBlip, mission = nil, nil
  clearEnemies()
end
local function clearTow()
  if selected~=0 then TriggerEvent('prfrp:traffic:towing',selected,false) end
  if selected ~= 0 and DoesEntityExist(selected) and towTruck ~= 0
    and IsEntityAttachedToEntity(selected, towTruck) then
    DetachEntity(selected, true, true)
    SetVehicleOnGroundProperly(selected)
  end
  remove(towDriver); remove(towTruck)
  towDriver, towTruck, towing = 0, 0, false
end
local function cleanup()
  clearTow(); release(); clearMission()
end
RegisterNetEvent('prfrp:setDuty', function(enabled)
  onDuty = enabled == true
  if not onDuty then generation = generation + 1; cleanup() end
end)

local function request(action, data)
  if not onDuty then inform('Entre em servico com F5.'); return end
  TriggerServerEvent('prfrp:ops:action', action, data)
end
AddEventHandler('prfrp:baseArrival', function()
  if not onDuty then return end
  local hadVehicle, hadMission = selected ~= 0 or (PrfHasTrafficStops and PrfHasTrafficStops()), mission ~= nil
  generation = generation + 1
  cleanup()
  if hadVehicle then request('release') end
  if hadMission then request('cancelMission') end
end)
local function approach()
  if not onDuty then inform('Entre em servico com F5.'); return end
  if towing then inform('Aguarde o guincho concluir.'); return end
  local ped = PlayerPedId()
  local own = GetVehiclePedIsIn(ped, false)
  local origin = own ~= 0 and own or ped
  local pos, forward = GetEntityCoords(origin), GetEntityForwardVector(origin)
  local target, best = 0, 35.0^2
  for _, car in ipairs(GetGamePool('CVehicle')) do
    if car ~= own and DoesEntityExist(car) and not IsEntityAttached(car) then
      local p = GetEntityCoords(car)
      local dx, dy, dz = p.x-pos.x, p.y-pos.y, p.z-pos.z
      local distance = dx*dx+dy*dy+dz*dz
      if distance < best and dx*forward.x+dy*forward.y > 0 then target, best = car, distance end
    end
  end
  if target == 0 then inform('Aproxime-se e olhe para o carro que deseja abordar.'); return end
  if not NetworkGetEntityIsNetworked(target) then NetworkRegisterEntityAsNetworked(target) end
  local id = NetworkGetNetworkIdFromEntity(target)
  if id == 0 then inform('Esse veiculo ainda nao esta disponivel na rede. Aproxime-se.'); return end
  request('stop', id)
end


local function toggleBlitz() TriggerEvent('prfrp:blitz:toggle') end
PrfCanApproachPerson = function() return not towing end
AddEventHandler('prfrp:ops:command',function(action)
  if action=='stop' then approach()
  elseif action=='blitz' then toggleBlitz()
  elseif action=='release' or action=='releaseVehicle' then
    if towing then inform('Aguarde o guincho concluir a remocao.')
    else request(action) end
  elseif action=='exit' then
    if towing then inform('Aguarde o guincho concluir.')
    elseif selected==0 then inform('Olhe para um carro e digite abordar antes de mandar descer.')
    else request('exit') end
  end
end)

local function spawnRoadVehicle(name, distance, token)
  local hash = model(name, token)
  if not hash then return 0 end
  local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -distance, 0.0)
  RequestCollisionAtCoord(p.x, p.y, p.z)
  local found, road, heading = GetClosestVehicleNodeWithHeading(p.x,p.y,p.z,1,3.0,0)
  if not found or IsAnyVehicleNearPoint(road.x,road.y,road.z,4.0) then
    SetModelAsNoLongerNeeded(hash); inform('Sem rua livre para o veiculo de apoio.'); return 0
  end
  local car = CreateVehicle(hash,road.x,road.y,road.z+0.3,heading,true,false)
  SetModelAsNoLongerNeeded(hash)
  if car ~= 0 then SetEntityAsMissionEntity(car,true,true); SetVehicleOnGroundProperly(car) end
  return car
end


RegisterNetEvent('prfrp:ops:tow', function(id)
  if not onDuty or towing then return end
  local target = NetworkGetEntityFromNetworkId(id)
  if target ~= selected or not DoesEntityExist(target) then return end
  towing = true
  TriggerEvent('prfrp:traffic:towing',target,true)
  local token = generation
  CreateThread(function()
    local hash = model('s_m_m_trucker_01', token)
    if not hash then if valid(token) then clearTow() end; return end
    local truck = spawnRoadVehicle('flatbed',55.0,token)
    if not valid(token) then SetModelAsNoLongerNeeded(hash); remove(truck); return end
    towTruck = truck
    if towTruck == 0 then SetModelAsNoLongerNeeded(hash); clearTow(); return end
    local p = GetEntityCoords(towTruck)
    towDriver = CreatePed(4,hash,p.x,p.y,p.z,0.0,true,true)
    SetModelAsNoLongerNeeded(hash)
    if towDriver == 0 then clearTow(); return end
    SetPedIntoVehicle(towDriver,towTruck,-1)
    SetBlockingOfNonTemporaryEvents(towDriver,true)
    p = GetEntityCoords(target)
    TaskVehicleDriveToCoordLongrange(towDriver,towTruck,p.x,p.y,p.z,10.0,786603,7.0)
    inform('Guincho acionado. Aguarde a chegada ao local.')
    local start = GetGameTimer()
    while valid(token) and DoesEntityExist(target) and DoesEntityExist(towTruck)
      and #(GetEntityCoords(towTruck)-GetEntityCoords(target)) > 12.0
      and GetGameTimer()-start < 45000 do Wait(500) end
    if not valid(token) then return end
    if not DoesEntityExist(target) or not DoesEntityExist(towTruck)
      or #(GetEntityCoords(towTruck)-GetEntityCoords(target)) > 12.0 then
      inform('O guincho nao conseguiu acessar o veiculo.'); clearTow(); return
    end
    if not control(target,token) then
      if valid(token) then inform('Sem controle do veiculo para embarcar no guincho.'); clearTow() end
      return
    end
    local occupants = {}
    for seat = -1, GetVehicleMaxNumberOfPassengers(target)-1 do
      local ped = GetPedInVehicleSeat(target,seat)
      if ped ~= 0 then
        if IsPedAPlayer(ped) then inform('Guincho aguarda os jogadores desembarcarem.'); clearTow(); return end
        occupants[#occupants+1] = ped
        TaskLeaveVehicle(ped,target,0)
      end
    end
    Wait(3000)
    if not valid(token) or not DoesEntityExist(target) then return end
    for seat = -1, GetVehicleMaxNumberOfPassengers(target)-1 do
      if not IsVehicleSeatFree(target,seat,true) then inform('O veiculo ainda esta ocupado.'); clearTow(); return end
    end
    SetVehicleHandbrake(target,false)
    AttachEntityToEntity(target,towTruck,0,0.0,-2.0,1.0,0.0,0.0,0.0,false,false,true,false,2,true)
    for _,ped in ipairs(occupants) do if DoesEntityExist(ped) then TaskWanderStandard(ped,10.0,10) end end
    p = GetOffsetFromEntityInWorldCoords(towTruck,0.0,180.0,0.0)
    TaskVehicleDriveToCoordLongrange(towDriver,towTruck,p.x,p.y,p.z,12.0,786603,8.0)
    inform('Veiculo embarcado no guincho.')
    start = GetGameTimer()
    while valid(token) and DoesEntityExist(towTruck)
      and #(GetEntityCoords(towTruck)-GetEntityCoords(PlayerPedId())) < 100.0
      and GetGameTimer()-start < 60000 do Wait(500) end
    if not valid(token) then return end
    if DoesEntityExist(towTruck) and #(GetEntityCoords(towTruck)-GetEntityCoords(PlayerPedId())) >= 100.0 then
      remove(target); selected,driver=0,0
      request('release')
      inform('Guincho concluiu a remocao simulada.')
    else inform('Guincho sem passagem. Veiculo desembarcado para nova tentativa.') end
    clearTow()
  end)
end)

RegisterNetEvent('prfrp:ops:mission', function(data)
  if missionBlip then RemoveBlip(missionBlip); missionBlip=nil end
  if type(data) ~= 'table' then clearMission(); return end
  if not onDuty then return end
  missionGeneration = missionGeneration + 1
  mission = data
  missionBlip = AddBlipForCoord(data.point.x,data.point.y,data.point.z)
  SetBlipSprite(missionBlip,1); SetBlipColour(missionBlip,5)
  SetBlipRoute(missionBlip,true)
  SetNewWaypoint(data.point.x,data.point.y)
  inform(data.name..' | Ponto '..data.stage..'/'..data.total..' marcado no GPS.')
end)

RegisterNetEvent('prfrp:ops:encounter', function(point, definitions)
  if not onDuty or not mission or #enemies > 0 then return end
  local token = generation
  local encounterToken = missionGeneration
  CreateThread(function()
    local ids = {}
    local positions = {}
    if GetResourceState('prf_favela_realista') == 'started' then
      local ok, result = pcall(function() return exports.prf_favela_realista:GetEncounterPoints(point,#definitions) end)
      if ok and type(result)=='table' then positions=result end
    end
    local groups={GetHashKey('PRF_ENCOUNTER_A'),GetHashKey('PRF_ENCOUNTER_B')}
    AddRelationshipGroup('PRF_ENCOUNTER_A');AddRelationshipGroup('PRF_ENCOUNTER_B')
    SetRelationshipBetweenGroups(5,groups[1],groups[2]);SetRelationshipBetweenGroups(5,groups[2],groups[1])
    for _,group in ipairs(groups) do SetRelationshipBetweenGroups(5,group,GetPedRelationshipGroupHash(PlayerPedId())) end
    for i,definition in ipairs(definitions) do
      local hash = model(definition.model,token)
      if not valid(token) or encounterToken ~= missionGeneration or not mission then
        if hash then SetModelAsNoLongerNeeded(hash) end
        return
      end
      if not hash then clearEnemies(); request('cancelMission'); return end
      local side=definition.side or 1
      local at=positions[i] or {x=point.x+(i%3-1)*5,y=point.y+(side==1 and 9 or -9),z=point.z}
      RequestCollisionAtCoord(at.x,at.y,at.z)
      local safe,ground=GetSafeCoordForPed(at.x,at.y,at.z,true,16)
      if safe and #(ground-vector3(at.x,at.y,at.z))<8 then at=ground end
      local ped = CreatePed(4,hash,at.x,at.y,at.z,0.0,true,true)
      SetModelAsNoLongerNeeded(hash)
      if ped == 0 then clearEnemies(); request('cancelMission'); return end
      enemies[#enemies+1] = ped
      SetEntityAsMissionEntity(ped,true,true)
      SetPedDropsWeaponsWhenDead(ped,false)
      SetPedRelationshipGroupHash(ped,groups[side])
      SetBlockingOfNonTemporaryEvents(ped,true)
      SetPedCombatAttributes(ped,46,true);SetPedCombatMovement(ped,2);SetPedCombatRange(ped,1)
      SetPedFleeAttributes(ped,0,false)
      SetPedCombatAbility(ped,1); SetPedAccuracy(ped,20)
      GiveWeaponToPed(ped,GetHashKey(definition.weapon),180,false,true)
      TaskCombatHatedTargetsAroundPed(ped,90.0,0)
      ids[#ids+1] = NetworkGetNetworkIdFromEntity(ped)
    end
    -- Aguarda as duas equipes existirem antes de escolher alvos.
    for _,ped in ipairs(enemies) do TaskCombatHatedTargetsAroundPed(ped,90.0,0) end
    for attempt = 1, 8 do
      if not valid(token) or encounterToken ~= missionGeneration or not mission or encounterRegistered then return end
      Wait(500)
      TriggerServerEvent('prfrp:ops:registerEnemies',ids)
    end
    if valid(token) and encounterToken == missionGeneration and not encounterRegistered then
      inform('Nao foi possivel sincronizar a ocorrencia. Solicite nova ronda.')
      request('cancelMission')
    end
  end)
end)
RegisterNetEvent('prfrp:ops:enemiesRegistered', function() encounterRegistered = true end)

RegisterCommand('prfoperacoes',function()
  TriggerEvent('prfrp:chatHelp')
end,false)
for i=1,9 do
  RegisterCommand('prfopsitem'..i,function() end,false)
end
RegisterCommand('prfabordar',function() TriggerEvent('prfrp:person:approachCommand') end,false)
RegisterCommand('prfblitz',toggleBlitz,false)
RegisterCommand('prfdocumentos',function() request('documents') end,false)
RegisterCommand('prfrevistar',function() request('search') end,false)
RegisterCommand('prfguincho',function() request('tow') end,false)
RegisterCommand('prfreforco',function(_,args)
  TriggerEvent('prfrp:backup:request',args and tonumber(args[1]) or 1)
end,false)
RegisterCommand('prfronda',function() request('mission') end,false)
RegisterCommand('prfcancelarronda',function() request('cancelMission') end,false)

CreateThread(function()
  while true do
    local wait=500
    if onDuty and mission then
      if IsEntityDead(PlayerPedId()) then request('cancelMission')
      else
        local point=mission.point
        local p=GetEntityCoords(PlayerPedId())
        local distance=(p.x-point.x)^2+(p.y-point.y)^2+(p.z-point.z)^2
        if distance<50^2 then
          wait=0
          DrawMarker(1,point.x,point.y,point.z-1,0.0,0.0,0.0,0.0,0.0,0.0,
            5.0,5.0,1.0,230,195,50,120,false,false,2,false,nil,nil,false)
        end
        if distance<25^2 and GetGameTimer()-requestingStep>2500 then
          requestingStep=GetGameTimer(); TriggerServerEvent('prfrp:ops:missionStep')
        end
      end
    end
    Wait(wait)
  end
end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  generation=generation+1; cleanup(); onDuty=false
end)
