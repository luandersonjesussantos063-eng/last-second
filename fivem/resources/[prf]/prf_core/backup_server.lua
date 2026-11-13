-- Cada chamada acrescenta unidades; nao ha cota de viaturas ativas por policial.
local requests, units, serial = {}, {}, 0
local function notify(src,text) TriggerClientEvent('prfrp:operationsNotify',src,text) end
local function permitted(src) return PrfHasDuty and PrfHasDuty(src) end
local function closeTo(src,entity,radius)
  local p,q=GetEntityCoords(GetPlayerPed(src)),GetEntityCoords(entity)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2<=radius^2
end
local function fleetEntry(entity)
  local hash=GetEntityModel(entity)
  for _,entry in ipairs(Config.Fleet) do if GetHashKey(entry.model)==hash then return entry end end
end
PrfRequestBackup = function(src,data)
  if not permitted(src) then return end
  data=type(data)=='table' and data or {}
  local count=data.count or 1
  if type(count)~='number' or count~=count or count%1~=0 or count<1 or count>2147483647 then
    notify(src,'Use reforco ou reforco 3. A quantidade precisa ser um numero inteiro positivo.'); return
  end
  local template=GetVehiclePedIsIn(GetPlayerPed(src),false)
  if template==0 and type(data.template)=='number' and data.template>0 and data.template%1==0 then
    local candidate=NetworkGetEntityFromNetworkId(data.template)
    if candidate~=0 and DoesEntityExist(candidate) and GetEntityType(candidate)==2
      and closeTo(src,candidate,50) then template=candidate end
  end
  local entry=template~=0 and DoesEntityExist(template) and fleetEntry(template) or nil
  if not entry then
    template=0
    for _,item in ipairs(Config.Fleet) do if item.model==Config.Vehicle then entry=item;break end end
  end
  if not entry then return end
  if entry.resource and GetResourceState(entry.resource)~='started'
    and (not entry.alternateResource or GetResourceState(entry.alternateResource)~='started') then
    notify(src,'A viatura PRF precisa estar iniciada antes do reforco.'); return
  end
  serial=serial+1
  requests[src]=requests[src] or {}
  requests[src][serial]={remaining=count,model=entry.model}
  TriggerClientEvent('prfrp:ops:backup',src,{request=serial,count=count,model=entry.model,
    template=template~=0 and NetworkGetNetworkIdFromEntity(template) or 0})
end
local function clear(src)
  for _,unit in pairs(units[src] or {}) do
    for id,entity in pairs(unit.entities) do
      if NetworkGetEntityFromNetworkId(id)==entity and DoesEntityExist(entity) then DeleteEntity(entity) end
    end
  end
  requests[src],units[src]=nil,nil
  TriggerClientEvent('prfrp:ops:clearBackup',src)
end
PrfDismissBackup = clear
RegisterNetEvent('prfrp:ops:registerBackup',function(requestId,carId,pedIds)
  local src=source
  if not permitted(src) or type(carId)~='number' or carId%1~=0 then return end
  local previous=units[src] and units[src][carId]
  if previous then TriggerClientEvent('prfrp:ops:backupRegistered',src,carId);return end
  local request=requests[src] and requests[src][requestId]
  if not request or request.remaining<=0 or type(pedIds)~='table' or #pedIds~=2 then return end
  local car=NetworkGetEntityFromNetworkId(carId)
  if car==0 or not DoesEntityExist(car) or GetEntityType(car)~=2
    or GetEntityModel(car)~=GetHashKey(request.model) or NetworkGetEntityOwner(car)~=src
    or not closeTo(src,car,250) then return end
  local entities={[carId]=car}
  for _,id in ipairs(pedIds) do
    if type(id)~='number' or id<=0 or id%1~=0 or entities[id] then return end
    local ped=NetworkGetEntityFromNetworkId(id)
    if ped==0 or not DoesEntityExist(ped) or GetEntityType(ped)~=1
      or NetworkGetEntityOwner(ped)~=src or not closeTo(src,ped,250) then return end
    local hash=GetEntityModel(ped)
    if hash~=GetHashKey(Config.PRFSkinModel) and hash~=GetHashKey('s_m_y_hwaycop_01') then return end
    entities[id]=ped
  end
  units[src]=units[src] or {}
  units[src][carId]={entities=entities}
  if PrfCopomEvidence then PrfCopomEvidence(src,'backup',car) end
  request.remaining=request.remaining-1
  if request.remaining==0 then requests[src][requestId]=nil end
  TriggerClientEvent('prfrp:ops:backupRegistered',src,carId)
end)
AddEventHandler('prfrp:ops:dutyEnded',clear)
AddEventHandler('playerDropped',function() clear(source) end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for src in pairs(units) do clear(src) end
end)
