-- Um motorista NPC por policial; nao transfere controle de outros jogadores.
local jobs,serial,last={},0,{}
local function notice(src,text) TriggerClientEvent('prfrp:operationsNotify',src,text) end
local function near(a,b,r)
  local p,q=GetEntityCoords(a),GetEntityCoords(b)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2<=r*r
end
local function resolve(src)
  local j=jobs[src]
  if not j or not PrfHasDuty(src) or GetEntityHealth(GetPlayerPed(src))<=0 then return end
  if NetworkGetEntityFromNetworkId(j.carId)~=j.car or NetworkGetEntityFromNetworkId(j.driverId)~=j.driver
    or not DoesEntityExist(j.car) or not DoesEntityExist(j.driver) or GetEntityModel(j.car)~=j.model
    or GetEntityHealth(j.driver)<=0 or GetEntityHealth(j.car)<=0 then return end
  return j
end
local function clear(src,message)
  jobs[src]=nil
  TriggerClientEvent('prfrp:driver:clear',src)
  if message then notice(src,message) end
end
local function human(ped)
  for _,id in ipairs(GetPlayers()) do if GetPlayerPed(tonumber(id))==ped then return true end end
  return false
end
PrfIsDriverVehicle=function(src,car)
  local j=resolve(src)
  return j and j.ready and j.car==car and GetPedInVehicleSeat(car,-1)==j.driver and near(GetPlayerPed(src),car,60) or false
end
PrfOfficerCanStopPersonFromVehicle=function(src,car,target)
  local j=resolve(src)
  return j and PrfIsDriverVehicle(src,car) and GetVehiclePedIsIn(GetPlayerPed(src),false)==car
    and GetEntitySpeed(car)<1.0 and j.target and j.target.kind=='ped' and j.target.entity==target
    and NetworkGetEntityFromNetworkId(j.target.id)==target and GetEntityModel(target)==j.target.model
    and os.time()<j.target.expires or false
end
RegisterNetEvent('prfrp:driver:request',function(carId,driverId)
  local src=source
  if not PrfHasDuty(src) or GetEntityHealth(GetPlayerPed(src))<=0 then return end
  if jobs[src] then notice(src,'Motorista ja acionado. Use continuar, embarcar ou assumir.');return end
  if last[src] and os.time()-last[src]<2 then return end
  last[src]=os.time()
  if type(carId)~='number' or carId<=0 or carId%1~=0 or type(driverId)~='number' or driverId<=0 or driverId%1~=0 then return end
  local car,driver=NetworkGetEntityFromNetworkId(carId),NetworkGetEntityFromNetworkId(driverId)
  if car==0 or driver==0 or not DoesEntityExist(car) or not DoesEntityExist(driver)
    or GetEntityType(car)~=2 or GetEntityType(driver)~=1 or human(driver)
    or NetworkGetEntityOwner(driver)~=src or not near(GetPlayerPed(src),car,12) or not near(driver,car,18)
    or GetEntitySpeed(car)>1.0 or GetEntityHealth(driver)<=0 then notice(src,'Pare sua viatura e aproxime a equipe antes de chamar motorista.');return end
  local fleet=false
  for _,e in ipairs(Config.Fleet) do if GetEntityModel(car)==GetHashKey(e.model) and e.model~='policeb' then fleet=true end end
  local hash=GetEntityModel(driver)
  local occupant=GetPedInVehicleSeat(car,-1)
  if not fleet or (hash~=GetHashKey(Config.PRFSkinModel) and hash~=GetHashKey('s_m_y_hwaycop_01'))
    or (occupant~=0 and occupant~=GetPlayerPed(src) and occupant~=driver) then notice(src,'Use uma viatura PRF com um colega da sua equipe.');return end
  serial=serial+1
  jobs[src]={token=serial,car=car,driver=driver,carId=carId,driverId=driverId,model=GetEntityModel(car),expires=os.time()+20}
  TriggerClientEvent('prfrp:driver:approved',src,serial,carId,driverId)
end)
RegisterNetEvent('prfrp:driver:ready',function(token)
  local src=source;local j=resolve(src)
  if not j or j.token~=token or GetVehiclePedIsIn(GetPlayerPed(src),false)~=j.car or GetPedInVehicleSeat(j.car,-1)~=j.driver then return end
  j.ready=true
  TriggerClientEvent('prfrp:driver:ready',src,token)
end)
RegisterNetEvent('prfrp:driver:control',function(action)
  local src=source;local j=resolve(src)
  if not j then clear(src);return end
  if action~='stop' and action~='resume' and action~='takeover' then return end
  if not near(GetPlayerPed(src),j.car,15) then notice(src,'Aproxime-se da sua viatura.');return end
  j.target=nil
  TriggerClientEvent('prfrp:driver:control',src,j.token,action)
end)
RegisterNetEvent('prfrp:driver:intercept',function(token,id,kind)
  local src=source;local j=resolve(src)
  if not j or j.token~=token or not j.ready or GetVehiclePedIsIn(GetPlayerPed(src),false)~=j.car then return end
  if kind~='ped' and kind~='vehicle' then return end
  if j.aimAt and os.time()-j.aimAt<1 then return end
  if PrfHasArrest and PrfHasArrest(src) then notice(src,'Conclua a custodia atual antes de iniciar outra abordagem.');return end
  if type(id)~='number' or id<=0 or id%1~=0 then return end
  local e=NetworkGetEntityFromNetworkId(id)
  if e==0 or not DoesEntityExist(e) or e==j.car or e==j.driver or e==GetPlayerPed(src)
    or GetEntityType(e)~=(kind=='vehicle' and 2 or 1) or GetEntityHealth(e)<=0
    or not near(j.car,e,kind=='vehicle' and 85 or 35) or (kind=='ped' and GetVehiclePedIsIn(e,false)~=0) then return end
  j.aimAt=os.time();j.target={id=id,entity=e,model=GetEntityModel(e),kind=kind,expires=os.time()+120}
  TriggerClientEvent('prfrp:driver:intercept',src,j.token,id,kind)
end)
RegisterNetEvent('prfrp:driver:cancel',function(token)
  local j=jobs[source];if j and j.token==token then clear(source) end
end)
AddEventHandler('prfrp:ops:dutyEnded',function(src) clear(src) end)
AddEventHandler('playerDropped',function() jobs[source],last[source]=nil,nil end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then for src in pairs(jobs) do clear(src) end end end)
CreateThread(function()
  while true do
    Wait(2000)
    for src,j in pairs(jobs) do
      if not resolve(src) or (not j.ready and os.time()>j.expires)
        or (j.ready and (GetPedInVehicleSeat(j.car,-1)~=j.driver or not near(GetPlayerPed(src),j.car,120))) then
        clear(src,'Motorista indisponivel. Pare a viatura e assuma o volante ou chame motorista novamente.')
      end
    end
  end
end)
