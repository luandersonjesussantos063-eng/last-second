-- Paradas persistentes: mudar de alvo ou abordar o motorista nao libera o carro.
local duty,epoch,serial,selected=false,0,0,0
local stops={}
local function notice(text) TriggerEvent('prfrp:chatNotice',text) end
local function active(stop,token) return duty and epoch==token and stops[stop.id]==stop end
local function clearBlip(stop)
  if stop.blip then RemoveBlip(stop.blip);stop.blip=nil end
end
local function restore(car,driver)
  if car~=0 and DoesEntityExist(car) and NetworkHasControlOfEntity(car) then
    SetVehicleHandbrake(car,false)
    SetVehicleEngineOn(car,true,true,false)
    SetEntityAsNoLongerNeeded(car)
  end
  if driver~=0 and DoesEntityExist(driver) and NetworkHasControlOfEntity(driver) and not IsPedAPlayer(driver)
    and not (PrfIsPersonStopped and PrfIsPersonStopped(driver)) then
    SetBlockingOfNonTemporaryEvents(driver,false);SetPedKeepTask(driver,false)
    if not IsEntityDead(driver) then
      if car~=0 and DoesEntityExist(car) and GetVehiclePedIsIn(driver,false)==car then
        TaskVehicleDriveWander(driver,car,15.0,786603)
      else TaskWanderStandard(driver,10.0,10) end
    end
    SetPedAsNoLongerNeeded(driver)
  end
end
local function release(id)
  for netId,stop in pairs(stops) do
    if not id or netId==id then
      stops[netId]=nil;clearBlip(stop);restore(stop.car,stop.driver)
    end
  end
  if not id or selected==id then selected=0;TriggerEvent('prfrp:traffic:selected',0,0) end
end
PrfGetInspectedVehicle=function()
  return stops[selected] and stops[selected].car or 0
end
PrfHasTrafficStops=function() return next(stops)~=nil end
PrfGetPursuitVehicle=function()
  local latest
  for _,stop in pairs(stops) do
    if stop.phase=='flee' and DoesEntityExist(stop.car) and (not latest or stop.number>latest.number) then latest=stop end
  end
  return latest and latest.car or 0
end
local function pursue(stop)
  stop.phase,stop.stillSince='flee',nil
  if not stop.human then
    SetVehicleHandbrake(stop.car,false);SetVehicleEngineOn(stop.car,true,true,false)
    TaskVehicleDriveWander(stop.driver,stop.car,30.0,786468)
  end
  stop.blip=AddBlipForEntity(stop.car)
  SetBlipSprite(stop.blip,225);SetBlipColour(stop.blip,1);SetBlipRoute(stop.blip,true)
  BeginTextCommandSetBlipName('STRING');AddTextComponentString('PRF | Veiculo em fuga');EndTextCommandSetBlipName(stop.blip)
  notice('COPOM: motorista desobedeceu! Perseguicao iniciada. Veiculo marcado no GPS; use reforco se precisar.')
end
local function hold(stop)
  if not NetworkHasControlOfEntity(stop.car) then NetworkRequestControlOfEntity(stop.car);return end
  SetVehicleHandbrake(stop.car,true);SetVehicleEngineOn(stop.car,false,true,true)
  if stop.driver~=0 and DoesEntityExist(stop.driver) and not IsPedAPlayer(stop.driver)
    and GetVehiclePedIsIn(stop.driver,false)==stop.car and NetworkHasControlOfEntity(stop.driver) then
    TaskVehicleTempAction(stop.driver,stop.car,27,1000)
  end
