local duty, epoch, sequence = false, 0, 0
local queue, units, byNetId = {}, {}, {}
local working = false
local convoyPaused,convoyEpoch=false,0
local threat,threatUntil=0,0
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
  epoch=epoch+1;convoyEpoch=convoyEpoch+1;convoyPaused=false;threat,threatUntil=0,0
  for _,job in ipairs(queue) do job.cancelled=true end
  queue={}; working=false
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
AddEventHandler('prfrp:backup:request',function(count,mode)
  if not duty then notice('Digite servico no T primeiro.'); return end
  local car=GetVehiclePedIsIn(PlayerPedId(),false)
  if car==0 and PrfGetPatrolVehicle then car=PrfGetPatrolVehicle() end
  local id=car~=0 and DoesEntityExist(car) and NetworkGetNetworkIdFromEntity(car) or 0
  TriggerServerEvent('prfrp:ops:action','backup',{count=count or (mode=='convoy' and Config.Backup.convoyDefault or 1),template=id,mode=mode or 'support'})
end)
RegisterNetEvent('prfrp:ops:backupRegistered',function(id)
  if byNetId[id] then byNetId[id].registered=true end
end)
local function active(unit,token) return valid(token) and units[unit.number]==unit end
local function alive(ped) return ped and ped~=0 and DoesEntityExist(ped) and not IsEntityDead(ped) end
local function distance(a,b)
  local p,q=GetEntityCoords(a),GetEntityCoords(b)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2
end
local function fleetCar(car)
  if car==0 or not DoesEntityExist(car) then return false end
  for _,entry in ipairs(Config.Fleet) do if GetEntityModel(car)==GetHashKey(entry.model) then return true end end
  return false
end
local function playerCar()
  local car=GetVehiclePedIsIn(PlayerPedId(),false)
  if car~=0 and PrfGetDriverVehicle and PrfGetDriverVehicle()==car and fleetCar(car) then return car end
  return fleetCar(car) and GetPedInVehicleSeat(car,-1)==PlayerPedId() and car or 0
end
local function threatTarget()
  if not alive(threat) or GetGameTimer()>threatUntil or distance(threat,PlayerPedId())>100^2
    or (PrfIsPersonStopped and PrfIsPersonStopped(threat)) then threat=0 end
  return threat
end
local function engage(candidate)
  if not duty or not candidate or candidate==0 or not DoesEntityExist(candidate) then return end
  if GetEntityType(candidate)==2 then candidate=GetPedInVehicleSeat(candidate,-1) end
  if not alive(candidate) or GetEntityType(candidate)~=1 or candidate==PlayerPedId()
    or PrfIsBackup(candidate) or (PrfIsCompanion and PrfIsCompanion(candidate))
    or (PrfIsServiceStaff and PrfIsServiceStaff(candidate)) or (PrfIsPersonStopped and PrfIsPersonStopped(candidate))
    or distance(candidate,PlayerPedId())>85^2 then return end
  threat,threatUntil=candidate,GetGameTimer()+20000
end
AddEventHandler('entityDamaged',function(victim,culprit)
  if victim==PlayerPedId() or PrfIsBackup(victim) then engage(culprit);return end
  for _,unit in pairs(units) do if victim==unit.car then engage(culprit);return end end
end)
AddEventHandler('prfrp:person:detained',function(ped)
  if threat==ped then threat=0 end
  for _,unit in pairs(units) do
    if unit.enemy==ped then
      unit.enemy=0;unit.footAt=0
      for _,officer in ipairs(unit.officers) do if alive(officer) then ClearPedTasks(officer) end end
    end
  end
end)
local function emergency(unit,on)
  if unit.emergency==on or not DoesEntityExist(unit.car) then return end
  unit.emergency=on;SetVehicleHasMutedSirens(unit.car,not on);SetVehicleSiren(unit.car,on)
end
local function stopCar(unit,state,now)
  if not DoesEntityExist(unit.car) then return end
  if unit.state~=state or (GetEntitySpeed(unit.car)>0.8 and now>=(unit.brakeAt or 0)) then
    if alive(unit.officers[1]) and GetVehiclePedIsIn(unit.officers[1],false)==unit.car then TaskVehicleTempAction(unit.officers[1],unit.car,27,1500) end
    unit.brakeAt=now+1600
  end
  SetVehicleHandbrake(unit.car,true);unit.state=state
