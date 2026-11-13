local duty,epoch=false,0
local job,pending=nil,nil
local candidate,since,lastAim=0,0,0
local function notice(text) TriggerEvent('prfrp:chatNotice',text) end
local function alive(e) return e and e~=0 and DoesEntityExist(e) and not IsEntityDead(e) end
local function same(j,token) return duty and epoch==token and job==j end
PrfIsChauffeur=function(ped) return (job and job.driver==ped) or (pending and pending.driver==ped) or false end
PrfGetDriverVehicle=function() return job and job.ready and job.car or 0 end
PrfDriverIsPassenger=function() return job and job.ready and GetVehiclePedIsIn(PlayerPedId(),false)==job.car and GetPedInVehicleSeat(job.car,-1)==job.driver end
local function clear()
  epoch=epoch+1
  local j=job;job,pending=nil,nil;candidate,since=0,0
  if j then
    if alive(j.driver) and NetworkHasControlOfEntity(j.driver) then ClearPedTasks(j.driver);TaskLeaveVehicle(j.driver,j.car,0) end
    if DoesEntityExist(j.car) then
      local manual=j.takeover or GetPedInVehicleSeat(j.car,-1)==PlayerPedId()
      SetVehicleHandbrake(j.car,not manual)
      if not manual then
        CreateThread(function()
          Wait(1800)
          if DoesEntityExist(j.car) and (not job or job.car~=j.car) then SetVehicleHandbrake(j.car,false) end
        end)
      end
    end
    if j.pistolGranted and j.player==PlayerPedId() then RemoveWeaponFromPed(j.player,GetHashKey(Config.Driver.weapon)) end
  end
end
local function halt(j)
  if alive(j.driver) and GetVehiclePedIsIn(j.driver,false)==j.car then TaskVehicleTempAction(j.driver,j.car,27,1500) end
  SetVehicleHandbrake(j.car,true)
end
local function passengerSeat(j)
  for seat=0,GetVehicleMaxNumberOfPassengers(j.car)-1 do if IsVehicleSeatFree(j.car,seat,true) or GetPedInVehicleSeat(j.car,seat)==PlayerPedId() then return seat end end
end
local function enterPassenger(j,token)
  local car=j.car;local ped=PlayerPedId()
  if not alive(car) then return false end
  if GetVehiclePedIsIn(ped,false)==car and GetPedInVehicleSeat(car,-1)~=ped then return true end
  local seat=passengerSeat(j)
  if not seat then notice('Aguarde um banco livre na sua viatura.');return false end
  if GetVehiclePedIsIn(ped,false)==car then SetPedIntoVehicle(ped,car,seat)
  else
    if #(GetEntityCoords(ped)-GetEntityCoords(car))>12 then notice('Aproxime-se da viatura para embarcar.');return false end
    TaskEnterVehicle(ped,car,8000,seat,1.8,1,0)
    local started=GetGameTimer()
    while same(j,token) and GetVehiclePedIsIn(ped,false)~=car and GetGameTimer()-started<8000 do Wait(100) end
  end
  return same(j,token) and GetVehiclePedIsIn(ped,false)==car and GetPedInVehicleSeat(car,-1)~=ped