end
local function start(stop)
  local token=epoch
  CreateThread(function()
    local car,driver=stop.car,stop.driver
    if driver==0 then stop.phase='held'
    elseif IsPedAPlayer(driver) then stop.human=true;stop.phase='player';notice('Parada solicitada ao jogador. Aguarde a colaboracao do condutor.')
    else stop.phase='loading' end
    while active(stop,token) and DoesEntityExist(car) do
      local now=GetGameTimer()
      if not stop.towing then
        if stop.phase=='loading' then
          NetworkRequestControlOfEntity(car);NetworkRequestControlOfEntity(driver)
          if NetworkHasControlOfEntity(car) and NetworkHasControlOfEntity(driver) then
            SetEntityAsMissionEntity(car,true,true);SetEntityAsMissionEntity(driver,true,true)
            SetBlockingOfNonTemporaryEvents(driver,true);SetPedKeepTask(driver,true)
            if stop.flee then pursue(stop)
            else
              stop.shoulder=GetOffsetFromEntityInWorldCoords(car,4.0,10.0,0.0)
              local p=stop.shoulder
              local found,z=GetGroundZFor_3dCoord(p.x,p.y,p.z+3.0,false)
              if found and math.abs(z-p.z)<3 then stop.shoulder={x=p.x,y=p.y,z=z} end
              p=stop.shoulder
              SetVehicleHandbrake(car,false);SetVehicleEngineOn(car,true,true,false)
              TaskVehicleDriveToCoordLongrange(driver,car,p.x,p.y,p.z,5.0,786603,2.5)
              stop.phase,stop.deadline='pulling',now+25000
              notice('Parada solicitada. Aguarde o motorista encostar.')
            end
          end
        elseif stop.phase=='pulling' then
          local p,q=GetEntityCoords(car),stop.shoulder
          if (GetEntitySpeed(car)<0.8 and (p.x-q.x)^2+(p.y-q.y)^2<6^2) or now>stop.deadline then
            stop.phase='held';hold(stop)
            notice('Veiculo em abordagem. Permanece parado ate voce digitar liberar ou liberarcarro no T.')
          end
        elseif stop.phase=='held' or stop.phase=='captured' then
          if not stop.human then hold(stop) end
          if stop.human and stop.phase=='held' and GetEntitySpeed(car)>8 then pursue(stop) end
          if stop.phase=='captured' and now>(stop.resolveAt or 0) then
            stop.resolveAt=now+2000;TriggerServerEvent('prfrp:ops:pursuitEnded',stop.id)
          end
        elseif stop.phase=='player' then
          local p=GetEntityCoords(car)
          if GetEntitySpeed(car)>8 and (p.x-stop.origin.x)^2+(p.y-stop.origin.y)^2>25^2 then pursue(stop) end
        elseif stop.phase=='flee' then
          local p,q=GetEntityCoords(car),GetEntityCoords(PlayerPedId())
          if GetEntitySpeed(car)<0.8 then stop.stillSince=stop.stillSince or now
          else stop.stillSince=nil end
          if stop.stillSince and now-stop.stillSince>=6000 and (p.x-q.x)^2+(p.y-q.y)^2<30^2 then
            stop.phase='captured';stop.resolveAt=0
            if not stop.human then hold(stop) end
          end
        end
      end
      Wait(500)
    end
    if stops[stop.id]==stop and not DoesEntityExist(car) then release(stop.id) end
  end)
end
RegisterNetEvent('prfrp:ops:stop',function(id,info)
  if not duty then return end
  local car=NetworkGetEntityFromNetworkId(id)
  if car==0 or not DoesEntityExist(car) then return end
  local stop=stops[id]
  if stop and stop.car~=car then release(id);stop=nil end
  selected=id
  if not stop then
    serial=serial+1
    stop={id=id,car=car,driver=GetPedInVehicleSeat(car,-1),number=serial,
      flee=type(info)=='table' and info.flee==true,origin=GetEntityCoords(car)}
    stops[id]=stop;start(stop)
  end
  TriggerEvent('prfrp:traffic:selected',car,stop.driver)
end)
RegisterNetEvent('prfrp:ops:release',function(id)
  release(type(id)=='number' and id or nil)
  notice('Abordagem do veiculo encerrada.')
end)
RegisterNetEvent('prfrp:traffic:resolved',function(id)
  local stop=stops[id]
  if stop then stop.phase='held';clearBlip(stop);notice('Perseguicao encerrada. Veiculo imobilizado ate liberacao no T.') end
end)
RegisterNetEvent('prfrp:traffic:resume',function(id,driverId)
  local stop=stops[id]
  local car=NetworkGetEntityFromNetworkId(id)
  local driver=driverId and driverId~=0 and NetworkGetEntityFromNetworkId(driverId) or 0
  if stop then release(id) end
  CreateThread(function()
    for i=1,12 do
      restore(car,driver)
      if car==0 or not DoesEntityExist(car) or NetworkHasControlOfEntity(car) then break end
      Wait(250)
    end
  end)
end)
AddEventHandler('prfrp:traffic:releaseLocal',function(id) release(id) end)
AddEventHandler('prfrp:traffic:towing',function(car,value)
  for _,stop in pairs(stops) do if stop.car==car then stop.towing=value;clearBlip(stop) end end
end)
AddEventHandler('prfrp:traffic:cancelPursuit',function()
  local car=PrfGetPursuitVehicle()
  if car==0 then notice('Nenhuma perseguicao ativa.');return end
  TriggerServerEvent('prfrp:ops:action','cancelPursuit',NetworkGetNetworkIdFromEntity(car))
end)
RegisterNetEvent('prfrp:setDuty',function(value)
  duty=value==true
  if not duty then epoch=epoch+1;release() end
end)
AddEventHandler('prfrp:baseArrival',function() epoch=epoch+1;release() end)
AddEventHandler('onResourceStop',function(name)
  if name==GetCurrentResourceName() then duty=false;epoch=epoch+1;release() end
end)
