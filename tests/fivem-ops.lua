local root='fivem/resources/[prf]/prf_core/'
local function file(name,env)
  local fn,err=loadfile(root..name,'t',env); assert(fn,err); fn()
end
local function check(name,fn)
  local ok,err=pcall(fn); assert(ok,name..': '..tostring(err)); print('ok '..name)
end
local function server()
  local callbacks,events={},{}
  local now,duty,src=1000,false,1
  local p={x=0,y=0,z=0}
  local entities={ [100]={kind=2,p={x=5,y=0,z=0},speed=0},
    [400]={kind=1,p=p,health=100,owner=1,model='g_m_y_ballaeast_01'},
    [401]={kind=1,p=p,health=100,owner=1,model='g_m_y_mexgoon_02'},
    [402]={kind=1,p=p,health=100,owner=1,model='g_m_y_ballaeast_01'} }
  local occupied=false
  local env=setmetatable({Config={},source=src,
    RegisterNetEvent=function(n,fn) callbacks[n]=fn end,
    AddEventHandler=function(n,fn) callbacks[n]=fn end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,args={...}} end,
    PrfHasDuty=function(id) return duty and id==1 end,
    GetResourceState=function() return 'started' end,
    GetPlayerPed=function(id) return id end,
    GetEntityCoords=function(e) return (entities[e] and entities[e].p) or p end,
    GetEntitySpeed=function(e) return entities[e].speed end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    DoesEntityExist=function(e) return entities[e]~=nil end,
    GetEntityType=function(e) return entities[e].kind end,
    GetVehiclePedIsIn=function(e) return e==2 and occupied and 100 or 0 end,
    GetPlayers=function() return {'1','2'} end,
    GetVehicleNumberPlateText=function() return 'SIM0001' end,
    GetEntityHealth=function(e) return entities[e].health end,
    GetEntityModel=function(e) return entities[e].model end,
    GetHashKey=function(n) return n end,
    NetworkGetEntityOwner=function(e) return entities[e].owner end,
    DeleteEntity=function(e) entities[e]=nil end,
    os={time=function() return now end},
  },{__index=_G})
  file('operations_config.lua',env);env.Config.Operations.encounterChance=0
  file('operations_server.lua',env)
  local function count(name)
    local n=0;for _,e in ipairs(events) do if e.name==name then n=n+1 end end;return n
  end
  return {env=env,events=events,entities=entities,p=p,
    call=function(name,...) callbacks[name](...) end,
    action=function(name,data) callbacks['prfrp:ops:action'](name,data) end,
    duty=function() duty=true end,
    advance=function(n) now=now+(n or 3) end,
    occupied=function(v) occupied=v end,count=count,
    last=function(name) for i=#events,1,-1 do if events[i].name==name then return events[i] end end end }
end

check('operations require authorized duty',function()
  local s=server()
  for _,a in ipairs({'stop','documents','search','tow','backup','mission'}) do s.action(a,100) end
  assert(s.count('prfrp:ops:stop')==0 and s.count('prfrp:ops:backup')==0 and s.count('prfrp:ops:mission')==0)
end)
check('documents/search are stable simulated records and respect target distance/speed',function()
  local s=server();s.duty();s.action('stop',100)
  assert(s.count('prfrp:ops:stop')==1)
  s.action('documents');local report=s.last('prfrp:operationsNotify').args[1]
  assert(report:find('DOCUMENTOS SIMULADOS',1,true) and report:find('SIM0001',1,true))
  s.advance();s.action('documents');assert(s.last('prfrp:operationsNotify').args[1]==report)
  s.action('search');assert(s.last('prfrp:operationsNotify').args[1]:find('REVISTA SIMULADA',1,true))
  s.entities[100].speed=5;s.advance();s.action('documents')
  assert(s.last('prfrp:operationsNotify').args[1]:find('Aguarde',1,true))
  s.entities[100].speed=0;s.p.x=200;s.advance();s.action('documents')
  assert(s.last('prfrp:operationsNotify').args[1]:find('Aproxime',1,true))
end)
check('tow never dispatches with a player inside the target',function()
  local s=server();s.duty();s.action('stop',100);s.occupied(true);s.action('tow')
  assert(s.count('prfrp:ops:tow')==0)
  s.occupied(false);s.advance(31);s.action('tow');assert(s.count('prfrp:ops:tow')==1)
end)
check('backup has a shared server cooldown',function()
  local s=server();s.duty();s.action('backup');s.action('backup')
  assert(s.count('prfrp:ops:backup')==1)
  s.advance(46);s.action('backup');assert(s.count('prfrp:ops:backup')==2)
end)
check('patrol progression requires arriving and waiting at each checkpoint',function()
  local s=server();s.duty();s.action('mission')
  s.call('prfrp:ops:missionStep');assert(s.count('prfrp:ops:mission')==1)
  for i=1,3 do
    local event=s.last('prfrp:ops:mission');local point=event.args[1].point
    s.p.x,s.p.y,s.p.z=point.x,point.y,point.z
    s.advance();s.call('prfrp:ops:missionStep')
    assert(s.last('prfrp:ops:mission')==event)
    s.advance(4);s.call('prfrp:ops:missionStep')
  end
  assert(s.last('prfrp:ops:mission').args[1]==false)
end)
check('combat cannot finish until three valid owned enemies are registered and defeated',function()
  local s=server();s.duty()
  for i=1,3 do s.action('mission');s.action('cancelMission');s.advance(6) end
  s.action('mission') -- fourth mission is the guaranteed support encounter
  local point=s.last('prfrp:ops:mission').args[1].point
  s.p.x,s.p.y,s.p.z=point.x,point.y,point.z
  s.call('prfrp:ops:missionStep');s.advance(4);s.call('prfrp:ops:missionStep')
  assert(s.count('prfrp:ops:encounter')==1)
  s.entities[400].owner=2
  s.call('prfrp:ops:registerEnemies',{400,401,402});assert(s.count('prfrp:ops:enemiesRegistered')==0)
  s.entities[400].owner=1
  s.call('prfrp:ops:registerEnemies',{400,401,402});assert(s.count('prfrp:ops:enemiesRegistered')==1)
  s.advance();s.call('prfrp:ops:missionStep');assert(s.last('prfrp:ops:mission').args[1]~=false)
  for id=400,402 do s.entities[id].health=0 end
  s.advance();s.call('prfrp:ops:missionStep');assert(s.last('prfrp:ops:mission').args[1]==false)
end)
check('ending duty clears inspection and mission state',function()
  local s=server();s.duty();s.action('stop',100);s.action('mission')
  s.call('prfrp:ops:dutyEnded',1)
  assert(s.last('prfrp:ops:mission').args[1]==false)
  s.advance();s.action('documents')
  assert(s.last('prfrp:operationsNotify').args[1]:find('ABORDAR',1,true))
end)
print('PRF operations behavior passed')
