local function check(name,fn)
  local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name)
end
local root='fivem/resources/[prf]/prf_core/'
for _,name in ipairs({'config.lua','client.lua','base_client.lua','keys_client.lua',
  'squad_client.lua','server.lua','operations_config.lua','operations_client.lua','operations_server.lua',
  'people_client.lua','people_server.lua','commands_client.lua','commands_server.lua'}) do
  assert(loadfile(root..name))
end
local function spawnEnv(behavior)
  local events,threads,positions,frozen={},{},{},{}
  local now,current=0,1
  local env=setmetatable({
    RegisterNetEvent=function(n,fn) events[n]=fn end,
    AddEventHandler=function(n,fn) events[n]=fn end,
    RegisterCommand=function() end, RegisterKeyMapping=function() end,
    CreateThread=function(fn) threads[#threads+1]=fn end,
    GetResourceState=function() return behavior.missingMap and 'stopped' or 'started' end,
    PlayerPedId=function() return current end,
    DoesEntityExist=function() return true end,
    FreezeEntityPosition=function(ped,value) frozen[ped]=value end,
    RequestCollisionAtCoord=function() end,
    SetEntityCoordsNoOffset=function(ped,x,y,z) positions[ped]={x=x,y=y,z=z} end,
    SetEntityHeading=function() end,
    GetGameTimer=function() return now end,
    GetGroundZFor_3dCoord=function(x,y,z)
      return not behavior.missingGround,z-2.0
    end,
    HasCollisionLoadedAroundEntity=function() return true end,
    Wait=function()
      now=now+1000
      if behavior.onWait then behavior.onWait(function() current=2 end,events,threads) end
    end,
    TriggerEvent=function(n) events.arrived=n end,
    BeginTextCommandThefeedPost=function() end,
    AddTextComponentSubstringPlayerName=function() end,
    EndTextCommandThefeedPostTicker=function() end,
    print=function() end,
  },{__index=_G})
  assert(loadfile(root..'config.lua','t',env))()
  assert(loadfile(root..'client.lua','t',env))()
  return {env=env,events=events,threads=threads,positions=positions,frozen=frozen,
    spawn=function() events.playerSpawned();threads[#threads]() end}
end
check('joining and respawning place player at new base without granting police duty',function()
  local s=spawnEnv({});s.spawn()
  assert(s.positions[1].x==s.env.Config.SpawnBase.x and s.positions[1].y==s.env.Config.SpawnBase.y)
  assert(s.frozen[1]==false and s.events.arrived=='prfrp:baseArrival')
  s.spawn();assert(s.positions[1].x==s.env.Config.SpawnBase.x)
end)
check('stopped map or failed ground load returns to Sandy Shores',function()
  for _,behavior in ipairs({{missingMap=true},{missingGround=true}}) do
    local s=spawnEnv(behavior);s.spawn()
    assert(s.positions[1].x==s.env.Config.Base.x and s.frozen[1]==false)
  end
end)
check('ped change and duplicate spawn while streaming do not leave either ped frozen',function()
  local behavior={missingGround=true}
  behavior.onWait=function(change,events,threads)
    change();events.playerSpawned();threads[#threads]()
    behavior.missingGround=false;behavior.onWait=nil
  end
  local s=spawnEnv(behavior);s.spawn()
  assert(s.frozen[1]==false and s.frozen[2]==false)
  assert(s.positions[2].x==s.env.Config.SpawnBase.x)
end)

check('favela population never exceeds twelve and cleans up outside the region',function()
  local root='fivem/resources/[prf]/prf_favela_realista/'
  local callbacks,threads,entities={},{},{}
  local now,nextId=0,100
  local position={x=1180.15991,y=-125.015266,z=61.4836}
  local env=setmetatable({
    GetHashKey=function(n) return n end,
    AddRelationshipGroup=function() end,
    AddBlipForCoord=function() return 1 end,
    RegisterCommand=function() end,
    AddEventHandler=function(n,fn) callbacks[n]=fn end,
    exports=function() end,
    CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
    GetGameTimer=function() return now end,
    Wait=function(ms) now=now+ms;coroutine.yield() end,
    PlayerPedId=function() return 1 end,
    GetEntityCoords=function(id) return id==1 and position or entities[id].position end,
    DoesEntityExist=function(id) return id==1 or entities[id]~=nil end,
    IsEntityDead=function(id) return entities[id] and entities[id].dead or false end,
    GetPedRelationshipGroupHash=function() return 1 end,
    HasCollisionLoadedAroundEntity=function() return true end,
    IsModelInCdimage=function() return true end,
    IsModelAPed=function() return true end,
    HasModelLoaded=function() return true end,
    CreatePed=function(_,hash,x,y,z)
      nextId=nextId+1;entities[nextId]={position={x=x,y=y,z=z}};return nextId
    end,
    DeletePed=function(id) entities[id]=nil end,
    GetCurrentResourceName=function() return 'prf_favela_realista' end,
  },{__index=_G})
  for _,n in ipairs({'SetBlipSprite','SetBlipColour','SetBlipAsShortRange',
    'BeginTextCommandSetBlipName','AddTextComponentString','EndTextCommandSetBlipName',
    'SetRelationshipBetweenGroups','RequestModel','SetModelAsNoLongerNeeded',
    'RequestCollisionAtCoord','SetEntityAsMissionEntity','SetPedRelationshipGroupHash',
    'SetBlockingOfNonTemporaryEvents','SetPedFleeAttributes','SetPedDropsWeaponsWhenDead',
    'SetPedAccuracy','SetPedCombatAbility','SetPedArmour','GiveWeaponToPed',
    'SetCurrentPedWeapon','TaskStandStill','ClearPedTasks','RemoveBlip'}) do env[n]=function() end end
  assert(loadfile(root..'gang_points.lua','t',env))()
  assert(loadfile(root..'gangs_client.lua','t',env))()
  local function count() local n=0;for _ in pairs(entities) do n=n+1 end;return n end
  local function tick() local ok,err=coroutine.resume(threads[1]);assert(ok,err);assert(count()<=12) end
  tick();assert(count()<=2)
  for i=1,12 do tick() end
  assert(count()==12)
  local first=next(entities);entities[first].dead=true
  for i=1,18 do tick() end
  assert(not entities[first])
  position={x=-3000,y=300,z=14};tick();assert(count()==0)
  position={x=1180.15991,y=-125.015266,z=61.4836};tick();assert(count()<=2)
  callbacks.onResourceStop('prf_favela_realista');assert(count()==0)
  tick();assert(coroutine.status(threads[1])=='dead')
end)
print('PRF spawn and population behavior passed')
