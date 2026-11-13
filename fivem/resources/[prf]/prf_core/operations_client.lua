-- Blitz, fiscalizacao e rondas ficticias. Documentos/revista sao gerados no servidor.
local onDuty, menuOpen = false, false
local generation = 0
local selected, driver = 0, 0
local cones, support, enemies = {}, {}, {}
local towTruck, towDriver, towing = 0, 0, false
local mission, missionBlip = nil, nil
local requestingStep = 0
local encounterRegistered = false
local missionGeneration = 0

local function inform(message)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName('PRF RP: '..tostring(message))
  EndTextCommandThefeedPostTicker(false, false)
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
  if selected ~= 0 and DoesEntityExist(selected) then
    SetVehicleHandbrake(selected, false)
    if driver ~= 0 and DoesEntityExist(driver) and not IsPedAPlayer(driver) then
      if GetVehiclePedIsIn(driver, false) == selected then
        SetVehicleEngineOn(selected, true, true, false)
        TaskVehicleDriveWander(driver, selected, 15.0, 786603)
      else TaskWanderStandard(driver, 10.0, 10) end
    end
  end
  selected, driver = 0, 0
end
RegisterNetEvent('prfrp:ops:release', function()
  local hadVehicle=selected~=0
  release()
  if hadVehicle then inform('Veiculo liberado.') end
end)
local inspecting = false
RegisterNetEvent('prfrp:ops:inspectionAction', function(id, action)
  if not onDuty or inspecting or (action ~= 'documents' and action ~= 'search') then return end
  local target = NetworkGetEntityFromNetworkId(id)
  if target ~= selected or not DoesEntityExist(target) or IsPedInAnyVehicle(PlayerPedId(),false) then return end
  local ped, token = PlayerPedId(), generation
  local scenario = action == 'search' and 'PROP_HUMAN_BUM_BIN' or 'WORLD_HUMAN_CLIPBOARD'
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
  for _, ped in ipairs(enemies) do remove(ped) end
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
  for _, entity in ipairs(cones) do remove(entity) end
  for _, entity in ipairs(support) do remove(entity) end
  cones, support = {}, {}
  menuOpen = false
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
  local hadVehicle, hadMission = selected ~= 0, mission ~= nil
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

RegisterNetEvent('prfrp:ops:stop', function(id)
  if not onDuty then return end
  local vehicle = NetworkGetEntityFromNetworkId(id)
  if vehicle == 0 or not DoesEntityExist(vehicle) then return end
  release()
  selected, driver = vehicle, GetPedInVehicleSeat(vehicle, -1)
  local token = generation
  if driver ~= 0 and IsPedAPlayer(driver) then
    inform('Veiculo selecionado. Solicite a parada ao jogador; os documentos desta fiscalizacao sao simulados.')
    return
  end
  if driver == 0 then inform('Veiculo selecionado. F11: documentos, revista e guincho.'); return end
  CreateThread(function()
    if not control(vehicle, token) or not control(driver, token) then inform('Nao foi possivel assumir a parada desse veiculo.'); return end
    local shoulder = GetOffsetFromEntityInWorldCoords(vehicle, 4.0, 10.0, 0.0)
    TaskVehicleDriveToCoordLongrange(driver, vehicle, shoulder.x, shoulder.y, shoulder.z,
      5.0, 786603, 3.0)
    inform('Parada solicitada. Aguarde o condutor encostar e desembarque.')
    local start = GetGameTimer()
    while valid(token) and selected == vehicle and DoesEntityExist(vehicle)
      and GetGameTimer()-start < 12000 do
      if GetEntitySpeed(vehicle) < 0.8 then
        SetVehicleHandbrake(vehicle, true)
        inform('Veiculo parado. F11: pedir documentos ou revistar.')
        return
      end
      Wait(400)
    end
    if valid(token) and selected == vehicle then inform('Aguarde uma area livre e solicite a parada novamente.'); end
  end)
end)

local function toggleBlitz()
  if not onDuty then inform('Entre em servico com F5.'); return end
  if #cones > 0 then
    for _, object in ipairs(cones) do remove(object) end
    cones = {}; inform('Cones da blitz recolhidos.'); return
  end
  if IsPedInAnyVehicle(PlayerPedId(), false) then inform('Desembarque para montar a blitz.'); return end
  local token = generation
  CreateThread(function()
    local hash = model('prop_roadcone02a', token)
    if not hash then return end
    if #cones > 0 then SetModelAsNoLongerNeeded(hash); return end
    for i = 1, 4 do
      local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), -3.0+i*1.2, 4.0, 0.0)
      local object = CreateObject(hash, p.x, p.y, p.z, false, false, false)
      if object ~= 0 then PlaceObjectOnGroundProperly(object); FreezeEntityPosition(object, true); cones[#cones+1] = object end
    end
    SetModelAsNoLongerNeeded(hash)
    inform('Blitz montada. Olhe para um carro e escolha ABORDAR no F11.')
  end)
