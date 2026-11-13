-- Chamadas acrescentam unidades; cada viatura chega com motorista e tres passageiros.
local requests,units,convoyPaused,serial={}, {}, {},0
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
local function entryByName(name)
  for _,entry in ipairs(Config.Fleet) do if entry.model==name then return entry end end
end
local function human(ped)
  for _,id in ipairs(GetPlayers()) do if GetPlayerPed(tonumber(id))==ped then return true end end
  return false
end
PrfRequestBackup=function(src,data)
  if not permitted(src) then return end
  data=type(data)=='table' and data or {}
  local mode=data.mode or 'support'
  if mode~='support' and mode~='convoy' then return end
  local count=data.count or (mode=='convoy' and Config.Backup.convoyDefault or 1)
  if type(count)~='number' or count~=count or count%1~=0 or count<1 or count>2147483647 then
    notify(src,'Use apoio 3 ou comboio 3. A quantidade precisa ser um numero inteiro positivo.');return
  end
  local template=GetVehiclePedIsIn(GetPlayerPed(src),false)
  if template==0 and type(data.template)=='number' and data.template>0 and data.template%1==0 then
    local e=NetworkGetEntityFromNetworkId(data.template)
    if e~=0 and DoesEntityExist(e) and GetEntityType(e)==2 and closeTo(src,e,50) then template=e end
  end
  local entry=template~=0 and DoesEntityExist(template) and fleetEntry(template) or nil
  if mode=='convoy' then
    if not entry then notify(src,'Pegue sua viatura PRF e deixe-a proxima antes de chamar o comboio.');return end
    local driver=GetPedInVehicleSeat(template,-1)
    if driver~=0 and driver~=GetPlayerPed(src) and not (PrfIsDriverVehicle and PrfIsDriverVehicle(src,template)) then notify(src,'Assuma o volante da sua viatura para liderar o comboio.');return end
  end
  local sourceVehicle=template
  if not entry then template=0;entry=entryByName(Config.Backup.fallback) end
  local override=entry and Config.Backup.vehicleOverrides[entry.model]
  if override then
    entry=entryByName(override);template=0
    notify(src,'O apoio usa o SUV PRF para acomodar quatro policiais quando voce esta de moto.')
  end
  if not entry then return end
  if entry.resource and GetResourceState(entry.resource)~='started'
    and (not entry.alternateResource or GetResourceState(entry.alternateResource)~='started') then
    notify(src,'A viatura PRF precisa estar iniciada antes do apoio.');return
  end
  serial=serial+1;requests[src]=requests[src] or {}
  requests[src][serial]={remaining=count,model=entry.model,mode=mode,sourceVehicle=sourceVehicle}
  TriggerClientEvent('prfrp:ops:backup',src,{request=serial,count=count,model=entry.model,mode=mode,
    leader=sourceVehicle~=0 and NetworkGetNetworkIdFromEntity(sourceVehicle) or 0,
    paused=convoyPaused[src]==true,template=template~=0 and NetworkGetNetworkIdFromEntity(template) or 0})
end
local function removeUnit(unit)
  for id,e in pairs(unit.entities) do
    if NetworkGetEntityFromNetworkId(id)==e and DoesEntityExist(e) and GetEntityModel(e)==unit.models[id] then DeleteEntity(e) end
  end
end
local function clear(src)
  for _,unit in pairs(units[src] or {}) do removeUnit(unit) end
  requests[src],units[src],convoyPaused[src]=nil,nil,nil
  TriggerClientEvent('prfrp:ops:clearBackup',src)
end
PrfDismissBackup=clear
RegisterNetEvent('prfrp:ops:registerBackup',function(requestId,carId,pedIds)
  local src=source
  if not permitted(src) or type(carId)~='number' or carId<=0 or carId%1~=0
    or type(pedIds)~='table' or #pedIds~=Config.Backup.crewSize then return end
  local previous=units[src] and units[src][carId]
  if previous then
    if previous.request~=requestId or NetworkGetEntityFromNetworkId(carId)~=previous.car then return end
    for i,id in ipairs(pedIds) do if previous.pedIds[i]~=id or NetworkGetEntityFromNetworkId(id)~=previous.entities[id] then return end end
    TriggerClientEvent('prfrp:ops:backupRegistered',src,carId);return
  end
  local request=requests[src] and requests[src][requestId]
  if not request or request.remaining<=0 then return end
  local car=NetworkGetEntityFromNetworkId(carId)
  if car==0 or car==request.sourceVehicle or not DoesEntityExist(car) or GetEntityType(car)~=2
    or GetEntityModel(car)~=GetHashKey(request.model) or NetworkGetEntityOwner(car)~=src
    or not closeTo(src,car,250) then return end
  local entities,models={[carId]=car},{[carId]=GetEntityModel(car)}
  for index,id in ipairs(pedIds) do
    if type(id)~='number' or id<=0 or id%1~=0 or entities[id] then return end
    local ped=NetworkGetEntityFromNetworkId(id)
    if ped==0 or not DoesEntityExist(ped) or GetEntityType(ped)~=1 or human(ped) or GetEntityHealth(ped)<=0
      or NetworkGetEntityOwner(ped)~=src or GetVehiclePedIsIn(ped,false)~=car
      or GetPedInVehicleSeat(car,index-2)~=ped then return end
    local hash=GetEntityModel(ped)
    if hash~=GetHashKey(Config.PRFSkinModel) and hash~=GetHashKey('s_m_y_hwaycop_01') then return end
    entities[id],models[id]=ped,hash
  end
  units[src]=units[src] or {}
  units[src][carId]={entities=entities,models=models,car=car,pedIds=pedIds,request=requestId,mode=request.mode}
  request.remaining=request.remaining-1
  if request.remaining==0 then requests[src][requestId]=nil end
  TriggerClientEvent('prfrp:ops:backupRegistered',src,carId)
  if PrfCopomEvidence then PrfCopomEvidence(src,'backup',car) end
end)
RegisterNetEvent('prfrp:backup:formation',function(action)
  local src=source
  if not permitted(src) or (action~='hold' and action~='resume' and action~='end' and action~='dismount') then return end
  if action=='end' then
    for id,r in pairs(requests[src] or {}) do if r.mode=='convoy' then requests[src][id]=nil end end
    for id,u in pairs(units[src] or {}) do if u.mode=='convoy' then removeUnit(u);units[src][id]=nil end end
    convoyPaused[src]=nil
    TriggerClientEvent('prfrp:backup:convoyEnded',src)
    notify(src,'Comboio dispensado. Chamadas pendentes do comboio canceladas.');return
  end
  if action=='dismount' then
    if GetVehiclePedIsIn(GetPlayerPed(src),false)~=0 then notify(src,'Desembarque primeiro para solicitar apoio a pe.');return end
    for _,r in pairs(requests[src] or {}) do r.mode='support' end
    for _,u in pairs(units[src] or {}) do u.mode='support' end
  end
  convoyPaused[src]=action=='hold'
  TriggerClientEvent('prfrp:backup:formation',src,action)
  notify(src,action=='hold' and 'Comboio parado: equipes aguardam nas viaturas.' or
    action=='resume' and 'Comboio retomado. Assuma o volante da viatura.' or 'Equipes liberadas para apoio a pe.')
end)
AddEventHandler('prfrp:ops:dutyEnded',clear)
AddEventHandler('playerDropped',function() clear(source) end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for src in pairs(units) do clear(src) end
end)