end
local function board(unit,now)
  local ready=true
  for index,ped in ipairs(unit.officers) do
    if alive(ped) and (GetVehiclePedIsIn(ped,false)~=unit.car or GetPedInVehicleSeat(unit.car,index-2)~=ped) then
      ready=false
      if now>=(unit.boardAt[ped] or 0) then
        local other=GetVehiclePedIsIn(ped,false)
        ClearPedTasks(ped)
        if other~=0 then TaskLeaveVehicle(ped,other,0)
        else TaskEnterVehicle(ped,unit.car,10000,index-2,2.0,1,0) end
        unit.boardAt[ped]=now+10000
      end
    end
  end
  if not ready then stopCar(unit,'boarding',now) end
  return ready
end
local function convoyLeader(unit)
  local lead=playerCar()
  if lead==0 and unit.leader and DoesEntityExist(unit.leader) and fleetCar(unit.leader)
    and (GetPedInVehicleSeat(unit.leader,-1)==0 or (PrfGetDriverVehicle and PrfGetDriverVehicle()==unit.leader)) and distance(unit.leader,PlayerPedId())<60^2 then lead=unit.leader end
  if lead==0 then return 0 end
  unit.leader=lead
  local number=0
  for n,other in pairs(units) do
    if n<unit.number and n>number and other.mode=='convoy' and other.registered and DoesEntityExist(other.car)
      and not IsEntityDead(other.car) and alive(other.officers[1]) and GetVehiclePedIsIn(other.officers[1],false)==other.car
      and other.state=='escort' then lead,number=other.car,n end
  end
  return lead
end
local function foot(unit,enemy,now)
  local carExists=DoesEntityExist(unit.car)
  stopCar(unit,'foot',now);emergency(unit,false)
  if carExists and GetEntitySpeed(unit.car)>2 then return end
  for _,ped in ipairs(unit.officers) do
    if alive(ped) and GetVehiclePedIsIn(ped,false)~=0 and now>=(unit.exitAt[ped] or 0) then
      TaskLeaveVehicle(ped,GetVehiclePedIsIn(ped,false),0);unit.exitAt[ped]=now+5000
    end
  end
  if now<(unit.footAt or 0) and unit.enemy==enemy then return end
  local previous=unit.enemy or 0;unit.enemy=enemy;unit.footAt=now+3800
  for index,ped in ipairs(unit.officers) do
    if alive(ped) and GetVehiclePedIsIn(ped,false)==0 then
      if previous~=enemy then ClearPedTasks(ped) end
      SetCurrentPedWeapon(ped,GetHashKey(Config.DutyWeapon),true)
      if enemy~=0 then TaskCombatPed(ped,enemy,0,16)
      else
        local rank=(unit.number-1)*Config.Backup.crewSize+index
        local angle,radius=rank*2.399963,math.min(18.0,4.0+math.sqrt(rank)*1.3)
        TaskFollowToOffsetOfEntity(ped,PlayerPedId(),math.cos(angle)*radius,math.sin(angle)*radius,0.0,2.2,-1,3.0,true)
      end
      SetPedKeepTask(ped,true)
    end
  end
  unit.deployed=true