end
AddEventHandler('prfrp:driver:command',function(action)
  if not duty then notice('Digite servico primeiro.');return end
  if action=='driverStop' or action=='driverResume' or action=='driverTakeover' then
    TriggerServerEvent('prfrp:driver:control',({driverStop='stop',driverResume='resume',driverTakeover='takeover'})[action]);return
  elseif action=='driverBoard' then
    if not job or not job.ready then notice('Ative motorista primeiro.');return end
    local j,token=job,epoch;CreateThread(function() enterPassenger(j,token) end);return
  end
  if job then TriggerServerEvent('prfrp:driver:control','takeover');return end
  if pending then notice('Aguarde o motorista embarcar.');return end
  local car=GetVehiclePedIsIn(PlayerPedId(),false)
  if car==0 and PrfGetPatrolVehicle then car=PrfGetPatrolVehicle() end
  local driver=PrfGetSquadOfficer and PrfGetSquadOfficer(1)
  if not alive(car) or not alive(driver) then notice('Pegue a viatura, aguarde sua equipe e digite motorista com o carro parado.');return end
  pending={car=car,driver=driver};local current,token=pending,epoch
  CreateThread(function()
    if not NetworkGetEntityIsNetworked(driver) then NetworkRegisterEntityAsNetworked(driver);Wait(150) end
    if not duty or token~=epoch or pending~=current then return end
    local id=NetworkGetNetworkIdFromEntity(driver)
    if id==0 then pending=nil;notice('Equipe ainda carregando. Tente motorista novamente.');return end
    TriggerServerEvent('prfrp:driver:request',NetworkGetNetworkIdFromEntity(car),id)
    Wait(4000)
    if pending==current then pending=nil;notice('Motorista nao autorizado ou equipe indisponivel. Confira se o carro esta parado.');return end
  end)
end)
RegisterNetEvent('prfrp:driver:approved',function(id,carId,driverId)
  if not duty then return end
  pending=nil
  local j={id=id,car=NetworkGetEntityFromNetworkId(carId),driver=NetworkGetEntityFromNetworkId(driverId),mode='navigation',player=PlayerPedId()}
  job=j;local token=epoch
  CreateThread(function()
    halt(j)
    if GetVehiclePedIsIn(j.driver,false)==j.car then TaskLeaveVehicle(j.driver,j.car,0) end
    local started=GetGameTimer()
    while same(j,token) and GetVehiclePedIsIn(j.driver,false)~=0 and GetGameTimer()-started<4000 do Wait(100) end
    if not same(j,token) then return end
    if not enterPassenger(j,token) then TriggerServerEvent('prfrp:driver:cancel',id);return end
    TaskEnterVehicle(j.driver,j.car,8000,-1,2.0,1,0)
    started=GetGameTimer()
    while same(j,token) and GetPedInVehicleSeat(j.car,-1)~=j.driver and GetGameTimer()-started<8000 do Wait(100) end
    if not same(j,token) then return end
    for attempt=1,10 do
      TriggerServerEvent('prfrp:driver:ready',id);Wait(250)
      if not same(j,token) or j.ready then return end
    end
    if same(j,token) then TriggerServerEvent('prfrp:driver:cancel',id);notice('Nao foi possivel concluir o embarque do motorista.');end
  end)
end)
RegisterNetEvent('prfrp:driver:ready',function(id)
  if not job or job.id~=id or job.ready then return end
  job.ready=true
  SetDriverAbility(job.driver,1.0);SetDriverAggressiveness(job.driver,0.3)
  local weapon=GetHashKey(Config.Driver.weapon)
  job.pistolGranted=not HasPedGotWeapon(PlayerPedId(),weapon,false)
  if job.pistolGranted then GiveWeaponToPed(PlayerPedId(),weapon,120,false,false) end
  SetCurrentPedWeapon(PlayerPedId(),weapon,true)
  notice('Motorista no volante. Marque um destino no mapa. L/O: giroflex e sirene; Z: mirar para abordar; continuar: retomar; assumir: dirigir voce.')
end)
RegisterNetEvent('prfrp:driver:clear',clear)
RegisterNetEvent('prfrp:driver:control',function(id,action)
  local j=job;if not j or j.id~=id then return end
  j.control=(j.control or 0)+1
  local revision=j.control
  if action=='takeover' then
    j.mode='hold';j.takeover=true;halt(j);local token=epoch
    CreateThread(function()
      local start=GetGameTimer()
      while same(j,token) and j.control==revision and GetEntitySpeed(j.car)>0.8 and GetGameTimer()-start<7000 do Wait(100) end
      if not same(j,token) or j.control~=revision then return end
      if GetEntitySpeed(j.car)>0.8 then j.takeover=false;notice('Aguarde a viatura parar para assumir.');return end
      local car=j.car
      TriggerServerEvent('prfrp:driver:cancel',id)
      TaskLeaveVehicle(j.driver,car,0)
      start=GetGameTimer()
      while DoesEntityExist(car) and GetPedInVehicleSeat(car,-1)~=0 and GetGameTimer()-start<4000 do Wait(100) end
      if alive(car) and GetPedInVehicleSeat(car,-1)==0 and #(GetEntityCoords(PlayerPedId())-GetEntityCoords(car))<12 then
        SetVehicleHandbrake(car,false)
        if GetVehiclePedIsIn(PlayerPedId(),false)==car then SetPedIntoVehicle(PlayerPedId(),car,-1)
        else TaskEnterVehicle(PlayerPedId(),car,8000,-1,1.8,1,0) end
      end
    end)
  else
    j.takeover=false;j.target=nil;j.mode=action=='stop' and 'hold' or 'navigation';j.routeAt=0;j.arrived=false;j.stopSent=nil
    if action=='stop' then halt(j) end
    notice(action=='stop' and 'Viatura parada. Use continuar para retomar o GPS.' or 'Motorista retomando o destino marcado.')
  end
end)
RegisterNetEvent('prfrp:driver:intercept',function(id,netId,kind)
  if not job or job.id~=id then return end
  job.target={id=netId,kind=kind};job.mode='intercept';job.routeAt=0;job.stopSent=false;job.personSent=false
  notice(kind=='vehicle' and 'Motorista interceptando o veiculo. Aguarde a parada ou a perseguicao.' or 'Motorista parando para abordar a pessoa. Desembarque para fiscalizar.')
end)
local function aimTarget()
  if not PrfDriverIsPassenger() or IsNuiFocused() then return end
  local found,target=GetEntityPlayerIsFreeAimingAt(PlayerId())
  if not found or target==job.car or target==job.driver then
    local j=job
    local p,r=GetGameplayCamCoord(),GetGameplayCamRot(2)
    local pitch,yaw=math.rad(r.x),math.rad(r.z)
    local dx,dy,dz=-math.sin(yaw)*math.cos(pitch),math.cos(yaw)*math.cos(pitch),math.sin(pitch)
    local ray=StartShapeTestRay(p.x,p.y,p.z,p.x+dx*85,p.y+dy*85,p.z+dz*85,31,j.car,7)
    local status,hit,_,_,entity=GetShapeTestResult(ray)
    local started=GetGameTimer()
    while status==1 and job==j and GetGameTimer()-started<120 do Wait(0);status,hit,_,_,entity=GetShapeTestResult(ray) end
    if job~=j then return end
    found,target=status==2 and hit,entity
  end
  if not found or not alive(target) or target==job.car or target==job.driver then return end
  if GetEntityType(target)==1 then
    if (PrfIsCompanion and PrfIsCompanion(target)) or (PrfIsBackup and PrfIsBackup(target)) or (PrfIsServiceStaff and PrfIsServiceStaff(target)) then return end
    local car=GetVehiclePedIsIn(target,false)
    if car~=0 then target=car end
  end
  local kind=GetEntityType(target)==2 and 'vehicle' or GetEntityType(target)==1 and 'ped' or nil
  if not kind or target==job.car or #(GetEntityCoords(target)-GetEntityCoords(job.car))>(kind=='vehicle' and 80 or 35) then return end
  if kind=='vehicle' then
    local driver=GetPedInVehicleSeat(target,-1)
    if driver~=0 and ((PrfIsCompanion and PrfIsCompanion(driver)) or (PrfIsBackup and PrfIsBackup(driver))
      or (PrfIsServiceStaff and PrfIsServiceStaff(driver))) then return end
  end
  return target,kind
