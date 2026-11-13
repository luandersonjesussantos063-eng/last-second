local duty, epoch, sequence = false, 0, 0
local queue, units, byNetId = {}, {}, {}
local working = false
local function notice(text) TriggerEvent('prfrp:chatNotice',text) end
local function valid(token) return duty and epoch==token end
local function remove(entity)
  if entity and entity~=0 and DoesEntityExist(entity) then
    SetEntityAsMissionEntity(entity,true,true); DeleteEntity(entity)
  end
end
local function removeUnit(unit)
  units[unit.number]=nil
  if unit.netId then byNetId[unit.netId]=nil end
  for _,ped in ipairs(unit.officers) do remove(ped) end
  remove(unit.car)
end
local function clear()
  epoch=epoch+1; queue={}; working=false
  for _,unit in pairs(units) do removeUnit(unit) end
  units,byNetId={},{}
end
local function load(name,token)
  local hash=GetHashKey(name)
  if not IsModelInCdimage(hash) then return end
  RequestModel(hash)
  local started=GetGameTimer()
  while valid(token) and not HasModelLoaded(hash) and GetGameTimer()-started<6000 do Wait(0) end
  if valid(token) and HasModelLoaded(hash) then return hash end
  SetModelAsNoLongerNeeded(hash)
end
local function snapshot(car)
  if car==0 or not DoesEntityExist(car) then return end
  local look={colours={GetVehicleColours(car)},extraColours={GetVehicleExtraColours(car)},
    livery=GetVehicleLivery(car),liveryMod=GetVehicleMod(car,48),tint=GetVehicleWindowTint(car),extras={}}
  if GetIsVehiclePrimaryColourCustom(car) then look.primary={GetVehicleCustomPrimaryColour(car)} end
  if GetIsVehicleSecondaryColourCustom(car) then look.secondary={GetVehicleCustomSecondaryColour(car)} end
  for i=0,20 do if DoesExtraExist(car,i) then look.extras[i]=IsVehicleExtraTurnedOn(car,i) end end
  return look
end
local function applyLook(car,look)
  if not look then return end
  SetVehicleModKit(car,0)
  SetVehicleColours(car,look.colours[1],look.colours[2])
  SetVehicleExtraColours(car,look.extraColours[1],look.extraColours[2])
  if look.primary then SetVehicleCustomPrimaryColour(car,table.unpack(look.primary)) end
  if look.secondary then SetVehicleCustomSecondaryColour(car,table.unpack(look.secondary)) end
  if look.livery>=0 then SetVehicleLivery(car,look.livery) end
  if look.liveryMod>=0 then SetVehicleMod(car,48,look.liveryMod,false) end
  SetVehicleWindowTint(car,look.tint)
  for i,on in pairs(look.extras) do if DoesExtraExist(car,i) then SetVehicleExtra(car,i,not on) end end
end
PrfIsBackup = function(ped)
  for _,unit in pairs(units) do for _,officer in ipairs(unit.officers) do if officer==ped then return true end end end
  return false
