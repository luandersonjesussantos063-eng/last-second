local lists,pending,last={}, {}, {}
local serial=0
local function clear(src)
  for id,entity in pairs(lists[src] or {}) do
    if NetworkGetEntityFromNetworkId(id)==entity and DoesEntityExist(entity) then DeleteEntity(entity) end
  end
  lists[src],pending[src]=nil,nil
  TriggerClientEvent('prfrp:blitz:clear',src)
end
local function nearby(src,p)
  if type(p)~='table' then return false end
  for _,key in ipairs({'x','y','z'}) do if type(p[key])~='number' or p[key]~=p[key] or math.abs(p[key])>20000 then return false end end
  local ped=GetPlayerPed(src)
  if ped==0 or not DoesEntityExist(ped) or GetVehiclePedIsIn(ped,false)~=0 then return false end
  local q=GetEntityCoords(ped)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2<=10^2
end
RegisterNetEvent('prfrp:blitz:place',function(point)
  local src=source
  if not PrfHasDuty(src) or not nearby(src,point) or (last[src] and GetGameTimer()-last[src]<250) then return end
  if pending[src] and not pending[src].registered and os.time()<pending[src].expires then return end
  local count=0
  for id,entity in pairs(lists[src] or {}) do
    if DoesEntityExist(entity) then count=count+1 else lists[src][id]=nil end
  end
  if count>=60 then TriggerClientEvent('prfrp:operationsNotify',src,'Recolha alguns cones antes de continuar (60 por blitz).');return end
  last[src]=GetGameTimer();serial=serial+1
  pending[src]={token=serial,point=point,expires=os.time()+8}
  TriggerClientEvent('prfrp:blitz:authorized',src,serial,point)
end)
RegisterNetEvent('prfrp:blitz:spawned',function(token,id)
  local src=source
  local job=pending[src]
  if not job or job.token~=token or os.time()>job.expires or not PrfHasDuty(src) or not nearby(src,job.point)
    or type(id)~='number' or id%1~=0 or id<=0 then return end
  local entity=NetworkGetEntityFromNetworkId(id)
  if entity==0 or not DoesEntityExist(entity) or GetEntityType(entity)~=3
    or GetEntityModel(entity)~=GetHashKey('prop_roadcone02a') or NetworkGetEntityOwner(entity)~=src then return end
  local p=GetEntityCoords(entity);local q=job.point
  if (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2>2^2 then return end
  if job.entity and job.entity~=entity then return end
  job.entity=entity;job.registered=true
  lists[src]=lists[src] or {};lists[src][id]=entity
  TriggerClientEvent('prfrp:blitz:registered',src,token)
end)
RegisterNetEvent('prfrp:blitz:clear',function() if PrfHasDuty(source) then clear(source) end end)
AddEventHandler('prfrp:ops:dutyEnded',clear)
AddEventHandler('playerDropped',function() clear(source);last[source]=nil end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then for src in pairs(lists) do clear(src) end end end)

PrfCountBlitzCones=function(src,point,radius)
  local count=0
  for id,e in pairs(lists[src] or {}) do
    if DoesEntityExist(e) and NetworkGetEntityFromNetworkId(id)==e then
      local p=GetEntityCoords(e)
      if (p.x-point.x)^2+(p.y-point.y)^2+(p.z-point.z)^2<radius^2 then count=count+1 end
    end
  end
  return count
end