end
local function tick(unit,now)
  local carExists=DoesEntityExist(unit.car)
  local enemy=threatTarget()
  if enemy~=0 and carExists and distance(unit.car,enemy)>100^2 then enemy=0 end
  if not carExists or IsEntityDead(unit.car) or not alive(unit.officers[1]) then foot(unit,enemy,now);return end
  local target=PrfGetPursuitVehicle and PrfGetPursuitVehicle() or 0
  if target~=0 and (not DoesEntityExist(target) or IsEntityDead(target)) then target=0 end
  local own=playerCar()
  local paused=unit.mode=='convoy' and convoyPaused
  if enemy~=0 and (target==0 or GetEntitySpeed(target)<1.0) and (GetEntitySpeed(unit.car)<3 or distance(unit.car,PlayerPedId())<25^2) then
    foot(unit,enemy,now);return
  end
  if target~=0 and GetEntitySpeed(target)<1.0 then unit.stoppedAt=unit.stoppedAt or now else unit.stoppedAt=nil end
  if not paused and unit.stoppedAt and now-unit.stoppedAt>2500 and distance(unit.car,target)<24^2 then foot(unit,enemy,now);return end
  if not paused and target==0 and unit.mode=='support' and own==0
    and (unit.deployed or distance(unit.car,PlayerPedId())<22^2) then foot(unit,enemy,now);return end
  if not board(unit,now) then return end
  local state,leader='arrive',0
  if paused then state='hold'
  elseif target~=0 then state,leader='pursuit',target
  elseif unit.mode=='convoy' then leader=convoyLeader(unit);state=leader~=0 and 'escort' or 'hold'
  elseif own~=0 then state,leader='escort',own end
  if state=='hold' then emergency(unit,false);stopCar(unit,'hold',now);return end
  SetVehicleHandbrake(unit.car,false)
  local changed=unit.state~=state or unit.target~=leader
  if changed then unit.driveAt=0;unit.enemy=0 end
  local driver=unit.officers[1]
  emergency(unit,state=='pursuit' or state=='arrive')
  if now>=(unit.driveAt or 0) then
    if state=='pursuit' then
      TaskVehicleChase(driver,leader);SetDriveTaskDrivingStyle(driver,786468)
    elseif state=='escort' then
      -- Modo -1 = atras. Distancia zero para manter o pathfinding nas ruas.
      TaskVehicleEscort(driver,unit.car,leader,-1,Config.Backup.cruiseSpeed,786603,Config.Backup.convoyGap,0,0.0)
    else
      local p=GetEntityCoords(PlayerPedId())
      TaskVehicleDriveToCoordLongrange(driver,unit.car,p.x,p.y,p.z,18.0,786603,12.0)
    end
    unit.driveAt=now+(state=='arrive' and 3000 or 10000)
  end
  SetDriveTaskCruiseSpeed(driver,state=='pursuit' and math.min(60.0,math.max(Config.Backup.pursuitSpeed,GetEntitySpeed(leader)+6.0))
    or state=='escort' and math.min(45.0,math.max(Config.Backup.cruiseSpeed,GetEntitySpeed(leader)+4.0)) or 18.0)
  unit.state,unit.target=state,leader
end
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
    if not unit.registered then removeUnit(unit);notice('Uma unidade nao sincronizou. Solicite novo apoio.');return end
    notice(('Unidade PRF %d disponivel: quatro policiais.'):format(unit.number))
    while active(unit,token) do tick(unit,GetGameTimer());Wait(600) end
  end)
