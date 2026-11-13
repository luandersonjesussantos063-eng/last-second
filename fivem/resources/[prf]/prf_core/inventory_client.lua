local removed={}
local function npc(id)
  local ped=NetworkGetEntityFromNetworkId(id)
  if ped~=0 and DoesEntityExist(ped) and not IsPedAPlayer(ped) and NetworkHasControlOfEntity(ped) then return ped end
end
RegisterNetEvent('prfrp:inventory:inspect',function(id,token)
  local ped=npc(id)
  if not ped then return end
  local items={}
  for name in pairs(Config.SearchWeapons) do
    local hash=GetHashKey(name)
    if HasPedGotWeapon(ped,hash,false) then
      items[#items+1]={name=name,ammo=math.max(0,math.min(3000,GetAmmoInPedWeapon(ped,hash)))}
    end
  end
  TriggerServerEvent('prfrp:inventory:inspection',id,token,items)
end)
RegisterNetEvent('prfrp:inventory:seize',function(id,token,items)
  local ped=npc(id)
  if not ped then return end
  if not removed[token] then
    local actual={}
    for _,item in ipairs(items) do
      local hash=GetHashKey(item.name)
      if Config.SearchWeapons[item.name] and HasPedGotWeapon(ped,hash,false) then
        actual[#actual+1]={name=item.name,ammo=math.max(0,math.min(item.ammo,GetAmmoInPedWeapon(ped,hash)))}
      end
    end
    for _,item in ipairs(actual) do
      local hash=GetHashKey(item.name)
      SetPedAmmo(ped,hash,0);RemoveWeaponFromPed(ped,hash)
    end
    removed[token]={id=id,items=actual,expires=GetGameTimer()+60000}
  end
  TriggerServerEvent('prfrp:inventory:removed',id,token,removed[token].items)
end)
RegisterNetEvent('prfrp:inventory:restore',function(id,token)
  local value=removed[token]
  if not value or value.restored or value.finished then return end
  local ped=npc(id)
  if not ped then return end
  value.restored=true
  local pools={}
  for _,item in ipairs(value.items) do
    local kind=Config.SearchWeapons[item.name].ammo or item.name
    GiveWeaponToPed(ped,GetHashKey(item.name),pools[kind] and 0 or item.ammo,false,false)
    pools[kind]=true
  end
end)
RegisterNetEvent('prfrp:inventory:finished',function(token) if removed[token] then removed[token].finished=true end end)
CreateThread(function()
  while true do
    Wait(5000)
    for token,value in pairs(removed) do if GetGameTimer()>value.expires then removed[token]=nil end end
  end
end)
