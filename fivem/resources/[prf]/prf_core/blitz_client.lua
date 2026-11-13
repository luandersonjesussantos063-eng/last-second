-- Uma mira, um clique, um cone. A posicao vem do solo atingido pela camera.
local duty,placing,epoch=false,false,0
local held,preview,oldWeapon=0,0,nil
local cones,registered,roles={}, {}, {}
local hash=GetHashKey('prop_roadcone02a')
local function remove(entity) if entity~=0 and DoesEntityExist(entity) then DeleteObject(entity) end end
local function cancel()
  placing=false;epoch=epoch+1
  remove(held);remove(preview);held,preview=0,0
  if oldWeapon and HasPedGotWeapon(PlayerPedId(),oldWeapon,false) then SetCurrentPedWeapon(PlayerPedId(),oldWeapon,true) end
  oldWeapon=nil
end
local function clear()
  cancel()
  for _,entity in ipairs(cones) do remove(entity) end
  cones,registered,roles={}, {}, {}
end
local function load(token)
  RequestModel(hash);local started=GetGameTimer()
  while duty and token==epoch and not HasModelLoaded(hash) and GetGameTimer()-started<4000 do Wait(0) end
  return duty and token==epoch and HasModelLoaded(hash)
end
local function ground()
  local p,r=GetGameplayCamCoord(),GetGameplayCamRot(2)
  local pitch,yaw=math.rad(r.x),math.rad(r.z)
  local dx,dy,dz=-math.sin(yaw)*math.cos(pitch),math.cos(yaw)*math.cos(pitch),math.sin(pitch)
  local ray=StartShapeTestRay(p.x,p.y,p.z,p.x+dx*10,p.y+dy*10,p.z+dz*10,17,PlayerPedId(),7)
  local status,hit,at,normal=GetShapeTestResult(ray)
  local start=GetGameTimer()
  while status==1 and GetGameTimer()-start<100 do Wait(0);status,hit,at,normal=GetShapeTestResult(ray) end
  if status==2 and hit and at and normal and normal.z>0.7 and #(at-GetEntityCoords(PlayerPedId()))<8 then return at end
