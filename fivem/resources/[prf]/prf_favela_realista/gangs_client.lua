-- Populacao local do mapa: ate 12 NPCs, sem recriar os 64 do Map Editor de uma vez.
local active, running = {}, true
local group = GetHashKey('PRF_FAVELA_AMBIENT')
local models = { 'g_m_y_ballaeast_01', 'g_m_y_famca_01', 'g_m_y_mexgoon_02' }
local hostileUntil = 0
AddRelationshipGroup('PRF_FAVELA_AMBIENT')
local favelaBlip = AddBlipForCoord(1180.15991,-125.015266,61.4836)
SetBlipSprite(favelaBlip,84)
SetBlipColour(favelaBlip,1)
SetBlipAsShortRange(favelaBlip,false)
BeginTextCommandSetBlipName('STRING')
AddTextComponentString('Favela Realista')
EndTextCommandSetBlipName(favelaBlip)
RegisterCommand('prffavela',function()
  SetNewWaypoint(1180.15991,-125.015266)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName('Favela Realista marcada no GPS.')
  EndTextCommandThefeedPostTicker(false,false)
end,false)

local function distance(a,b)
  return (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2
end
local function remove(slot)
  if slot.ped and DoesEntityExist(slot.ped) then
    SetEntityAsMissionEntity(slot.ped,true,true)
    DeletePed(slot.ped)
  end
  slot.ped = nil
end
local function load(name)
  local hash=GetHashKey(name)
  if not IsModelInCdimage(hash) or not IsModelAPed(hash) then return nil end
  RequestModel(hash)
  local start=GetGameTimer()
  while running and not HasModelLoaded(hash) and GetGameTimer()-start<2500 do Wait(0) end
  if running and HasModelLoaded(hash) then return hash end
  SetModelAsNoLongerNeeded(hash)
end
local function detained(ped)
  if GetResourceState('prf_core')~='started' then return false end
  local ok,value=pcall(function() return exports.prf_core:IsPersonStopped(ped) end)
  return ok and value==true
end
local function police()
  if GetResourceState('prf_core')~='started' then return false end
  local ok,value=pcall(function() return exports.prf_core:IsOnDuty() end)
  return ok and value==true
end
local function patrol(slot,index)
  local p=FavelaPoints[index]
  TaskWanderInArea(slot.ped,p.x,p.y,p.z,12.0,2.0,4.0)
  slot.mode,slot.nextTask='patrol',GetGameTimer()+20000
end
local function react(slot,index)
  local ped,player=slot.ped,PlayerPedId()
  if detained(ped) or (NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped)) then return end
  local now=GetGameTimer()
  local armed=IsPedArmed(ped,4)
  if index%4==0 or not armed then
    if slot.mode~='flee' or now>(slot.nextTask or 0) then
      TaskSmartFleePed(ped,player,90.0,15000,false,false);slot.mode,slot.nextTask='flee',now+12000
    end
  elseif slot.mode~='combat' or (not IsPedInCombat(ped,player) and now>(slot.nextTask or 0)) then
    TaskCombatPed(ped,player,0,16);slot.mode,slot.nextTask='combat',now+6000
  end
end
local function calm()
  SetRelationshipBetweenGroups(3,group,GetPedRelationshipGroupHash(PlayerPedId()))
  hostileUntil=0
  for index,slot in pairs(active) do
    if slot.ped and DoesEntityExist(slot.ped) and not IsEntityDead(slot.ped) and not detained(slot.ped) then
      ClearPedTasks(slot.ped);patrol(slot,index)
    end
  end