end
AddEventHandler('prfrp:backup:request',function(count)
  if not duty then notice('Digite servico no T primeiro.'); return end
  local car=GetVehiclePedIsIn(PlayerPedId(),false)
  if car==0 and PrfGetPatrolVehicle then car=PrfGetPatrolVehicle() end
  local id=car~=0 and DoesEntityExist(car) and NetworkGetNetworkIdFromEntity(car) or 0
  TriggerServerEvent('prfrp:ops:action','backup',{count=count or 1,template=id})
end)
RegisterNetEvent('prfrp:ops:backupRegistered',function(id)
  if byNetId[id] then byNetId[id].registered=true end
end)
local function active(unit,token) return valid(token) and units[unit.number]==unit end
local function monitor(unit,token,request)
  CreateThread(function()
    for attempt=1,12 do
      if not active(unit,token) then return end
      local ids={}
      for _,ped in ipairs(unit.officers) do ids[#ids+1]=NetworkGetNetworkIdFromEntity(ped) end
      unit.netId=NetworkGetNetworkIdFromEntity(unit.car)
      if unit.netId~=0 then
        byNetId[unit.netId]=unit
        TriggerServerEvent('prfrp:ops:registerBackup',request,unit.netId,ids)
      end
      Wait(300)
      if unit.registered then break end
    end
    if not active(unit,token) then return end
    if not unit.registered then removeUnit(unit);notice('Uma unidade nao sincronizou. Solicite novo reforco.');return end
    local started=GetGameTimer()
    local chasing=false
    while active(unit,token) and DoesEntityExist(unit.car) do
      local p,q=GetEntityCoords(unit.car),GetEntityCoords(PlayerPedId())
      local target=PrfGetPursuitVehicle and PrfGetPursuitVehicle() or 0
      if target~=0 and DoesEntityExist(target) then
        local at=GetEntityCoords(target)
        SetVehicleSiren(unit.car,true)
        TaskVehicleDriveToCoordLongrange(unit.officers[1],unit.car,at.x,at.y,at.z,25.0,786468,10.0)
        chasing=true
      elseif chasing then
        TaskVehicleDriveToCoordLongrange(unit.officers[1],unit.car,q.x,q.y,q.z,15.0,786603,10.0)
        chasing=false;started=GetGameTimer()
      elseif (p.x-q.x)^2+(p.y-q.y)^2<20^2 or GetGameTimer()-started>=45000 then break end
      Wait(1000)
    end
    if not active(unit,token) or not DoesEntityExist(unit.car) then return end
    SetVehicleSiren(unit.car,false)
    TaskVehicleTempAction(unit.officers[1],unit.car,27,1500)
    for _,ped in ipairs(unit.officers) do if DoesEntityExist(ped) then TaskLeaveVehicle(ped,unit.car,0) end end
    Wait(2000)
    if not active(unit,token) then return end
    notice('Unidade PRF '..unit.number..' no local.')
    while active(unit,token) do
      for i,ped in ipairs(unit.officers) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) then
          local rank=(unit.number-1)*2+i
          local angle,radius=rank*2.399963,4.0+math.sqrt(rank)*1.6
          SetCurrentPedWeapon(ped,GetHashKey(Config.DutyWeapon),true)
          -- Seguem individualmente: nao dependem do limite do grupo do GTA.
          TaskFollowToOffsetOfEntity(ped,PlayerPedId(),math.cos(angle)*radius,math.sin(angle)*radius,0.0,2.2,-1,3.0,true)
          SetPedKeepTask(ped,true)
        end
      end
      Wait(4000)
    end
  end)
