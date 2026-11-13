local root='fivem/resources/[prf]/prf_core/'
local support=dofile('tests/fivem-support.lua')
local function file(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function setup(storage)
  local handlers,events,threads={}, {}, {}
  local now,allowed=1000,true
  local entities={[1]={x=0,y=0,z=0,kind=1,model='officer',health=200,owner=1},[2]={x=0,y=0,z=0,kind=1,model='other',health=200,owner=2}}
  local env=setmetatable({source=1,
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,RegisterCommand=function() end,
    AddEventHandler=function(n,fn) local old=handlers[n];handlers[n]=function(...) if old then old(...) end;fn(...) end end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,to=to,args={...}} end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,Wait=function() coroutine.yield() end,
    IsPlayerAceAllowed=function(src) return allowed and src==1 end,
    GetPlayerPed=function(id) return id end,GetPlayers=function() return {'1','2'} end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityCoords=function(id) local p=assert(entities[id],tostring(id));return {x=p.x,y=p.y,z=p.z} end,
    GetEntityType=function(id) return entities[id].kind end,GetEntityModel=function(id) return entities[id].model end,
    GetEntityHealth=function(id) return entities[id].health end,GetEntitySpeed=function(id) return entities[id].speed or 0 end,
    GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,GetPedInVehicleSeat=function(id,seat) return entities[id].driver or 0 end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,NetworkGetNetworkIdFromEntity=function(id) return id end,
    NetworkGetEntityOwner=function(id) return entities[id].owner end,GetHashKey=function(n) return n end,
    DeleteEntity=function(id) entities[id]=nil end,GetGameTimer=function() return now*1000 end,
    GetVehicleNumberPlateText=function() return 'RP0001' end,GetResourceState=function() return 'started' end,
    os={time=function() return now end},
  },{__index=_G})
  for _,name in ipairs({'config.lua','operations_config.lua','gameplay_config.lua','copom_config.lua'}) do file(name,env) end
  storage=support.progress(env,storage)
  for _,name in ipairs({'server.lua','inventory_server.lua','people_server.lua','operations_server.lua','services_server.lua','copom_server.lua'}) do file(name,env) end
  env.PrfCountBlitzCones=function() return 0 end
  handlers['prfrp:requestAction']('duty')
  local h={env=env,handlers=handlers,events=events,entities=entities,storage=storage}
  h.call=function(n,...) env.source=1;assert(handlers[n],n)(...) end
  h.tick=function() for _,thread in ipairs(threads) do local ok,err=coroutine.resume(thread);assert(ok,err) end end
  h.time=function(seconds) now=now+(seconds or 3) end
  h.last=function(n) for i=#events,1,-1 do if events[i].name==n then return events[i] end end end
  h.count=function(n) local count=0;for _,e in ipairs(events) do if e.name==n then count=count+1 end end;return count end
  h.select=function(index,variant)
    assert(env.PrfMutateProfile(1,function(p) p.copom={remaining={index},locations={1}} end))
    local old=env.math
    if variant then env.math=setmetatable({random=function(n) return math.min(variant,n) end},{__index=math}) end
    h.time(4);h.call('prfrp:requestAction','call');env.math=old
    return h.last('prfrp:copom:call').args[1]
  end
  h.scene=function(c)
    local p=c.location;local anchor={x=p.x,y=p.y,z=p.z,heading=0};local ids={}
    for k,v in pairs(p) do if k~='name' then entities[1][k]=v end end
    for i,def in ipairs(c.definition.actors) do
      local id=100+i;ids[def.key]=id
      entities[id]={x=p.x+def.x,y=p.y+def.y,z=p.z,kind=({vehicle=2,ped=1,object=3})[def.kind],model=def.model,
        health=def.injured and 135 or 200,owner=1,speed=0}
      if def.driver then entities[ids[def.driver]].driver=id;entities[id].car=ids[def.driver] end
    end
    h.call('prfrp:copom:register',c.session,anchor,ids)
    return ids,anchor
  end
  h.at=function(id) local e=entities[id];for _,k in ipairs({'x','y','z'}) do entities[1][k]=e[k] end end
  h.work=function(c,g)
    h.at(h.ids[g.actor]);h.call('prfrp:copom:workStart',c.session,g.key);h.time((g.seconds or 4)+1)
    h.call('prfrp:copom:workFinish',c.session,g.key)
  end
  return h
