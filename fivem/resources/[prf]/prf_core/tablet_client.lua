local opened,prop,ped,epoch=false,0,0,0
local duty=false
local dict,clip='amb@code_human_in_bus_passenger_idles@female@tablet@base','base'
local latest={stats={},items={},arrests={}}
local function close()
  epoch=epoch+1;opened=false
  SetNuiFocus(false,false);SendNUIMessage({action='close'})
  if prop~=0 and DoesEntityExist(prop) then DeleteObject(prop) end
  if ped~=0 and DoesEntityExist(ped) then StopAnimTask(ped,dict,clip,2.0) end
  prop,ped=0,0
end
local function open(tab,lines)
  if not duty then TriggerEvent('prfrp:chatNotice','Digite servico no T primeiro.');return end
  close();opened=true
  local token=epoch
  SendNUIMessage({action='open',tab=tab or 'documents',lines=lines or {},profile=latest})
  SetNuiFocus(true,true)
  TriggerServerEvent('prfrp:progress:request','profile')
  CreateThread(function()
    ped=PlayerPedId()
    if IsPedInAnyVehicle(ped,false) then return end
    local hash=GetHashKey('prop_cs_tablet')
    RequestModel(hash);RequestAnimDict(dict)
    local started=GetGameTimer()
    while opened and epoch==token and (not HasModelLoaded(hash) or not HasAnimDictLoaded(dict))
      and GetGameTimer()-started<4000 do Wait(0) end
    if not opened or epoch~=token or not HasModelLoaded(hash) then SetModelAsNoLongerNeeded(hash);return end
    local p=GetEntityCoords(ped)
    prop=CreateObject(hash,p.x,p.y,p.z,false,false,false)
    SetModelAsNoLongerNeeded(hash)
    if prop~=0 then
      AttachEntityToEntity(prop,ped,GetPedBoneIndex(ped,60309),0.03,0.002,-0.023,10.0,160.0,0.0,true,true,false,true,1,true)
    end
    if HasAnimDictLoaded(dict) then TaskPlayAnim(ped,dict,clip,3.0,3.0,-1,49,0,false,false,false) end
  end)
end
AddEventHandler('prfrp:tablet:document',function(lines) open('documents',lines) end)
RegisterNetEvent('prfrp:tablet:vehicleDocument',function(lines) open('documents',lines) end)
AddEventHandler('prfrp:tablet:open',function(tab) open(tab or 'documents') end)
RegisterNetEvent('prfrp:tablet:profile',function(value,tab)
  if not duty then return end
  latest=value
  if tab=='inventory' or tab=='progress' then open(tab)
  elseif opened then SendNUIMessage({action='profile',profile=value}) end
end)
RegisterNetEvent('prfrp:progress:updated',function(value)
  latest=value
  if opened then SendNUIMessage({action='profile',profile=value}) end
end)
RegisterNUICallback('close',function(_,reply) close();reply({ok=true}) end)
RegisterNUICallback('save',function(_,reply) TriggerServerEvent('prfrp:progress:request','save');reply({ok=true}) end)
RegisterNUICallback('service',function(data,reply)
  if type(data)=='table' and Config.Services[data.name] then TriggerEvent('prfrp:services:request',data.name) end
  reply({ok=true})
end)
AddEventHandler('prfrp:notify',function(text) if opened then SendNUIMessage({action='notice',text=tostring(text)}) end end)
RegisterNetEvent('prfrp:setDuty',function(enabled) duty=enabled==true;if not duty then close() end end)
AddEventHandler('prfrp:baseArrival',close)
CreateThread(function()
  while true do
    if opened and (IsEntityDead(PlayerPedId()) or PlayerPedId()~=ped and ped~=0) then close() end
    Wait(300)
  end
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then close() end end)
