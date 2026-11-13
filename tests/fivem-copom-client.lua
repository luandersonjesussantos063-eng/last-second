local root='fivem/resources/[prf]/prf_core/'
local function file(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local mt={};local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__sub=function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__len=function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
local function setup()
  local handlers,threads,requests,tasks={}, {}, {}, {}
  local now,nextId=0,100
  local entities={[1]={p=vec(1183.9,2660.7,38.02),health=200,model='officer'}}
  local hold,collision=true,true
  local env=setmetatable({
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,
    AddEventHandler=function(n,fn) local old=handlers[n];handlers[n]=function(...) if old then old(...) end;fn(...) end end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,
    Wait=function(ms) coroutine.yield(ms) end,GetGameTimer=function() return now end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    TriggerServerEvent=function(n,...)
      requests[#requests+1]={name=n,args={...}}
      local args={...}
      if n=='prfrp:copom:register' then handlers['prfrp:copom:registered'](args[1]) end
      if n=='prfrp:copom:workStart' then handlers['prfrp:copom:workBegin'](args[1],args[2],4,'talk') end
    end,
    PlayerPedId=function() return 1 end,PlayerId=function() return 1 end,
    GetHashKey=function(n) return n end,IsModelInCdimage=function() return true end,
    RequestModel=function() end,HasModelLoaded=function() return true end,SetModelAsNoLongerNeeded=function() end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityCoords=function(id) return entities[id].p end,GetEntityHeading=function() return 0 end,
    GetClosestVehicleNodeWithHeading=function(x,y,z) return true,vec(x,y,z),0 end,
    RequestCollisionAtCoord=function() end,GetGroundZFor_3dCoord=function(x,y,z) return collision,z-4 end,
    GetSafeCoordForPed=function(x,y,z) return true,vec(x,y,z) end,
    IsAnyVehicleNearPoint=function() return false end,
    IsEntityDead=function(id) return entities[id] and entities[id].health<=0 or false end,
    NetworkHasControlOfEntity=function() return true end,IsPedInCombat=function() return false end,
    IsNuiFocused=function() return false end,IsPedInAnyVehicle=function() return false end,
    IsControlPressed=function() return hold end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    AddBlipForCoord=function() return 1 end,AddBlipForEntity=function() return 2 end,
    CreateVehicle=function(model,x,y,z) nextId=nextId+1;entities[nextId]={p=vec(x,y,z),model=model,kind=2,health=1000};return nextId end,
    CreatePed=function(_,model,x,y,z) nextId=nextId+1;entities[nextId]={p=vec(x,y,z),model=model,kind=1,health=200};return nextId end,
    CreateObjectNoOffset=function(model,x,y,z) nextId=nextId+1;entities[nextId]={p=vec(x,y,z),model=model,kind=3,health=1000};return nextId end,
    DeleteEntity=function(id) entities[id]=nil end,
    SetPedIntoVehicle=function(id,car) entities[id].car=car end,
    SetEntityHealth=function(id,n) entities[id].health=n end,
    GiveWeaponToPed=function(id,name) entities[id].weapon=name end,
    StartEntityFire=function(id) entities[id].fire=true end,
    TaskVehicleDriveWander=function(id) tasks[id]='drive' end,TaskWanderInArea=function(id) tasks[id]='wander' end,
    TaskCombatPed=function(id) tasks[id]='combat' end,
    ClearPedTasks=function(id) tasks[id]='clear' end,
    TaskPlayAnim=function(id) tasks[id]='injured' end,
    TaskStartScenarioInPlace=function(id) tasks[id]='scenario' end,
    RequestAnimDict=function() end,HasAnimDictLoaded=function() return true end,
    GetCurrentResourceName=function() return 'prf_core' end,
    vector3=vec,
  },{__index=_G})
  for _,n in ipairs({'StopEntityFire','SetEntityAsMissionEntity','SetVehicleOnGroundProperly','SetVehicleNumberPlateText','SetVehicleEngineHealth','SetVehicleBodyHealth',
    'SetVehicleUndriveable','SetVehicleEngineOn','SetVehicleDoorOpen','PlaceObjectOnGroundProperly','FreezeEntityPosition','SetBlockingOfNonTemporaryEvents',
    'SetPedDropsWeaponsWhenDead','SetEntityInvincible','SetPedCanRagdoll','RemoveBlip','SetBlipSprite','SetBlipColour','SetBlipRoute','BeginTextCommandSetBlipName',
    'AddTextComponentString','EndTextCommandSetBlipName','SetNewWaypoint','SetPedCombatAbility','SetPedCombatMovement','SetPedCombatRange','SetPedAccuracy',
    'SetPedFleeAttributes','BeginTextCommandDisplayHelp','AddTextComponentSubstringPlayerName','EndTextCommandDisplayHelp','DrawMarker','TaskTurnPedToFaceEntity','DisablePlayerFiring'}) do env[n]=function() end end
  for _,name in ipairs({'config.lua','operations_config.lua','gameplay_config.lua','copom_config.lua','copom_client.lua'}) do file(name,env) end
  handlers['prfrp:setDuty'](true)
  local h={env=env,handlers=handlers,entities=entities,tasks=tasks,requests=requests}
  h.step=function(ms)
    now=now+(ms or 100)
    for i=1,#threads do local t=threads[i];if coroutine.status(t.co)~='dead' and t.due<=now then local ok,wait=coroutine.resume(t.co);assert(ok,wait);t.due=now+math.max(1,wait or 1) end end
  end
  h.last=function(name) for i=#requests,1,-1 do if requests[i].name==name then return requests[i] end end end
  h.dispatch=function(index,variant)
    local c={session=1,definition=env.PrfBuildCopom(env.Config.Copom.templates[index],variant or 1),location=env.Config.Copom.locations[1]}
    handlers['prfrp:copom:call'](c)
    for i=1,5 do h.step(800) end
    return c
  end
  h.hold=function(value) hold=value end
  h.collision=function(value) collision=value end
  return h
end
check('all twenty variants spawn the actual vehicles, people and objects before registration',function()
  for index=1,10 do for variant=1,2 do
    local h=setup();h.hold(false);local c=h.dispatch(index,variant)
    local registration=h.last('prfrp:copom:register');assert(registration,c.definition.key)
    local ids=registration.args[3];local n=0
    for _,def in ipairs(c.definition.actors) do
      local e=h.entities[ids[def.key]];assert(e and e.model==def.model);n=n+1
      if def.injured then assert(e.health==135 and h.tasks[ids[def.key]]=='injured') end
      if def.weapon then assert(e.weapon==def.weapon) end
      if def.fire then assert(e.fire==true) end
      if def.driver then assert(h.tasks[ids[def.key]]=='drive' and e.car==ids[def.driver]) end
    end
    assert(n==#c.definition.actors and n>=1)
    for _,request in ipairs(h.requests) do assert(request.name~='prfrp:completeCall' and request.name~='prfrp:advanceCall') end
    h.handlers['prfrp:copom:call'](false);for id in pairs(h.entities) do assert(id==1,'scene props leaked') end
  end end
end)
check('lack of ground never creates a floating scene or reports completion',function()
  local h=setup();h.collision(false);h.dispatch(2,1)
  for i=1,8 do h.step(1000) end
  assert(h.last('prfrp:copom:spawnFailed') and not h.last('prfrp:copom:register'))
  for id in pairs(h.entities) do assert(id==1) end
end)
check('holding E performs a timed action and releasing it cancels instead of advancing the call',function()
  local h=setup();h.hold(false);h.dispatch(1,1)
  local ids=h.last('prfrp:copom:register').args[3];h.entities[1].p=h.entities[ids.motorista].p
  h.hold(true);h.step(800);h.step(800)
  h.hold(false);h.step(1000)
  assert(h.last('prfrp:copom:workCancel') and not h.last('prfrp:copom:workFinish'))
end)
check('T conversar uses the nearby witness and takes time; scene cancellation invalidates late work',function()
  local h=setup();h.hold(false);h.dispatch(1,1)
  local ids=h.last('prfrp:copom:register').args[3];h.entities[1].p=h.entities[ids.motorista].p
  h.handlers['prfrp:copom:command']('copomTalk');h.step(1000);h.step(800)
  assert(not h.last('prfrp:copom:workFinish'))
  h.step(4100);assert(h.last('prfrp:copom:workFinish').args[2]=='talk_motorista')
  h.step(1500);h.handlers['prfrp:copom:command']('copomTalk');h.step(800)
  local before=#h.requests;h.handlers['prfrp:copom:call'](false);h.step(5000)
  assert(#h.requests==before,'late callback cannot touch a later scene')
end)
check('support targets the actual victims and damaged mission vehicle instead of the officer patrol car',function()
  local h=setup();h.hold(false);h.dispatch(2,2)
  local ids=h.last('prfrp:copom:register').args[3]
  h.entities[1].p=h.entities[ids.vitima].p
  assert(h.env.PrfGetCopomServiceTarget('ambulance')==ids.vitima)
  h.handlers['prfrp:copom:progress'](1,{{key='medic_vitima',done=true}})
  assert(h.env.PrfGetCopomServiceTarget('ambulance')==ids.vitima2)
  h.entities[1].p=h.entities[ids.carro1].p;assert(h.env.PrfGetCopomServiceTarget('tow')==ids.carro1)
end)
check('scene cleanup preserves a detained NPC and combat never overrides surrender',function()
  local h=setup();h.hold(false);h.dispatch(6,1)
  local ids=h.last('prfrp:copom:register').args[3];local target=ids.agressor1
  h.entities[1].p=h.entities[target].p;h.env.PrfIsPersonStopped=function(id) return id==target end
  h.tasks[target]='cuffed';h.step(1000);assert(h.tasks[target]=='cuffed')
  h.handlers['prfrp:copom:call'](false);assert(h.entities[target])
end)
print('PRF COPOM client behavior passed')