end
check('ten call types do not repeat within a cycle, survive reloads and avoid consecutive location repeats',function()
  local s=setup();local seen,last={},nil
  for i=1,20 do
    s.time(4);s.call('prfrp:requestAction','call');local c=s.last('prfrp:copom:call').args[1]
    assert(type(c)=='table' and c.location.name~=last);last=c.location.name
    if i==11 then seen={} end
    assert(not seen[c.definition.key],c.definition.key);seen[c.definition.key]=true
    s.call('prfrp:requestAction','cancel')
    s=setup(s.storage)
  end
end)
check('arrival, legacy E events and finish requests never award an empty or unresolved scene',function()
  local s=setup();local c=s.select(1,1)
  assert(not s.handlers['prfrp:advanceCall'] and not s.handlers['prfrp:completeCall'])
  s.call('prfrp:copom:status',true);assert(s.env.PrfLoadProfile(1).stats.calls==0)
  s.ids=s.scene(c);s.call('prfrp:copom:status',true);assert(s.env.PrfLoadProfile(1).stats.calls==0)
  s.env.source=2;s.handlers['prfrp:copom:register'](c.session,c.location,{});assert(s.env.PrfLoadProfile(1).stats.calls==0)
end)
check('scene registration rejects foreign owners, wrong models, duplicate IDs and remote anchors',function()
  for _,reason in ipairs({'owner','model','duplicate','distance','session'}) do
    local s=setup();local c=s.select(2,1)
    local old=s.call;s.call=function(n,...) if n~='prfrp:copom:register' then old(n,...) end end
    local ids,anchor=s.scene(c);s.call=old
    if reason=='owner' then s.entities[ids.carro1].owner=2
    elseif reason=='model' then s.entities[ids.carro1].model='adder'
    elseif reason=='duplicate' then ids.carro2=ids.carro1
    elseif reason=='distance' then anchor.x=anchor.x+500
    else c.session=c.session+1 end
    s.call('prfrp:copom:register',c.session,anchor,ids);assert(not s.last('prfrp:copom:registered'),reason)
  end
end)
check('work checks elapsed time, current scene, proximity, prerequisites and cancellation',function()
  local s=setup();local c=s.select(3,1);s.ids=s.scene(c)
  local talk=c.definition.objectives[2];s.at(s.ids.motorista)
  s.call('prfrp:copom:workStart',c.session,talk.key);s.call('prfrp:copom:workFinish',c.session,talk.key)
  local progress=s.last('prfrp:copom:progress').args[2];assert(not progress[2].done)
  s.time(5);s.entities[1].x=s.entities[1].x+30;s.call('prfrp:copom:workFinish',c.session,talk.key)
  assert(not s.last('prfrp:copom:progress').args[2][2].done)
  local obstacle=c.definition.objectives[3];s.at(s.ids[obstacle.actor]);s.time()
  s.call('prfrp:copom:workStart',c.session,obstacle.key);assert(s.entities[s.ids[obstacle.actor]],'cannot clear before signaling')
  s.env.PrfCountBlitzCones=function() return 2 end;s.call('prfrp:copom:status')
  s.call('prfrp:copom:workStart',c.session,obstacle.key);s.call('prfrp:copom:workCancel',c.session,obstacle.key);s.time(6)
  s.call('prfrp:copom:workFinish',c.session,obstacle.key);assert(s.entities[s.ids[obstacle.actor]])
  s.work(c,obstacle);assert(not s.entities[s.ids[obstacle.actor]],'actual obstruction removed')
end)
check('all twenty templates/variants require their real objectives and save completion once',function()
  for index=1,10 do for variant=1,2 do
    local s=setup();local c=s.select(index,variant);s.ids=s.scene(c)
    s.env.PrfCountBlitzCones=function() return 2 end
    for _,g in ipairs(c.definition.objectives) do
      s.call('prfrp:copom:status');local id=g.actor and s.ids[g.actor]
      if ({talk=true,clear=true,cargo=true,load=true})[g.kind] then s.work(c,g)
      elseif g.kind=='contain' then s.entities[id].health=0
      elseif g.kind=='escort' then
        s.entities[id].x=c.location.x+c.definition.safe.x;s.entities[id].y=c.location.y+c.definition.safe.y;s.at(id)
        s.env.PrfCopomEvidence(1,'follow',id)
      elseif g.kind=='ambulance' then s.entities[id].health=200;s.env.PrfCopomEvidence(1,'ambulance',id)
      elseif g.kind=='backup' then
        s.entities[999]={x=c.location.x,y=c.location.y,z=c.location.z,kind=2,model='police',owner=1,health=1000}
        s.env.PrfCopomEvidence(1,'backup',999)
      elseif g.kind~='secure' then s.env.PrfCopomEvidence(1,g.kind,id) end
      s.call('prfrp:copom:status')
    end
    assert(s.env.PrfLoadProfile(1).stats.calls==1,c.definition.key..' variant '..variant)
    s.call('prfrp:copom:status',true);assert(s.env.PrfLoadProfile(1).stats.calls==1)
  end end
end)
check('real traffic/documents/breathalyzer/arrest hooks resolve the drunk-driver call without fake E stages',function()
  local s=setup();local c=s.select(4,2);s.ids=s.scene(c)
  local car,ped=s.ids.carro,s.ids.suspeito
  s.at(car);s.call('prfrp:ops:action','stop',car)
  assert(s.last('prfrp:ops:stop').args[2].flee==true)
  s.time();s.call('prfrp:ops:action','documents')
  local report=s.last('prfrp:tablet:vehicleDocument').args[1];assert(report[#report]:find('bafometro'))
  s.time();s.call('prfrp:ops:action','breathalyzer');assert(s.last('prfrp:operationsNotify').args[1]:find('0.62',1,true))
  assert(s.env.PrfLoadProfile(1).stats.calls==0)
  s.entities[ped].car=0;s.at(ped);s.call('prfrp:person:approach',ped);s.call('prfrp:person:order','arrest')
  assert(s.env.PrfLoadProfile(1).stats.calls==1 and s.env.PrfHasArrest(1) and s.entities[ped],'prisoner survives scene cleanup')
end)
check('medical services target the scene victim, require actual crew arrival and heal before completion',function()
  local s=setup();local c=s.select(1,1);s.ids=s.scene(c)
  -- No arbitrary NPC may be submitted as a patient.
  s.call('prfrp:services:request','ambulance',{person=s.ids.motorista});assert(not s.last('prfrp:services:dispatch'))
  s.call('prfrp:requestAction','cancel');c=s.select(8,1);s.ids=s.scene(c);s.at(s.ids.motorista)
  s.call('prfrp:services:request','ambulance',{person=s.ids.motorista})
  local dispatch=s.last('prfrp:services:dispatch');assert(dispatch.args[3]==s.ids.motorista,'NPC patient instead of officer')
  local token=dispatch.args[2];local p=s.entities[s.ids.motorista]
  s.entities[300]={x=p.x,y=p.y,z=p.z,kind=2,model='ambulance',owner=1,health=1000}
  s.entities[301]={x=p.x,y=p.y,z=p.z,kind=1,model='s_m_m_paramedic_01',owner=1,health=200}
  s.call('prfrp:services:spawned','ambulance',token,300,301);s.call('prfrp:services:arrived','ambulance',token)
  s.call('prfrp:services:finished','ambulance',token,true)
  local list=s.last('prfrp:copom:progress').args[2];assert(not list[#list].done,'no award for an unhealed patient')
  s.entities[s.ids.motorista].health=200;s.call('prfrp:copom:status');assert(s.last('prfrp:copom:progress').args[2][#list].done)
end)
check('tow waits for investigation, actual dispatch and departure; scene completion never deletes a prisoner',function()
  local s=setup();local c=s.select(5,1);s.ids=s.scene(c)
  local car,ped=s.ids.carro,s.ids.suspeito;s.entities[ped].car=0;s.at(car)
  s.call('prfrp:services:request','tow',{vehicle=car});assert(not s.last('prfrp:services:dispatch'))
  for _,kind in ipairs({'stop','documents'}) do s.env.PrfCopomEvidence(1,kind,car) end
  s.env.PrfCopomEvidence(1,'search',ped)
  s.at(ped);s.call('prfrp:person:approach',ped);s.call('prfrp:person:order','arrest')
  s.call('prfrp:services:request','tow',{vehicle=car});local token=s.last('prfrp:services:dispatch').args[2]
  local p=s.entities[car]
  s.entities[300]={x=p.x,y=p.y,z=p.z,kind=2,model='flatbed',owner=1,health=1000}
  s.entities[301]={x=p.x,y=p.y,z=p.z,kind=1,model='s_m_m_trucker_01',owner=1,health=200}
  s.call('prfrp:services:spawned','tow',token,300,301);s.call('prfrp:services:arrived','tow',token)
  s.entities[301].car=300
  for _,id in ipairs({car,300,301}) do s.entities[id].x=s.entities[id].x+70 end
  s.call('prfrp:services:finished','tow',token,true)
  assert(s.env.PrfLoadProfile(1).stats.calls==1 and not s.entities[car] and s.entities[ped])
end)
check('failed saves preserve a resolved call for retry and stale work never affects a later call',function()
  local s=setup();local c=s.select(1,1);s.ids=s.scene(c);s.env.PrfCountBlitzCones=function() return 2 end
  s.call('prfrp:copom:status');s.work(c,c.definition.objectives[2]);s.storage.fail=true
  s.env.PrfCopomEvidence(1,'mechanic',s.ids.carro);assert(s.env.PrfLoadProfile(1).stats.calls==0)
  s.storage.fail=false;s.call('prfrp:copom:status');assert(s.env.PrfLoadProfile(1).stats.calls==1)
  local nextCall=s.select(3,1);s.ids=s.scene(nextCall)
  s.call('prfrp:copom:workFinish',c.session,'talk_motorista');assert(s.env.PrfLoadProfile(1).stats.calls==1)
end)
check('missing scene actors or death of a victim fails visibly without awarding completion',function()
  for _,missing in ipairs({true,false}) do
    local s=setup();local c=s.select(2,1);s.ids=s.scene(c)
    if missing then s.entities[s.ids.vitima]=nil else s.entities[s.ids.vitima].health=0 end
    s.tick();s.tick()
    assert(s.env.PrfLoadProfile(1).stats.calls==0 and s.last('prfrp:copom:call').args[1]==false)
  end
end)
print('PRF COPOM scene behavior passed')
