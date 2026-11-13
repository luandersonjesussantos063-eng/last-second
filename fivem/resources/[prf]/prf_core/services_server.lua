local jobs,serial={},0
local function notice(src,text) TriggerClientEvent('prfrp:operationsNotify',src,text) end
local function near(a,b,r)
  local p,q=GetEntityCoords(a),GetEntityCoords(b)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2<=r*r
end
local function clear(src,kind)
  local job=jobs[src] and jobs[src][kind]
  if not job then return end
  for id,entity in pairs(job.entities or {}) do
    if NetworkGetEntityFromNetworkId(id)==entity and DoesEntityExist(entity) then DeleteEntity(entity) end
  end
  jobs[src][kind]=nil
  TriggerClientEvent('prfrp:services:clear',src,kind)
end
RegisterNetEvent('prfrp:services:request',function(kind,data)
  local src=source
  if not PrfHasDuty(src) or not Config.Services[kind] then return end
  jobs[src]=jobs[src] or {}
  if jobs[src][kind] then notice(src,'Esse servico ja esta em atendimento.');return end
  local target=GetPlayerPed(src)
  if kind~='ambulance' then
    local id=type(data)=='table' and data.vehicle
    target=type(id)=='number' and NetworkGetEntityFromNetworkId(id) or 0
    if target==0 or not DoesEntityExist(target) or GetEntityType(target)~=2 or not near(GetPlayerPed(src),target,35) then
      notice(src,'Aproxime-se da viatura para chamar esse atendimento.');return
    end
  end
  serial=serial+1
  jobs[src][kind]={token=serial,target=target,targetModel=GetEntityModel(target),expires=os.time()+120}
  TriggerClientEvent('prfrp:services:dispatch',src,kind,serial,kind=='ambulance' and 0 or NetworkGetNetworkIdFromEntity(target))
  notice(src,Config.Services[kind].name..' acionado. Aguarde em local acessivel.')
end)
RegisterNetEvent('prfrp:services:spawned',function(kind,token,carId,pedId)
  local src=source
  local job=jobs[src] and jobs[src][kind]
  if not job or job.token~=token or not PrfHasDuty(src) then return end
  if type(carId)~='number' or carId<=0 or carId%1~=0 or type(pedId)~='number' or pedId<=0 or pedId%1~=0 then return end
  local def=Config.Services[kind]
  local car,ped=NetworkGetEntityFromNetworkId(carId),NetworkGetEntityFromNetworkId(pedId)
  if car==0 or ped==0 or not DoesEntityExist(car) or not DoesEntityExist(ped)
    or GetEntityType(car)~=2 or GetEntityType(ped)~=1 or not near(car,ped,8)
    or GetEntityModel(car)~=GetHashKey(def.vehicle) or GetEntityModel(ped)~=GetHashKey(def.ped)
    or NetworkGetEntityOwner(car)~=src or NetworkGetEntityOwner(ped)~=src
    or not near(GetPlayerPed(src),car,200) then return end
  if job.entities and (job.car~=car or job.worker~=ped) then return end
  job.car,job.worker=car,ped;job.entities={[carId]=car,[pedId]=ped}
  TriggerClientEvent('prfrp:services:registered',src,kind,token)
end)
RegisterNetEvent('prfrp:services:arrived',function(kind,token)
  local src=source
  local job=jobs[src] and jobs[src][kind]
  if not job or job.token~=token or job.performing or not PrfHasDuty(src) then return end
  local target=kind=='ambulance' and GetPlayerPed(src) or job.target
  if not job.worker or not DoesEntityExist(job.worker) or GetEntityHealth(job.worker)<=0
    or not DoesEntityExist(target) or (kind~='ambulance' and GetEntityModel(target)~=job.targetModel) or not near(job.worker,target,5)
    or not near(GetPlayerPed(src),target,35) then return end
  job.performing=true;job.expires=os.time()+20
  TriggerClientEvent('prfrp:services:perform',src,kind,token,kind=='ambulance' and 0 or NetworkGetNetworkIdFromEntity(target))
end)
RegisterNetEvent('prfrp:services:finished',function(kind,token,success)
  local src=source
  local job=jobs[src] and jobs[src][kind]
  if not job or job.token~=token then return end
  if success==true and not job.performing then return end
  notice(src,success==true and (Config.Services[kind].name..': atendimento concluido.') or 'Atendimento encerrado sem acesso ao alvo.')
  clear(src,kind)
end)
local function clearAll(src) for kind in pairs(jobs[src] or {}) do clear(src,kind) end;jobs[src]=nil end
AddEventHandler('prfrp:ops:dutyEnded',clearAll)
AddEventHandler('playerDropped',function() clearAll(source) end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then for src in pairs(jobs) do clearAll(src) end end end)
CreateThread(function()
  while true do Wait(5000);for src,list in pairs(jobs) do for kind,job in pairs(list) do if os.time()>job.expires then clear(src,kind) end end end end
end)