end
local function requestIntercept(target,kind)
  if not job or not target or GetGameTimer()-lastAim<1800 then return end
  lastAim=GetGameTimer();local j,token=job,epoch
  CreateThread(function()
    if not NetworkGetEntityIsNetworked(target) then NetworkRegisterEntityAsNetworked(target);Wait(150) end
    if same(j,token) and alive(target) then TriggerServerEvent('prfrp:driver:intercept',j.id,NetworkGetNetworkIdFromEntity(target),kind) end
  end)
end
AddEventHandler('prfrp:driver:approach',function()
  local target,kind=aimTarget()
  if target then requestIntercept(target,kind) else notice('Mire na pessoa ou no veiculo para o motorista interceptar.');end
end)
AddEventHandler('prfrp:driver:toggleAimWeapon',function()
  if not PrfDriverIsPassenger() then return end
  local weapon=GetHashKey(Config.Driver.weapon)
  SetCurrentPedWeapon(PlayerPedId(),GetSelectedPedWeapon(PlayerPedId())==weapon and GetHashKey('WEAPON_UNARMED') or weapon,true)
end)
local function drive(j)
  local now=GetGameTimer()
  if j.takeover then
    if GetPedInVehicleSeat(j.car,-1)==PlayerPedId() then SetVehicleHandbrake(j.car,false) else halt(j) end
    return
  end
  if not PrfDriverIsPassenger() then halt(j);return end
  if j.mode=='hold' then halt(j);return end
  local pursuit=PrfGetPursuitVehicle and PrfGetPursuitVehicle() or 0
  if j.target then
    local target=NetworkGetEntityFromNetworkId(j.target.id)
    if not alive(target) then j.target=nil;j.mode='hold';halt(j);notice('Alvo indisponivel. Use continuar para retomar o GPS.');return end
    local d=#(GetEntityCoords(target)-GetEntityCoords(j.car))
    if j.target.kind=='ped' then
      if d<12 then
        halt(j)
        if GetEntitySpeed(j.car)<0.8 and not j.personSent then j.personSent=true;TriggerServerEvent('prfrp:person:approach',j.target.id);j.mode='hold' end
      elseif now>=(j.routeAt or 0) then
        local p=GetEntityCoords(target);SetVehicleHandbrake(j.car,false)
        TaskVehicleDriveToCoordLongrange(j.driver,j.car,p.x,p.y,p.z,10.0,786603,6.0);j.routeAt=now+2000
      end
      return
    end
    if d<34 and not j.stopSent then j.stopSent=now;TriggerServerEvent('prfrp:ops:action','stop',j.target.id) end
    if j.stopSent and now-j.stopSent>2500 and pursuit==0 and GetEntitySpeed(target)<1 and d<20 then j.mode='hold';halt(j);return end
    pursuit=target
  end
  if pursuit~=0 and alive(pursuit) then
    SetVehicleHandbrake(j.car,false)
    if now>=(j.routeAt or 0) or j.chase~=pursuit then
      TaskVehicleChase(j.driver,pursuit);SetDriveTaskDrivingStyle(j.driver,786468);j.routeAt=now+8000;j.chase=pursuit
    end
    SetDriveTaskCruiseSpeed(j.driver,math.min(60.0,math.max(35.0,GetEntitySpeed(pursuit)+6.0)));return
  end
  j.chase=nil
  local waypoint=GetFirstBlipInfoId(8)
  if not DoesBlipExist(waypoint) then
    halt(j)
    if not j.noWaypoint then notice('Marque um destino no mapa para o motorista seguir.');j.noWaypoint=true end
    return
  end
  local p=GetBlipInfoIdCoord(waypoint)
  if not j.destination or #(p-j.destination)>12 then j.destination=p;j.arrived=false;j.routeAt=0;j.noWaypoint=false end
  if #(GetEntityCoords(j.car)-vector3(p.x,p.y,GetEntityCoords(j.car).z))<18 then
    halt(j);if not j.arrived then notice('Destino alcancado. Marque outro ponto ou use assumir.');j.arrived=true end;return
  end
  local urgent=PrfIsEmergencyDriving and PrfIsEmergencyDriving() or false
  if now>=(j.routeAt or 0) or urgent~=j.urgent then
    local found,node=GetClosestVehicleNodeWithHeading(p.x,p.y,p.z,1,3.0,0)
    if not found or (node.x-p.x)^2+(node.y-p.y)^2>150^2 then halt(j);notice('Sem via acessivel nesse ponto. Marque um destino proximo da rua.');j.routeAt=now+8000;return end
    SetVehicleHandbrake(j.car,false)
    TaskVehicleDriveToCoordLongrange(j.driver,j.car,node.x,node.y,node.z,urgent and Config.Driver.emergencySpeed or Config.Driver.cruiseSpeed,urgent and 786468 or 786603,8.0)
    j.routeAt=now+8000;j.urgent=urgent
  end
