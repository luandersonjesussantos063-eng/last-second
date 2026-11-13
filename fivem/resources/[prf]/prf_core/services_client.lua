local duty,epoch=false,0
local jobs={}
local function alive(job,token) return duty and epoch==token and jobs[job.kind]==job end
local function remove(entity) if entity and entity~=0 and DoesEntityExist(entity) then SetEntityAsMissionEntity(entity,true,true);DeleteEntity(entity) end end
local function clear(kind)
  local job=jobs[kind]
  if job then
    jobs[kind]=nil
    local target=job.target and NetworkGetEntityFromNetworkId(job.target) or 0
    if kind=='tow' and target~=0 and DoesEntityExist(target) and job.car and IsEntityAttachedToEntity(target,job.car) then
      DetachEntity(target,true,true);SetVehicleOnGroundProperly(target)
    end
    remove(job.worker);remove(job.car)
  end
end
local function model(name,token)
  local hash=GetHashKey(name);RequestModel(hash)
  local started=GetGameTimer()
  while duty and epoch==token and not HasModelLoaded(hash) and GetGameTimer()-started<6000 do Wait(0) end
  if duty and epoch==token and HasModelLoaded(hash) then return hash end
  SetModelAsNoLongerNeeded(hash)
end
PrfIsServiceStaff=function(ped) for _,job in pairs(jobs) do if job.worker==ped then return true end end;return false end
AddEventHandler('prfrp:services:request',function(kind)
  if not duty then TriggerEvent('prfrp:chatNotice','Digite servico no T primeiro.');return end
  local missionTarget=PrfGetCopomServiceTarget and PrfGetCopomServiceTarget(kind) or 0
  if missionTarget~=0 then
    TriggerServerEvent('prfrp:services:request',kind,{vehicle=NetworkGetNetworkIdFromEntity(missionTarget),person=NetworkGetNetworkIdFromEntity(missionTarget)})
    return
  end
  local car=GetVehiclePedIsIn(PlayerPedId(),false)
  if car==0 and PrfGetInspectedVehicle then car=PrfGetInspectedVehicle() end
  if car==0 and PrfGetPatrolVehicle then car=PrfGetPatrolVehicle() end
  TriggerServerEvent('prfrp:services:request',kind,{vehicle=car~=0 and NetworkGetNetworkIdFromEntity(car) or 0})
end)
RegisterNetEvent('prfrp:services:registered',function(kind,id) if jobs[kind] and jobs[kind].id==id then jobs[kind].registered=true end end)
RegisterNetEvent('prfrp:services:dispatch',function(kind,id,targetId)
  if not duty or not Config.Services[kind] then return end
  local token=epoch
  local job={kind=kind,id=id,target=targetId};jobs[kind]=job
  CreateThread(function()
    local def=Config.Services[kind]
    local carHash,pedHash=model(def.vehicle,token),model(def.ped,token)
    if not alive(job,token) then if carHash then SetModelAsNoLongerNeeded(carHash) end;if pedHash then SetModelAsNoLongerNeeded(pedHash) end;return end
    if not carHash or not pedHash then TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    local p=GetEntityCoords(PlayerPedId())
    local road,heading
    for i=1,10 do
      local angle=i*2.399963
      local ok,node,h=GetClosestVehicleNodeWithHeading(p.x+math.cos(angle)*60,p.y+math.sin(angle)*60,p.z,1,3.0,0)
      if ok and math.abs(node.z-p.z)<8 and not IsAnyVehicleNearPoint(node.x,node.y,node.z,5) then road,heading=node,h;break end
    end
    if not road then SetModelAsNoLongerNeeded(carHash);SetModelAsNoLongerNeeded(pedHash);TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    RequestCollisionAtCoord(road.x,road.y,road.z)
    job.car=CreateVehicle(carHash,road.x,road.y,road.z+0.5,heading,true,false)
    SetModelAsNoLongerNeeded(carHash)
    if job.car==0 then SetModelAsNoLongerNeeded(pedHash);TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    SetEntityAsMissionEntity(job.car,true,true);SetVehicleOnGroundProperly(job.car)
    job.worker=CreatePed(4,pedHash,road.x,road.y,road.z,heading,true,true);SetModelAsNoLongerNeeded(pedHash)
    if job.worker==0 then TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    SetEntityAsMissionEntity(job.worker,true,true);SetPedIntoVehicle(job.worker,job.car,-1)
    SetBlockingOfNonTemporaryEvents(job.worker,true);SetPedRelationshipGroupHash(job.worker,GetPedRelationshipGroupHash(PlayerPedId()))
    for i=1,10 do
      if not alive(job,token) then return end
      TriggerServerEvent('prfrp:services:spawned',kind,id,NetworkGetNetworkIdFromEntity(job.car),NetworkGetNetworkIdFromEntity(job.worker))
      Wait(300);if job.registered then break end
    end
    if not alive(job,token) then return end
    if not job.registered then TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    local target=targetId==0 and PlayerPedId() or NetworkGetEntityFromNetworkId(targetId)
    local started=GetGameTimer()
    while alive(job,token) and DoesEntityExist(target) and GetGameTimer()-started<45000 do
      p=GetEntityCoords(target)
      TaskVehicleDriveToCoordLongrange(job.worker,job.car,p.x,p.y,p.z,15.0,786468,10.0)
      if #(GetEntityCoords(job.car)-p)<18 then break end
      Wait(1500)
    end
    if not alive(job,token) then return end
    if not DoesEntityExist(target) or #(GetEntityCoords(job.car)-GetEntityCoords(target))>25 then TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    TaskVehicleTempAction(job.worker,job.car,27,1500);TaskLeaveVehicle(job.worker,job.car,0);Wait(1800)
    if not alive(job,token) then return end
    TaskGoToEntity(job.worker,target,-1,2.0,1.5,0,0)
    started=GetGameTimer()
    while alive(job,token) and DoesEntityExist(target) and #(GetEntityCoords(job.worker)-GetEntityCoords(target))>4 and GetGameTimer()-started<15000 do Wait(300) end
    if not alive(job,token) then return end
    TriggerServerEvent('prfrp:services:arrived',kind,id)
  end)
end)
RegisterNetEvent('prfrp:services:perform',function(kind,id,targetId)
  local job=jobs[kind]
  if not job or job.id~=id then return end
  local token=epoch
  CreateThread(function()
    local target=targetId==0 and PlayerPedId() or NetworkGetEntityFromNetworkId(targetId)
    if not DoesEntityExist(target) then TriggerServerEvent('prfrp:services:finished',kind,id,false);return end
    TaskStartScenarioInPlace(job.worker,kind=='ambulance' and 'CODE_HUMAN_MEDIC_KNEEL' or 'WORLD_HUMAN_VEHICLE_MECHANIC',0,true)
    Wait(kind=='tow' and 5000 or 4000)
    if not alive(job,token) then return end
    local success=DoesEntityExist(target) and DoesEntityExist(job.worker) and not IsEntityDead(job.worker)
      and #(GetEntityCoords(job.worker)-GetEntityCoords(target))<5
    if success and not (kind=='ambulance' and targetId==0) then
      local started=GetGameTimer()
      while alive(job,token) and not NetworkHasControlOfEntity(target) and GetGameTimer()-started<2000 do NetworkRequestControlOfEntity(target);Wait(0) end
      success=alive(job,token) and NetworkHasControlOfEntity(target)
    end
    if success and kind=='ambulance' then
      if targetId==0 and IsEntityDead(target) then
        local p=GetEntityCoords(target)
        NetworkResurrectLocalPlayer(p.x,p.y,p.z,GetEntityHeading(target),true,false);target=PlayerPedId()
      end
      SetEntityHealth(target,GetEntityMaxHealth(target));ClearPedBloodDamage(target)
      if targetId~=0 then
        ClearPedTasks(target);SetPedCanRagdoll(target,true)
        if not (PrfIsPersonStopped and PrfIsPersonStopped(target)) then TaskStandStill(target,15000) end
      end
    elseif success and kind=='mechanic' then
      SetVehicleFixed(target);SetVehicleDeformationFixed(target);SetVehicleEngineHealth(target,1000.0);SetVehicleUndriveable(target,false)
    elseif success and kind=='fire' then StopEntityFire(target);SetVehicleEngineHealth(target,math.max(GetVehicleEngineHealth(target),500.0))
    elseif success and kind=='tow' then
      for seat=-1,GetVehicleMaxNumberOfPassengers(target)-1 do if GetPedInVehicleSeat(target,seat)~=0 then success=false end end
      if success then
        SetVehicleHandbrake(target,false);AttachEntityToEntity(target,job.car,0,0.0,-2.0,1.0,0,0,0,false,false,true,false,2,true)
        ClearPedTasks(job.worker);TaskEnterVehicle(job.worker,job.car,10000,-1,1.5,1,0)
        local start=GetGameTimer()
        while alive(job,token) and GetVehiclePedIsIn(job.worker,false)~=job.car and GetGameTimer()-start<10000 do Wait(250) end
        if not alive(job,token) then return end
        if GetVehiclePedIsIn(job.worker,false)~=job.car then success=false
        else
          local origin=GetEntityCoords(target)
          local out=GetOffsetFromEntityInWorldCoords(job.car,0.0,180.0,0.0)
          TaskVehicleDriveToCoordLongrange(job.worker,job.car,out.x,out.y,out.z,13.0,786603,8.0)
          start=GetGameTimer()
          while alive(job,token) and DoesEntityExist(target) and #(GetEntityCoords(target)-origin)<65 and GetGameTimer()-start<70000 do Wait(500) end
          if not alive(job,token) then return end
          success=DoesEntityExist(target) and #(GetEntityCoords(target)-origin)>=65
        end
      end
    end
    if alive(job,token) then TriggerServerEvent('prfrp:services:finished',kind,id,success) end
  end)
end)
RegisterNetEvent('prfrp:services:clear',clear)
RegisterNetEvent('prfrp:setDuty',function(value) duty=value==true;if not duty then epoch=epoch+1;for kind in pairs(jobs) do clear(kind) end end end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then epoch=epoch+1;duty=false;for kind in pairs(jobs) do clear(kind) end end end)