end

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

RegisterNetEvent('prfrp:ops:backup', function()
  if not onDuty then return end
  if #support > 0 then inform('Seu reforco ja esta ativo.'); return end
  local token = generation
  CreateThread(function()
    local name = GetResourceState(Config.PRFSkinResource) == 'started' and Config.PRFSkinModel or 's_m_y_hwaycop_01'
    local hash = model(name, token)
    if not hash then return end
    local car = spawnRoadVehicle('police3',45.0,token)
    if car == 0 or not valid(token) then SetModelAsNoLongerNeeded(hash); remove(car); return end
    support = {car}
    local officers = {}
    for seat = -1, 0 do
      local p = GetEntityCoords(car)
      local officer = CreatePed(4,hash,p.x,p.y,p.z,0.0,true,true)
      if officer ~= 0 then
        SetEntityAsMissionEntity(officer,true,true)
        SetPedRelationshipGroupHash(officer,GetPedRelationshipGroupHash(PlayerPedId()))
        SetCanAttackFriendly(officer,false,false)
        SetBlockingOfNonTemporaryEvents(officer,true)
        SetPedDropsWeaponsWhenDead(officer,false)
        GiveWeaponToPed(officer,GetHashKey(Config.DutyWeapon or 'WEAPON_CARBINERIFLE'),180,false,true)
        SetPedIntoVehicle(officer,car,seat)
        support[#support+1] = officer; officers[#officers+1] = officer
      end
    end
    SetModelAsNoLongerNeeded(hash)
    if #officers ~= 2 then for _,e in ipairs(support) do remove(e) end; support={}; return end
    local p = GetEntityCoords(PlayerPedId())
    SetVehicleHasMutedSirens(car,false); SetVehicleSiren(car,true)
    TaskVehicleDriveToCoordLongrange(officers[1],car,p.x,p.y,p.z,12.0,786603,9.0)
    inform('COPOM: reforco com dois policiais a caminho.')
    local start = GetGameTimer()
    while valid(token) and DoesEntityExist(car) and GetGameTimer()-start < 45000 do
      if #(GetEntityCoords(car)-GetEntityCoords(PlayerPedId())) < 18.0 then break end
      Wait(500)
    end
    if not valid(token) or not DoesEntityExist(car) then return end
    SetVehicleSiren(car,false)
    for _, officer in ipairs(officers) do TaskLeaveVehicle(officer,car,0) end
    Wait(1800)
    if not valid(token) then return end
    for i, officer in ipairs(officers) do
      if DoesEntityExist(officer) then
        SetPedAsGroupMember(officer,GetPedGroupIndex(PlayerPedId()))
        SetCurrentPedWeapon(officer,GetHashKey(Config.DutyWeapon or 'WEAPON_CARBINERIFLE'),true)
        TaskFollowToOffsetOfEntity(officer,PlayerPedId(),i*2.0,-4.0,0.0,2.2,-1,3.0,true)
      end
    end
    inform('Reforco no local.')
  end)
end)

RegisterNetEvent('prfrp:ops:tow', function(id)
  if not onDuty or towing then return end
  local target = NetworkGetEntityFromNetworkId(id)
  if target ~= selected or not DoesEntityExist(target) then return end
  towing = true
  local token = generation
  CreateThread(function()
    local hash = model('s_m_m_trucker_01', token)
    if not hash then if valid(token) then towing=false end; return end
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

RegisterNetEvent('prfrp:ops:encounter', function(point, models)
  if not onDuty or not mission or #enemies > 0 then return end
  local token = generation
  local encounterToken = missionGeneration
  CreateThread(function()
    local ids = {}
    local positions = {}
    if GetResourceState('prf_favela_realista') == 'started' then
      local ok, result = pcall(function() return exports.prf_favela_realista:GetEncounterPoints(point,3) end)
      if ok and type(result)=='table' then positions=result end
    end
    for i = 1, 3 do
      local hash = model(models[(i-1)%#models+1],token)
      if not valid(token) or encounterToken ~= missionGeneration or not mission then
        if hash then SetModelAsNoLongerNeeded(hash) end
        return
      end
      if not hash then clearEnemies(); request('cancelMission'); return end
      local at=positions[i] or {x=point.x+(i-2)*5,y=point.y+6,z=point.z}
      local ped = CreatePed(4,hash,at.x,at.y,at.z,0.0,true,true)
      SetModelAsNoLongerNeeded(hash)
      if ped == 0 then clearEnemies(); request('cancelMission'); return end
      enemies[#enemies+1] = ped
      SetEntityAsMissionEntity(ped,true,true)
      SetPedDropsWeaponsWhenDead(ped,false)
      SetPedRelationshipGroupHash(ped,GetHashKey('HATES_PLAYER'))
      SetPedCombatAbility(ped,1); SetPedAccuracy(ped,20)
      GiveWeaponToPed(ped,GetHashKey('WEAPON_PISTOL'),120,false,true)
      TaskCombatPed(ped,PlayerPedId(),0,16)
      ids[#ids+1] = NetworkGetNetworkIdFromEntity(ped)
    end
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

local options = { '1 Abordar carro a frente','2 Pedir documentos','3 Revistar veiculo',
  '4 Liberar veiculo','5 Solicitar guincho','6 Chamar reforco',
  '7 Montar / recolher blitz','8 Iniciar ronda','9 Fechar' }
local actions = { approach,function() request('documents') end,function() request('search') end,
  function() if towing then inform('Aguarde o guincho.'); else request('release') end end,
  function() request('tow') end,function() request('backup') end,toggleBlitz,
  function() request('mission') end,function() menuOpen=false end }
RegisterCommand('prfoperacoes',function()
  if not onDuty then inform('Entre em servico com F5.'); return end
  menuOpen=not menuOpen
  if menuOpen then TriggerEvent('prfrp:closeCoreMenu') end
end,false)
RegisterKeyMapping('prfoperacoes','PRF RP: blitz, guincho, reforco e rondas','keyboard','F11')
AddEventHandler('prfrp:closeOpsMenu',function() menuOpen=false end)
for i=1,9 do
  local index=i
  RegisterCommand('prfopsitem'..i,function()
    if not menuOpen then return end
    menuOpen=false; actions[index]()
  end,false)
  RegisterKeyMapping('prfopsitem'..i,'PRF RP: operacao '..i..' (menu F11)','keyboard',tostring(i))
end
RegisterCommand('prfabordar',approach,false)
RegisterCommand('prfblitz',toggleBlitz,false)
RegisterCommand('prfdocumentos',function() request('documents') end,false)
RegisterCommand('prfrevistar',function() request('search') end,false)
RegisterCommand('prfguincho',function() request('tow') end,false)
RegisterCommand('prfreforco',function() request('backup') end,false)
RegisterCommand('prfronda',function() request('mission') end,false)
RegisterCommand('prfcancelarronda',function() request('cancelMission') end,false)

local function text(x,y,value)
  SetTextFont(4); SetTextScale(0.32,0.32); SetTextColour(255,255,255,245)
  SetTextOutline(); SetTextEntry('STRING'); AddTextComponentString(value); DrawText(x,y)
end
CreateThread(function()
  while true do
    local wait=500
    if menuOpen then
      wait=0; DrawRect(0.20,0.34,0.36,0.53,8,28,48,220)
      text(0.03,0.10,'OPERACOES PRF | F11 fechar')
      for i,item in ipairs(options) do text(0.03,0.12+i*0.037,item) end
      text(0.03,0.53,'Cancelar ronda: /prfcancelarronda')
      for _,c in ipairs({157,158,160,164,165,159,161,162,163}) do DisableControlAction(0,c,true) end
    end
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