end
RegisterNetEvent('prfrp:setDuty',function(enabled) duty=enabled==true;if not duty then clear() end end)
AddEventHandler('prfrp:baseArrival',function() if job then TriggerServerEvent('prfrp:driver:cancel',job.id) end;clear() end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then if job then TriggerServerEvent('prfrp:driver:cancel',job.id) end;clear();duty=false end end)
CreateThread(function()
  local driveAt=0
  while true do
    local wait=750
    if job and job.ready then
      wait=150
      if not alive(PlayerPedId()) or not alive(job.car) or not alive(job.driver) then TriggerServerEvent('prfrp:driver:cancel',job.id);clear()
      else
        if GetGameTimer()>=driveAt then drive(job);driveAt=GetGameTimer()+600 end
        if PrfDriverIsPassenger() and not IsNuiFocused() and IsPedArmed(PlayerPedId(),4)
          and (IsPlayerFreeAiming(PlayerId()) or (PrfIsAimHeld and PrfIsAimHeld())) then
          local target,kind=aimTarget()
          if target~=candidate then candidate,since=target,GetGameTimer()
          elseif target and GetGameTimer()-since>=450 and (not job.target or job.target.id~=NetworkGetNetworkIdFromEntity(target)) then requestIntercept(target,kind) end
        else candidate,since=0,0 end
      end
    end
    Wait(wait)
  end
end)