end
CreateThread(function()
  while true do
    if duty and next(units) and threatTarget()==0 then
      local scanned=0
      for _,ped in ipairs(GetGamePool('CPed')) do
        scanned=scanned+1;if scanned>100 then break end
        if alive(ped) and ped~=PlayerPedId() and not PrfIsBackup(ped) and distance(ped,PlayerPedId())<35^2
          and IsPedShooting(ped) and IsPedFacingPed(ped,PlayerPedId(),30.0) and HasEntityClearLosToEntity(ped,PlayerPedId(),17) then engage(ped);break end
      end
    end
    Wait(1000)
  end
end)
local function jobActive(job,token) return valid(token) and not job.cancelled and (job.mode~='convoy' or job.convoyEpoch==convoyEpoch) end
local function spawnUnit(job,token)
  local carHash=load(job.model,token)
  if not jobActive(job,token) then if carHash then SetModelAsNoLongerNeeded(carHash) end;return nil,'cancelled' end
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
  local unit={car=car,officers={},number=sequence,mode=job.mode,leader=job.leader,boardAt={},exitAt={}}
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
  if GetVehicleMaxNumberOfPassengers(car)<Config.Backup.crewSize-1 then removeUnit(unit);return nil,'seats' end
  applyLook(car,job.look)
  SetVehicleNumberPlateText(car,('PRF%05d'):format(sequence%100000))
  SetVehicleDirtLevel(car,0.0);SetVehicleEngineOn(car,true,true,false)
  local name=GetResourceState(Config.PRFSkinResource)=='started' and Config.PRFSkinModel or 's_m_y_hwaycop_01'
  local hash=load(name,token) or load('s_m_y_hwaycop_01',token)
  if not active(unit,token) then if hash then SetModelAsNoLongerNeeded(hash) end;return nil,'cancelled' end
  if not hash then removeUnit(unit);return nil,'model' end
  for seat=-1,Config.Backup.crewSize-2 do
    local officer=CreatePed(4,hash,road.x,road.y,road.z,heading,true,true)
    if officer~=0 then
      unit.officers[#unit.officers+1]=officer
      SetEntityAsMissionEntity(officer,true,true)
      SetPedRelationshipGroupHash(officer,GetPedRelationshipGroupHash(PlayerPedId()))
      SetCanAttackFriendly(officer,false,false);SetBlockingOfNonTemporaryEvents(officer,true)
      SetPedFleeAttributes(officer,0,false);SetPedDropsWeaponsWhenDead(officer,false)
      SetPedCombatAbility(officer,2);SetPedCombatMovement(officer,2);SetPedCombatRange(officer,1);SetPedAccuracy(officer,40);SetPedArmour(officer,75)
      SetDriverAbility(officer,1.0);SetDriverAggressiveness(officer,0.45)
      GiveWeaponToPed(officer,GetHashKey(Config.DutyWeapon),180,false,true)
      SetPedIntoVehicle(officer,car,seat)
      SetCurrentPedWeapon(officer,GetHashKey('WEAPON_UNARMED'),true)
    end
  end
  SetModelAsNoLongerNeeded(hash)
  if #unit.officers~=Config.Backup.crewSize then removeUnit(unit);return nil,'road' end
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
      if not jobActive(job,token) then
        if unit then removeUnit(unit) end
        if queue[1]==job then table.remove(queue,1) end
      elseif unit then
        job.remaining=job.remaining-1
        if job.remaining==0 then table.remove(queue,1) end
        Wait(1200)
      elseif reason=='road' then
        if not job.waiting then notice('Reforco na fila: aguardando uma via livre.');job.waiting=true end
        Wait(2000)
      else
        if queue[1]==job then table.remove(queue,1) end
        notice(reason=='seats' and 'Esta viatura nao tem quatro assentos. Use um SUV ou sedan da frota para chamar apoio.' or 'Modelo do apoio indisponivel. Confira os recursos da viatura.')
      end
    end
    if epoch==token then working=false end
  end)
end
RegisterNetEvent('prfrp:ops:backup',function(data)
  if not duty or type(data)~='table' then return end
  local car=data.template~=0 and NetworkGetEntityFromNetworkId(data.template) or 0
  if car~=0 and (not DoesEntityExist(car) or GetEntityModel(car)~=GetHashKey(data.model)) then car=0 end
  if data.mode=='convoy' then convoyPaused=data.paused==true end
  queue[#queue+1]={request=data.request,remaining=data.count,model=data.model,look=snapshot(car),
    mode=data.mode or 'support',leader=data.leader and NetworkGetEntityFromNetworkId(data.leader) or 0,convoyEpoch=convoyEpoch}
  notice(('COPOM: %d viatura(s) com quatro policiais adicionada(s) ao %s.'):format(data.count,data.mode=='convoy' and 'comboio' or 'apoio'))
  startWorker()
end)
RegisterNetEvent('prfrp:backup:formation',function(action)
  if not duty then return end
  convoyPaused=action=='hold'
  if action=='dismount' then
    for _,job in ipairs(queue) do job.mode='support' end
    for _,unit in pairs(units) do unit.mode='support';unit.driveAt=0;unit.footAt=0 end
  end
end)
RegisterNetEvent('prfrp:backup:convoyEnded',function()
  convoyEpoch=convoyEpoch+1;convoyPaused=false
  for i=#queue,1,-1 do if queue[i].mode=='convoy' then queue[i].cancelled=true;table.remove(queue,i) end end
  for _,unit in pairs(units) do if unit.mode=='convoy' then removeUnit(unit) end end
end)
RegisterNetEvent('prfrp:ops:clearBackup',clear)
RegisterNetEvent('prfrp:setDuty',function(value) duty=value==true;if not duty then clear() end end)
AddEventHandler('prfrp:baseArrival',function()
  if not duty then return end
  clear();TriggerServerEvent('prfrp:ops:action','dismissBackup')
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then duty=false;clear() end end)