end
AddEventHandler('prfrp:blitz:toggle',function()
  if placing then cancel();return end
  if not duty or IsPedInAnyVehicle(PlayerPedId(),false) then TriggerEvent('prfrp:chatNotice','Entre em servico e desembarque para colocar cones.');return end
  placing=true;epoch=epoch+1;local token=epoch
  oldWeapon=GetSelectedPedWeapon(PlayerPedId());SetCurrentPedWeapon(PlayerPedId(),GetHashKey('WEAPON_UNARMED'),true)
  TriggerEvent('prfrp:chatNotice','Cones: mire no chao com Z ou botao direito e clique para colocar. T > guardarcone | recolhercones.')
  CreateThread(function()
    if not load(token) then if token==epoch then cancel() end;SetModelAsNoLongerNeeded(hash);return end
    local p=GetEntityCoords(PlayerPedId())
    held=CreateObject(hash,p.x,p.y,p.z,false,false,false)
    AttachEntityToEntity(held,PlayerPedId(),GetPedBoneIndex(PlayerPedId(),57005),0.12,0.02,-0.08,0.0,90.0,0.0,true,true,false,true,1,true)
    SetEntityCollision(held,false,false)
    preview=CreateObject(hash,p.x,p.y,p.z,false,false,false)
    SetEntityAlpha(preview,120,false);SetEntityCollision(preview,false,false);FreezeEntityPosition(preview,true)
    SetModelAsNoLongerNeeded(hash)
    while placing and duty and token==epoch do
      if IsEntityDead(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(),false) then cancel();break end
      DisablePlayerFiring(PlayerId(),true);DisableControlAction(0,24,true);DisableControlAction(0,25,true)
      local aiming=(PrfIsAimHeld and PrfIsAimHeld()) or IsDisabledControlPressed(0,25)
      local point=aiming and not IsNuiFocused() and ground() or nil
      SetEntityVisible(preview,point~=nil,false)
      if point then
        SetEntityCoordsNoOffset(preview,point.x,point.y,point.z,false,false,false)
        DrawMarker(28,point.x,point.y,point.z+0.03,0,0,0,0,0,0,0.12,0.12,0.12,250,210,60,180,false,false,2,false,nil,nil,false)
        if IsDisabledControlJustPressed(0,24) then TriggerServerEvent('prfrp:blitz:place',{x=point.x,y=point.y,z=point.z}) end
      end
      Wait(0)
    end
  end)
end)
AddEventHandler('prfrp:blitz:cancel',cancel)
AddEventHandler('prfrp:blitz:recollect',function() TriggerServerEvent('prfrp:blitz:clear') end)
RegisterNetEvent('prfrp:blitz:clear',clear)
RegisterNetEvent('prfrp:blitz:registered',function(token) registered[token]=true end)
RegisterNetEvent('prfrp:blitz:authorized',function(token,p)
  local generation=epoch
  if not duty or not placing then return end
  CreateThread(function()
    if not load(generation) then SetModelAsNoLongerNeeded(hash);return end
    local object=CreateObjectNoOffset(hash,p.x,p.y,p.z,true,true,false)
    SetModelAsNoLongerNeeded(hash)
    if object==0 then return end
    SetEntityAsMissionEntity(object,true,true);PlaceObjectOnGroundProperly(object);FreezeEntityPosition(object,true)
    cones[#cones+1]=object
    for attempt=1,12 do
      if not duty or generation~=epoch or not DoesEntityExist(object) then remove(object);return end
      TriggerServerEvent('prfrp:blitz:spawned',token,NetworkGetNetworkIdFromEntity(object))
      Wait(250)
      if registered[token] then TriggerEvent('prfrp:chatNotice','Cone colocado. Equipe posicionada na blitz.');return end
    end
    remove(object)
  end)
end)
PrfGetBlitzAnchor=function()
  for _,entity in ipairs(cones) do if DoesEntityExist(entity) then return GetEntityCoords(entity) end end
end
PrfAssignBlitzRole=function(officer,index,player)
  local anchor=PrfGetBlitzAnchor()
  if not anchor or #(GetEntityCoords(player)-anchor)>65 then roles[officer]=nil;return false end
  local now=GetGameTimer();local role=roles[officer]
  if role and now<role.untilAt then return true end
  local car=PrfGetInspectedVehicle and PrfGetInspectedVehicle() or 0
  if index==3 and car~=0 and DoesEntityExist(car) and #(GetEntityCoords(car)-anchor)<40 then
    if #(GetEntityCoords(officer)-GetEntityCoords(car))>3 then TaskGoToEntity(officer,car,-1,2.0,1.6,0,0)
    else TaskTurnPedToFaceEntity(officer,car,5000) end
  elseif index==1 then
    local p=GetEntityCoords(officer)
    if #(p-anchor)>5 then TaskGoStraightToCoord(officer,anchor.x-2,anchor.y,anchor.z,1.5,6000,GetEntityHeading(player),0.5)
    else SetCurrentPedWeapon(officer,GetHashKey('WEAPON_UNARMED'),true);TaskStartScenarioInPlace(officer,'WORLD_HUMAN_CAR_PARK_ATTENDANT',0,true) end
  else
    if #(GetEntityCoords(officer)-anchor)>6 then TaskGoStraightToCoord(officer,anchor.x+index,anchor.y+2,anchor.z,1.5,6000,GetEntityHeading(player),0.5)
    else TaskGuardCurrentPosition(officer,6.0,6.0,true) end
  end
  roles[officer]={untilAt=now+6500};return true
end
RegisterNetEvent('prfrp:setDuty',function(value) duty=value==true;if not duty then clear() end end)
AddEventHandler('prfrp:baseArrival',function() clear();TriggerServerEvent('prfrp:blitz:clear') end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then duty=false;clear() end end)
-- O sinalizador seleciona um motorista por vez; o carro continua retido ate liberar.
CreateThread(function()
  local nextStop,seen=0,{}
  while true do
    local anchor=duty and PrfGetBlitzAnchor()
    local now=GetGameTimer()
    local current=PrfGetInspectedVehicle and PrfGetInspectedVehicle() or 0
    if not (PrfHasCopom and PrfHasCopom()) and anchor and #cones>=2 and now>nextStop and current==0 and not (PrfHasPersonStop and PrfHasPersonStop()) and not IsPedInAnyVehicle(PlayerPedId(),false)
      and #(GetEntityCoords(PlayerPedId())-anchor)<35 and not IsNuiFocused() then
      local own=PrfGetPatrolVehicle and PrfGetPatrolVehicle() or 0
      for _,car in ipairs(GetGamePool('CVehicle')) do
        local driver=GetPedInVehicleSeat(car,-1)
        if car~=own and driver~=0 and not IsPedAPlayer(driver) and not IsEntityDead(driver)
          and GetVehicleClass(car)~=18 and not IsEntityAttached(car) and GetEntitySpeed(car)>1
          and not (PrfIsBackup and PrfIsBackup(driver)) and not (PrfIsServiceStaff and PrfIsServiceStaff(driver))
          and not (seen[car] and now<seen[car]) and #(GetEntityCoords(car)-anchor)<22 then
          if not NetworkGetEntityIsNetworked(car) then NetworkRegisterEntityAsNetworked(car) end
          local id=NetworkGetNetworkIdFromEntity(car)
          if id~=0 then TriggerServerEvent('prfrp:ops:action','stop',id);seen[car]=now+120000;nextStop=now+25000;break end
        end
      end
    end
    for car,untilAt in pairs(seen) do if now>untilAt then seen[car]=nil end end
    Wait(2000)
  end
end)
