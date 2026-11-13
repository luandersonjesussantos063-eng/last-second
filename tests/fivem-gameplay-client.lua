local root='fivem/resources/[prf]/prf_core/'
local function file(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local mt={}
local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__sub=function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__len=function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
local function host()
  local events,threads,network,tasks={}, {}, {}, {}
  local now,serial=0,100
  local entities={[1]={p=vec(0,0,1),health=100,model='officer'},[20]={p=vec(2,0,1),model='police'}}
  local env=setmetatable({
    RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) local old=events[n];events[n]=function(...) if old then old(...) end;fn(...) end end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,
    Wait=function(ms) coroutine.yield(ms) end,GetGameTimer=function() return now end,
    TriggerEvent=function(n,...) if events[n] then events[n](...) end end,
    TriggerServerEvent=function(n,...) network[#network+1]={name=n,args={...}} end,
    GetHashKey=function(n) return n end,GetCurrentResourceName=function() return 'prf_core' end,
    PlayerId=function() return 1 end,PlayerPedId=function() return 1 end,
    GetEntityCoords=function(id) return entities[id].p end,GetEntityHeading=function() return 0 end,
    DoesEntityExist=function(id) return entities[id]~=nil end,IsEntityDead=function() return false end,
    IsPedInAnyVehicle=function() return false end,GetVehiclePedIsIn=function() return 0 end,
    GetSelectedPedWeapon=function() return 'WEAPON_CARBINERIFLE' end,HasPedGotWeapon=function() return true end,
    SetCurrentPedWeapon=function(_,name) tasks.weapon=name end,
    RequestModel=function() end,HasModelLoaded=function() return true end,SetModelAsNoLongerNeeded=function() end,
    GetPedBoneIndex=function() return 1 end,
    CreateObject=function(model,x,y,z) serial=serial+1;entities[serial]={p=vec(x,y,z),model=model};return serial end,
    CreateObjectNoOffset=function(model,x,y,z) serial=serial+1;entities[serial]={p=vec(x,y,z),model=model};return serial end,
    DeleteObject=function(id) entities[id]=nil end,
    DeleteEntity=function(id) entities[id]=nil end,
    SetEntityCoordsNoOffset=function(id,x,y,z) entities[id].p=vec(x,y,z) end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    GetGameplayCamCoord=function() return vec(0,0,2) end,GetGameplayCamRot=function() return vec(-45,0,0) end,
    StartShapeTestRay=function() return 1 end,GetShapeTestResult=function() return 2,true,vec(0,3,0),vec(0,0,1) end,
    PrfIsAimHeld=function() return true end,IsNuiFocused=function() return false end,
    IsDisabledControlPressed=function() return false end,IsDisabledControlJustPressed=function() return true end,
    GetGamePool=function() return {} end,
    TaskGoStraightToCoord=function(id) tasks[id]='position' end,TaskGuardCurrentPosition=function(id) tasks[id]='guard' end,
    TaskStartScenarioInPlace=function(id,scenario) tasks[id]=scenario end,
    TaskGoToEntity=function(id,target) tasks[id]='inspect';entities[id].p=entities[target].p end,
    TaskTurnPedToFaceEntity=function(id) tasks[id]='face' end,
  },{__index=_G})
  for _,n in ipairs({'AttachEntityToEntity','SetEntityCollision','SetEntityAlpha','FreezeEntityPosition','SetEntityVisible',
    'DrawMarker','DisablePlayerFiring','DisableControlAction','PlaceObjectOnGroundProperly','SetEntityAsMissionEntity'}) do env[n]=function() end end
  file('config.lua',env);file('operations_config.lua',env);file('gameplay_config.lua',env)
  local function step(ms)
    now=now+(ms or 100)
    for i=1,#threads do local t=threads[i];if coroutine.status(t.co)~='dead' and now>=t.due then local ok,wait=coroutine.resume(t.co);assert(ok,wait);t.due=now+math.max(1,wait or 1) end end
  end
  return {env=env,events=events,threads=threads,entities=entities,network=network,tasks=tasks,step=step,
    last=function(n) for i=#network,1,-1 do if network[i].name==n then return network[i] end end end}
end
check('aimed cone placement rejects walls, accepts ground, positions squad roles and cleans all props',function()
  local h=host();file('blitz_client.lua',h.env);h.events['prfrp:setDuty'](true);h.events['prfrp:blitz:toggle']()
  h.env.GetShapeTestResult=function() return 2,true,vec(0,3,0),vec(1,0,0) end;h.step();assert(not h.last('prfrp:blitz:place'))
  h.env.GetShapeTestResult=function() return 2,true,vec(0,3,0),vec(0,0,1) end;h.step()
  local point=h.last('prfrp:blitz:place').args[1];assert(point.y==3 and point.z==0)
  h.events['prfrp:blitz:authorized'](7,point);h.step()
  local object=h.last('prfrp:blitz:spawned').args[2];h.events['prfrp:blitz:registered'](7);h.step(300)
  assert(h.env.PrfGetBlitzAnchor().y==3)
  for i=2,4 do h.entities[i]={p=vec(0,3,0)} end
  h.env.PrfGetInspectedVehicle=function() return 20 end
  assert(h.env.PrfAssignBlitzRole(2,1,1));assert(h.tasks[2]=='WORLD_HUMAN_CAR_PARK_ATTENDANT')
  assert(h.env.PrfAssignBlitzRole(3,2,1));assert(h.tasks[3]=='guard')
  assert(h.env.PrfAssignBlitzRole(4,3,1));assert(h.tasks[4]=='inspect')
  h.events['prfrp:blitz:cancel']();assert(h.entities[object],'canceling aim preserves placed cones')
  assert(h.tasks.weapon=='WEAPON_CARBINERIFLE')
  h.events['prfrp:blitz:clear']();assert(not h.entities[object] and not h.env.PrfGetBlitzAnchor())
end)
check('late cone authorization after leaving duty never creates an object',function()
  local h=host();file('blitz_client.lua',h.env);h.events['prfrp:setDuty'](true);h.events['prfrp:blitz:toggle']();h.step()
  h.events['prfrp:setDuty'](false);h.events['prfrp:blitz:authorized'](7,{x=0,y=2,z=0});h.step()
  for id in pairs(h.entities) do assert(id<=20) end
end)
check('service actors drive to the target and carry out healing, vehicle repair or firefighting',function()
  for _,kind in ipairs({'ambulance','mechanic','fire'}) do
    local h=host();local e=h.env;local repaired,fire=false,true
    e.GetClosestVehicleNodeWithHeading=function() return true,vec(10,0,1),0 end
    e.IsAnyVehicleNearPoint=function() return false end
    e.CreateVehicle=e.CreateObject;e.CreatePed=function(_,model,x,y,z) return e.CreateObject(model,x,y,z) end
    e.PrfGetPatrolVehicle=function() return 20 end;e.GetPedRelationshipGroupHash=function() return 1 end
    e.TaskVehicleDriveToCoordLongrange=function() end
    e.NetworkHasControlOfEntity=function() return true end
    e.GetEntityMaxHealth=function() return 200 end;e.SetEntityHealth=function(id,value) h.entities[id].health=value end
    e.SetVehicleFixed=function() repaired=true end;e.SetVehicleDeformationFixed=function() end
    e.GetVehicleEngineHealth=function() return 100 end;e.SetVehicleEngineHealth=function(_,health) h.tasks.engine=health end
    e.StopEntityFire=function() fire=false end
    for _,n in ipairs({'RequestCollisionAtCoord','SetVehicleOnGroundProperly','SetPedIntoVehicle','SetBlockingOfNonTemporaryEvents',
      'SetPedRelationshipGroupHash','TaskVehicleTempAction','TaskLeaveVehicle','ClearPedBloodDamage'}) do e[n]=function() end end
    local old=e.TriggerServerEvent
    e.TriggerServerEvent=function(n,...)
      old(n,...)
      if n=='prfrp:services:spawned' then local args={...};h.events['prfrp:services:registered'](args[1],args[2]) end
    end
    file('services_client.lua',e);h.events['prfrp:setDuty'](true)
    h.events['prfrp:services:dispatch'](kind,7,kind=='ambulance' and 0 or 20)
    h.step();h.step(300);h.step(1800);h.step(300)
    assert(h.last('prfrp:services:arrived'))
    h.events['prfrp:services:perform'](kind,7,kind=='ambulance' and 0 or 20);h.step();h.step(3000)
    assert(h.last('prfrp:services:finished').args[3]==true)
    if kind=='ambulance' then assert(h.entities[1].health==200) elseif kind=='mechanic' then assert(repaired and h.tasks.engine==1000) else assert(not fire and h.tasks.engine==500) end
    h.events['prfrp:services:clear'](kind)
    for id in pairs(h.entities) do assert(id<=20,'no leaked service actors') end
  end
end)
check('tablet Escape callback removes only its own prop and cancels late model loads',function()
  local h=host();local e=h.env;local nui,messages,focus={}, {},false
  e.RegisterNUICallback=function(n,fn) nui[n]=fn end;e.SendNUIMessage=function(message) messages[#messages+1]=message end
  e.SetNuiFocus=function(value) focus=value end;e.RequestAnimDict=function() end;e.HasAnimDictLoaded=function() return true end
  e.TaskPlayAnim=function() end;e.StopAnimTask=function() end
  file('tablet_client.lua',e);h.events['prfrp:setDuty'](true)
  h.events['prfrp:tablet:document']({'DOCUMENTO FICTICIO'});h.step();assert(focus)
  local replied=false;nui.close({},function() replied=true end);assert(replied and not focus and messages[#messages].action=='close')
  e.HasModelLoaded=function() return false end
  h.events['prfrp:tablet:document']({'DOCUMENTO FICTICIO'});h.step();nui.close({},function() end);h.step()
  for id in pairs(h.entities) do assert(id<=20,'closed tablet has no leaked prop') end
end)
check('favela members patrol, shoot or flee, and never override or delete a detained suspect',function()
  local h=host();local e=h.env;local detained={}
  e.FavelaPoints={{x=2,y=0,z=1,heading=0},{x=3,y=0,z=1,heading=0},{x=4,y=0,z=1,heading=0},{x=5,y=0,z=1,heading=0}}
  e.AddBlipForCoord=function() return 1 end;e.RegisterCommand=function() end
  e.GetResourceState=function() return 'started' end;e.GetCurrentResourceName=function() return 'prf_favela_realista' end
  e.exports=setmetatable({prf_core={IsPersonStopped=function(_,ped) return detained[ped]==true end,IsOnDuty=function() return true end}},{__call=function() end})
  e.IsModelInCdimage=function() return true end;e.IsModelAPed=function() return true end
  e.HasCollisionLoadedAroundEntity=function() return true end;e.NetworkGetEntityIsNetworked=function() return false end
  e.GetPedRelationshipGroupHash=function() return 1 end;e.IsPedArmed=function() return true end
  e.HasEntityClearLosToEntity=function() return true end;e.IsPedShooting=function() return false end;e.IsPedInCombat=function() return true end
  e.CreatePed=function(_,model,x,y,z) return e.CreateObject(model,x,y,z) end;e.DeletePed=e.DeleteObject
  e.TaskWanderInArea=function(id) h.tasks[id]='patrol' end;e.TaskCombatPed=function(id) h.tasks[id]='combat' end
  e.TaskSmartFleePed=function(id) h.tasks[id]='flee' end
  for _,n in ipairs({'AddRelationshipGroup','SetBlipSprite','SetBlipColour','SetBlipAsShortRange','BeginTextCommandSetBlipName','AddTextComponentString','EndTextCommandSetBlipName',
    'SetRelationshipBetweenGroups','RequestCollisionAtCoord','SetPedRelationshipGroupHash','SetBlockingOfNonTemporaryEvents','SetPedFleeAttributes','SetPedDropsWeaponsWhenDead',
    'SetPedAccuracy','SetPedCombatAbility','SetPedArmour','GiveWeaponToPed','SetPedCombatMovement','SetPedCombatRange','SetPedCombatAttributes','ClearPedTasks','RemoveBlip'}) do e[n]=function() end end
  assert(loadfile('fivem/resources/[prf]/prf_favela_realista/gangs_client.lua','t',e))()
  h.step(1500);assert(h.tasks[101]=='patrol')
  h.step(1500);h.step(1500);h.step(1500)
  assert(h.tasks[101]=='combat' and h.tasks[104]=='flee')
  detained[101]=true;h.tasks[101]='cuffed';h.step(1500);assert(h.tasks[101]=='cuffed')
  h.entities[1].p=vec(1000,0,1);h.step(1500);assert(h.entities[101] and not h.entities[104],'transport must preserve the prisoner')
  h.events.onResourceStop('prf_favela_realista');assert(not h.entities[101])
end)
print('PRF gameplay client behavior passed')