end
local function spawnUnit(job,token)
  local carHash=load(job.model,token)
  if not carHash then return nil,'model' end
  local p=GetEntityCoords(PlayerPedId())
  local road,heading
  for i=1,16 do
    local angle=(sequence+i)*2.399963
    local radius=45.0+(i%4)*12
    local x,y=p.x+math.cos(angle)*radius,p.y+math.sin(angle)*radius
    local found,node,direction=GetClosestVehicleNodeWithHeading(x,y,p.z,1,3.0,0)
    if found and node and math.abs(node.z-p.z)<8 and (node.x-p.x)^2+(node.y-p.y)^2<120^2
      and not IsAnyVehicleNearPoint(node.x,node.y,node.z,5.0) then road,heading=node,direction;break end
  end
  if not road then SetModelAsNoLongerNeeded(carHash);return nil,'road' end
  RequestCollisionAtCoord(road.x,road.y,road.z)
  local car=CreateVehicle(carHash,road.x,road.y,road.z+0.5,heading,true,false)
  SetModelAsNoLongerNeeded(carHash)
  if car==0 then return nil,'road' end
  sequence=sequence+1
  local unit={car=car,officers={},number=sequence}
  units[unit.number]=unit
  SetEntityAsMissionEntity(car,true,true)
  FreezeEntityPosition(car,true)
  for i=1,10 do
    if not active(unit,token) then return nil,'cancelled' end
    RequestCollisionAtCoord(road.x,road.y,road.z)
    if HasCollisionLoadedAroundEntity(car) then break end
    Wait(100)
  end
  if not active(unit,token) then return nil,'cancelled' end
  if not HasCollisionLoadedAroundEntity(car) then removeUnit(unit);return nil,'road' end
  SetVehicleOnGroundProperly(car);FreezeEntityPosition(car,false)
  applyLook(car,job.look)
  SetVehicleNumberPlateText(car,('PRF%05d'):format(sequence%100000))
  SetVehicleDirtLevel(car,0.0);SetVehicleEngineOn(car,true,true,false)
  local name=GetResourceState(Config.PRFSkinResource)=='started' and Config.PRFSkinModel or 's_m_y_hwaycop_01'
  local hash=load(name,token) or load('s_m_y_hwaycop_01',token)
  if not active(unit,token) then if hash then SetModelAsNoLongerNeeded(hash) end;return nil,'cancelled' end
  if not hash then removeUnit(unit);return nil,'model' end
  for seat=-1,0 do
    local officer=CreatePed(4,hash,road.x,road.y,road.z,heading,true,true)
    if officer~=0 then
      unit.officers[#unit.officers+1]=officer
      SetEntityAsMissionEntity(officer,true,true)
      SetPedRelationshipGroupHash(officer,GetPedRelationshipGroupHash(PlayerPedId()))
      SetCanAttackFriendly(officer,false,false);SetBlockingOfNonTemporaryEvents(officer,true)
      SetPedFleeAttributes(officer,0,false);SetPedDropsWeaponsWhenDead(officer,false)
      GiveWeaponToPed(officer,GetHashKey(Config.DutyWeapon),180,false,true)
      SetPedIntoVehicle(officer,car,seat)
    end
  end
  SetModelAsNoLongerNeeded(hash)
  if #unit.officers~=2 then removeUnit(unit);return nil,'road' end
  SetVehicleHasMutedSirens(car,false);SetVehicleSiren(car,true)
  local destination=GetEntityCoords(PlayerPedId())
  TaskVehicleDriveToCoordLongrange(unit.officers[1],car,destination.x,destination.y,destination.z,15.0,786603,10.0)
  monitor(unit,token,job.request)
  return unit
end
local function startWorker()
  if working then return end
  working=true
  local token=epoch
  CreateThread(function()
    while valid(token) and #queue>0 do
      local job=queue[1]
      local unit,reason=spawnUnit(job,token)
      if not valid(token) then return end
      if unit then
        job.remaining=job.remaining-1
        if job.remaining==0 then table.remove(queue,1) end
        Wait(1200)
      elseif reason=='road' then
        if not job.waiting then notice('Reforco na fila: aguardando uma via livre.');job.waiting=true end
        Wait(2000)
      else table.remove(queue,1);notice('Modelo do reforco indisponivel. Confira os recursos da viatura.') end
    end
    if epoch==token then working=false end
  end)
end
RegisterNetEvent('prfrp:ops:backup',function(data)
  if not duty or type(data)~='table' then return end
  local car=data.template~=0 and NetworkGetEntityFromNetworkId(data.template) or 0
  if car~=0 and (not DoesEntityExist(car) or GetEntityModel(car)~=GetHashKey(data.model)) then car=0 end
  queue[#queue+1]={request=data.request,remaining=data.count,model=data.model,look=snapshot(car)}
  notice(('COPOM: %d viatura(s) adicionada(s) ao reforco.'):format(data.count))
  startWorker()
end)
RegisterNetEvent('prfrp:ops:clearBackup',clear)
RegisterNetEvent('prfrp:setDuty',function(value) duty=value==true;if not duty then clear() end end)
AddEventHandler('prfrp:baseArrival',function()
  if not duty then return end
  clear();TriggerServerEvent('prfrp:ops:action','dismissBackup')
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then duty=false;clear() end end)