end
local function spawn(index)
  local point=FavelaPoints[index]
  local hash=load(models[(index-1)%#models+1])
  if not hash then return end
  if distance(GetEntityCoords(PlayerPedId()),point)>120^2 then SetModelAsNoLongerNeeded(hash); return end
  RequestCollisionAtCoord(point.x,point.y,point.z)
  local ped=CreatePed(4,hash,point.x,point.y,point.z,point.heading,false,true)
  SetModelAsNoLongerNeeded(hash)
  if ped==0 or not DoesEntityExist(ped) then return end
  SetEntityAsMissionEntity(ped,true,true)
  SetPedRelationshipGroupHash(ped,group)
  SetBlockingOfNonTemporaryEvents(ped,true)
  SetPedFleeAttributes(ped,0,false)
  SetPedDropsWeaponsWhenDead(ped,false)
  SetPedAccuracy(ped,15)
  SetPedCombatAbility(ped,1)
  SetPedArmour(ped,20)
  local weapon=GetHashKey(index%4==0 and 'WEAPON_MICROSMG' or 'WEAPON_PISTOL')
  GiveWeaponToPed(ped,weapon,120,false,true)
  SetCurrentPedWeapon(ped,weapon,true)
  SetPedCombatMovement(ped,2);SetPedCombatRange(ped,1);SetPedCombatAttributes(ped,46,true)
  active[index]={ped=ped}
  patrol(active[index],index)
end

AddEventHandler('entityDamaged',function(victim,culprit)
  if not running or culprit~=PlayerPedId() then return end
  local member=false
  for index,slot in pairs(active) do
    if slot.ped and DoesEntityExist(slot.ped) and not IsEntityDead(slot.ped)
      and #(GetEntityCoords(slot.ped)-GetEntityCoords(PlayerPedId()))<70 then react(slot,index) end
  end
end)

exports('GetEncounterPoints',function(origin,count)
  local candidates={}
  for i,point in ipairs(FavelaPoints) do
    if not (active[i] and active[i].ped) and distance(point,origin)<35^2 then
      candidates[#candidates+1]={point=point,d=distance(point,origin)}
    end
  end
  table.sort(candidates,function(a,b) return a.d<b.d end)
  local points={}
  for i=1,math.min(count or 3,#candidates) do points[#points+1]=candidates[i].point end
  return points
end)

CreateThread(function()
  calm()
  while running do
    local player=PlayerPedId()
    local position=GetEntityCoords(player)
    local now=GetGameTimer()
    if hostileUntil>0 and (now>hostileUntil or IsEntityDead(player)) then calm() end
    local count=0
    for index,slot in pairs(active) do
      if slot.ped then
        if not DoesEntityExist(slot.ped) or (distance(position,FavelaPoints[index])>180^2 and not detained(slot.ped)) then
          remove(slot)
        elseif IsEntityDead(slot.ped) then
          slot.deadAt=slot.deadAt or now
          if now-slot.deadAt>20000 then remove(slot); slot.readyAt=now+90000 end
        elseif not detained(slot.ped) then
          local d=distance(position,GetEntityCoords(slot.ped))
          local sees=d<65^2 and HasEntityClearLosToEntity(slot.ped,player,17)
          local threat=sees and not IsEntityDead(player) and
            (IsPedShooting(player) or (IsPedArmed(player,4) and d<45^2) or (police() and d<28^2))
          if threat then
            slot.alertAt=slot.alertAt or now
            if IsPedShooting(player) or now-slot.alertAt>2500 then
              hostileUntil=now+45000
              SetRelationshipBetweenGroups(5,group,GetPedRelationshipGroupHash(player))
            end
          else slot.alertAt=nil end
          if sees and hostileUntil>now then react(slot,index)
          elseif now>(slot.nextTask or 0) then patrol(slot,index) end
        end
      end
      if slot.ped then count=count+1 end
    end
    if not IsEntityDead(player) and HasCollisionLoadedAroundEntity(player) and count<12 then
      local candidates={}
      for index,point in ipairs(FavelaPoints) do
        local slot=active[index]
        local d=distance(position,point)
        if d<120^2 and not (slot and slot.ped) and not (slot and slot.readyAt and now<slot.readyAt) then
          candidates[#candidates+1]={index=index,d=d}
        end
      end
      table.sort(candidates,function(a,b) return a.d<b.d end)
      -- Adiciona no maximo dois por ciclo; evita pico ao entrar no mapa.
      for i=1,math.min(2,12-count,#candidates) do spawn(candidates[i].index) end
    end
    Wait(1500)
  end
end)

AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  running=false
  if favelaBlip then RemoveBlip(favelaBlip) end
  calm()
  for _,slot in pairs(active) do remove(slot) end
  active={}
end)
