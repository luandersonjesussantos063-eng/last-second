local root='fivem/resources/[prf]/prf_core/'
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function setup()
  local handlers,events,threads,deleted={},{},{},{}
  local now,duty=100,true
  local entities={ [1]={x=0,y=0,z=0,model='officer',health=100,kind=1},
    [2]={x=1,y=0,z=0,model='player',health=100,kind=1},
    [100]={x=2,y=0,z=0,model='citizen',health=100,kind=1},
    [101]={x=2,y=0,z=0,model='citizen2',health=100,kind=1},
    [200]={x=2,y=0,z=0,model='police',health=100,kind=2} }
  local env=setmetatable({source=1,
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,
    AddEventHandler=function(n,fn)
      local old=handlers[n];handlers[n]=function(...) if old then old(...) end;fn(...) end
    end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,to=to,args={...}} end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
    Wait=function() coroutine.yield() end,
    PrfHasDuty=function() return duty end,
    GetPlayerPed=function(id) return id end,
    GetPlayers=function() return {'1','2'} end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,
    NetworkGetEntityOwner=function() return 1 end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityType=function(id) return entities[id].kind end,
    GetEntityModel=function(id) return entities[id].model end,
    GetEntityHealth=function(id) return entities[id].health end,
    GetEntityCoords=function(id) return entities[id] end,
    GetEntitySpeed=function(id) return entities[id].speed or 0 end,
    GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,
    GetPedInVehicleSeat=function() return 0 end,
    GetResourceState=function() return 'started' end,
    GetHashKey=function(value) return value end,
    DeleteEntity=function(id) deleted[id]=true;entities[id]=nil end,
    os={time=function() return now end},
  },{__index=_G})
  for _,name in ipairs({'config.lua','operations_config.lua','people_server.lua','operations_server.lua'}) do
    assert(loadfile(root..name,'t',env))()
  end
  dofile('tests/fivem-support.lua').progress(env)
  local function atBase()
    local point=env.Config.SpawnBase
    for _,id in ipairs({1,100,200}) do for _,axis in ipairs({'x','y','z'}) do entities[id][axis]=point[axis] end end
  end
  return {env=env,entities=entities,deleted=deleted,events=events,atBase=atBase,
    call=function(name,...) handlers[name](...) end,
    order=function(name) handlers['prfrp:person:order'](name) end,
    approach=function(id) handlers['prfrp:person:approach'](id or 100) end,
    book=function() handlers['prfrp:person:bookArrest']() end,
    advance=function(seconds) now=now+seconds end,duty=function(value) duty=value end,
    tick=function() for _,thread in ipairs(threads) do local ok,err=coroutine.resume(thread);assert(ok,err) end end,
    last=function(name) for i=#events,1,-1 do if events[i].name==name then return events[i] end end end,
    count=function(name) local n=0;for _,e in ipairs(events) do if e.name==name then n=n+1 end end;return n end }
end
check('arrest requires active duty, a nearby NPC and actual approach',function()
  local s=setup();s.order('arrest');assert(not s.env.PrfHasArrest(1))
  s.approach();s.duty(false);s.order('arrest');assert(not s.env.PrfHasArrest(1))
  s.duty(true);s.entities[1].x=10;s.order('arrest');assert(not s.env.PrfHasArrest(1))
  s.entities[1].x=0;s.order('arrest')
  local order=s.last('prfrp:person:hold').args[3]
  assert(s.env.PrfHasArrest(1) and order.cuffed and order.mode=='cuffed')
  assert(s.last('prfrp:person:custody').args[1].x==s.env.Config.SpawnBase.x)
end)
check('booking requires a cuffed prisoner at the base, a stopped car and an officer on foot',function()
  local s=setup();s.approach();s.order('arrest');s.book()
  assert(not s.deleted[100] and not s.last('prfrp:person:booked'),'cannot book remotely')
  s.atBase();s.entities[1].car=200;s.book();assert(not s.deleted[100])
  s.entities[1].car=0;s.entities[100].car=200;s.entities[200].speed=5;s.book();assert(not s.deleted[100])
  s.entities[100].car=0;s.entities[200].speed=0;s.advance(2);s.order('uncuff');s.book();assert(not s.deleted[100])
  s.advance(2);s.order('cuff');s.book()
  assert(s.deleted[100] and not s.deleted[1] and not s.deleted[200])
  assert(not s.env.PrfHasArrest(1) and s.last('prfrp:person:custody').args[1]==false)
  assert(s.last('prfrp:operationsNotify').args[1]:find('PRISAO REGISTRADA #0001',1,true))
  local n=s.count('prfrp:person:booked');s.book();assert(s.count('prfrp:person:booked')==n,'cannot book twice')
  s.call('prfrp:person:arrestHistory');assert(s.last('prfrp:operationsNotify').args[1]:find('#0001',1,true))
end)
check('transport exceeds the ordinary stop timeout and cannot be lost by selecting another target',function()
  local s=setup();s.approach();s.order('arrest');s.advance(240);s.tick();s.tick()
  assert(s.env.PrfHasArrest(1),'prisoner must not be released after three minutes')
  s.approach(101);assert(s.env.PrfHasArrest(1) and s.last('prfrp:person:selected').args[1]==100)
  s.call('prfrp:ops:action','stop',200);assert(s.env.PrfHasArrest(1))
  s.call('prfrp:ops:action','release');assert(not s.env.PrfHasArrest(1) and not s.deleted[100])
end)
check('human players are never removed by NPC booking and cancelled arrests are not recorded',function()
  local s=setup();s.approach(2);s.order('arrest');s.book()
  assert(not s.env.PrfHasArrest(1) and not s.deleted[2])
  s.advance(2);s.approach();s.order('arrest');s.call('prfrp:person:cancel')
  s.call('prfrp:person:arrestHistory')
  assert(s.last('prfrp:operationsNotify').args[1]=='PRISOES SALVAS | Total: 0')
end)
print('PRF arrest and custody behavior passed')
