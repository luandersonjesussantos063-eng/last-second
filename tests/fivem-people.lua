local root='fivem/resources/[prf]/prf_core/'
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function server()
  local handlers,events,threads={},{},{}
  local now,duty,authorized=100,true,true
  local entities={ [1]={x=0,y=0,z=0,kind=1,health=100,model='officer'},
    [2]={x=0,y=0,z=0,kind=1,health=100,model='officer'},
    [100]={x=2,y=0,z=0,kind=1,health=100,model='citizen'},
    [200]={x=2,y=0,z=0,kind=2,health=100,model='car'} }
  local env=setmetatable({source=1,
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,
    AddEventHandler=function(n,fn)
      local previous=handlers[n]
      handlers[n]=function(...) if previous then previous(...) end;fn(...) end
    end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,to=to,args={...}} end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
    Wait=function() coroutine.yield() end,
    PrfHasDuty=function() return duty and authorized end,
    IsPlayerAceAllowed=function() return authorized end,
    CancelEvent=function() events.cancelled=true end,
    GetPlayerPed=function(id) return id end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetEntityOwner=function() return 1 end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityType=function(id) return entities[id].kind end,
    GetEntityModel=function(id) return entities[id].model end,
    GetEntityHealth=function(id) return entities[id].health end,
    GetEntityCoords=function(id) return entities[id] end,
    GetVehiclePedIsIn=function(id) return entities[id] and entities[id].car or 0 end,
    GetEntitySpeed=function(id) return entities[id].speed or 0 end,
    GetPedInVehicleSeat=function(car,seat) return entities[car].seats and entities[car].seats[seat] or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,
    GetHashKey=function(value) return value end,
    GetVehicleNumberPlateText=function() return 'SIM0001' end,
    GetPlayers=function() return {'1','2'} end,
    GetResourceState=function() return 'started' end,
    os={time=function() return now end},
  },{__index=_G})
  for _,file in ipairs({'config.lua','operations_config.lua','gameplay_config.lua','inventory_server.lua','people_server.lua','operations_server.lua','commands_server.lua'}) do
    assert(loadfile(root..file,'t',env))()
  end
  return {env=env,entities=entities,events=events,handlers=handlers,
    approach=function(id) handlers['prfrp:person:approach'](id) end,
    action=function(action,id) handlers['prfrp:ops:action'](action,id) end,
    order=function(action,data) handlers['prfrp:person:order'](action,data) end,
    time=function(delta) now=now+delta end,
    duty=function(value) duty=value end,authorized=function(value) authorized=value end,
    tick=function() for _,t in ipairs(threads) do local ok,err=coroutine.resume(t);assert(ok,err) end end,
    last=function(name) for i=#events,1,-1 do if events[i].name==name then return events[i] end end end,
    count=function(name) local n=0;for _,e in ipairs(events) do if e.name==name then n=n+1 end end;return n end }
end
check('pedestrian stops require duty, a live nearby person and an officer on foot',function()
  local s=server();s.duty(false);s.approach(100);assert(not s.last('prfrp:person:hold'))
  s.duty(true);s.approach(200);s.time(2);s.approach(1);assert(not s.last('prfrp:person:hold'))
  s.entities[100].x=30;s.time(2);s.approach(100);assert(not s.last('prfrp:person:hold'))
  s.entities[100].x=2;s.time(2);s.approach(100);assert(s.last('prfrp:person:hold').args[1]==100)
end)
check('documents and criminal history stay consistent through searches and repeated stops',function()
  local s=server();s.approach(100);s.action('documents')
  local first=table.concat(s.last('prfrp:person:report').args[3],'\n')
  assert(first:find('DOCUMENTO FICTICIO',1,true) and first:find('ANTECEDENTES SIMULADOS',1,true))
  s.time(3);s.action('search');assert(s.last('prfrp:inventory:inspect').args[1]==100)
  s.time(3);s.action('documents');assert(table.concat(s.last('prfrp:person:report').args[3],'\n')==first)
  s.action('release');assert(s.last('prfrp:person:selected').args[1]==false)
  s.time(3);s.approach(100);s.action('documents');assert(table.concat(s.last('prfrp:person:report').args[3],'\n')==first)
end)
check('inspection proximity and locks prevent remote inspection and competing officers',function()
  local s=server();s.approach(100);s.entities[1].x=15;s.action('documents')
  assert(not s.last('prfrp:person:report'))
  s.env.source=2;s.time(2);s.approach(100);assert(s.count('prfrp:person:hold')==1)
  s.env.source=1;s.action('release');s.env.source=2;s.time(2);s.approach(100)
  assert(s.count('prfrp:person:hold')==2)
end)
check('inspecting a person preserves the stopped car until explicit release',function()
  local s=server();s.action('stop',200);assert(s.last('prfrp:ops:stop'))
  s.approach(100);assert(not s.last('prfrp:ops:release'))
  s.action('tow');assert(not s.last('prfrp:ops:tow'))
  s.time(3);s.action('stop',200);assert(s.last('prfrp:person:selected').args[1]==false)
  s.action('documents');assert(s.last('prfrp:ops:inspectionAction'))
end)
check('traffic refusal is chosen once and release clears the vehicle lock',function()
  local s=server();s.entities[200].seats={[-1]=100}
  s.env.math=setmetatable({random=function(a,b) if a==100 then return 1 end;return b and a or 1 end},{__index=math})
  s.action('stop',200);assert(s.last('prfrp:ops:stop').args[2].flee)
  s.env.math.random=function(a,b) if a==100 then return 100 end;return b and a or 1 end
  s.time(3);s.action('stop',200);assert(s.last('prfrp:ops:stop').args[2].flee,'repeat selection must not reroll refusal')
  s.handlers['prfrp:ops:pursuitEnded'](200)
  assert(s.last('prfrp:traffic:resolved').args[1]==200)
  s.time(3);s.action('stop',200);assert(not s.last('prfrp:ops:stop').args[2].flee)
  s.action('releaseVehicle');s.env.source=2;s.time(3);s.action('stop',200)
  assert(s.last('prfrp:ops:stop').to==2,'release allows another officer to approach')
end)
check('death, distance, duty end and disconnection release the person',function()
  for _,mode in ipairs({'death','distance','duty','disconnect'}) do
    local s=server();s.approach(100)
    if mode=='death' then s.entities[100].health=0
    elseif mode=='distance' then s.entities[1].x=50
    elseif mode=='duty' then s.duty(false)
    else s.handlers.playerDropped() end
    s.tick();s.tick()
    assert(s.last('prfrp:person:release'),mode)
  end
end)
check('plain chat accepts exact simple words, enforces duty and leaves other chat untouched',function()
  local s=server();local chat=s.handlers.chatMessage
  chat(1,'tester','  viatura  ');assert(s.events.cancelled and s.last('prfrp:chatCommand').args[1]=='viatura')
  local n=s.count('prfrp:chatCommand');s.events.cancelled=nil
  chat(1,'tester','minha viatura azul');chat(1,'tester','viatura; quit');assert(not s.events.cancelled and s.count('prfrp:chatCommand')==n)
  s.duty(false);chat(1,'tester','revistar');assert(s.count('prfrp:chatCommand')==n)
  chat(1,'tester','servico');assert(s.count('prfrp:chatCommand')==n+1)
  s.authorized(false);chat(1,'tester','servico');assert(s.count('prfrp:chatCommand')==n+1)
end)
check('voice postures and cuffs preserve identity and validate inspection distance',function()
  local s=server();s.approach(100);s.action('documents')
  local identity=table.concat(s.last('prfrp:person:report').args[3],'\n')
  for _,mode in ipairs({'head','handsup','prone','kneel','stand','stay','follow'}) do
    s.time(2);s.order(mode);assert(s.last('prfrp:person:hold').args[3].mode==mode,mode)
  end
  s.entities[1].x=10;s.time(2);local n=s.count('prfrp:person:hold');s.order('cuff')
  assert(s.count('prfrp:person:hold')==n,'cuffs require proximity')
  s.entities[1].x=0;s.time(2);s.order('cuff');assert(s.last('prfrp:person:hold').args[3].cuffed)
  s.time(2);s.order('head');assert(s.count('prfrp:person:hold')==n+1,'cuffed arms cannot be raised')
  s.time(2);s.order('follow');assert(s.last('prfrp:person:hold').args[3].mode=='follow')
  s.time(2);s.order('uncuff');assert(not s.last('prfrp:person:hold').args[3].cuffed)
  s.time(2);s.action('documents');assert(table.concat(s.last('prfrp:person:report').args[3],'\n')==identity)
  s.time(2);s.action('breathalyzer');assert(s.last('prfrp:person:report').args[3][1]:find('BAFOMETRO SIMULADO',1,true))
end)
check('transport validates the police vehicle and passengers can exit a stopped inspected car',function()
  local s=server();s.approach(100);s.entities[200].model='police'
  s.order('enter',{vehicle=200});assert(s.last('prfrp:person:hold').args[3].vehicle==200)
  s.entities[100].car=200;s.time(2);s.order('exit');assert(s.last('prfrp:person:hold').args[3].mode=='exit')
  s.entities[200].seats={[-1]=100,[0]=2};s.entities[2].car=200
  s.time(2);s.action('stop',200);s.entities[200].speed=5;s.action('exit')
  assert(not s.last('prfrp:person:leaveVehicle'),'occupants must not exit a moving car')
  s.entities[200].speed=0;s.time(2);s.action('exit')
  assert(s.count('prfrp:person:leaveVehicle')==2)
end)
check('chat phrases and reinforcement quantities parse without consuming unrelated sentences',function()
  local s=server();local chat=s.handlers.chatMessage
  chat(1,'tester','desce do carro');assert(s.last('prfrp:chatCommand').args[1]=='descer')
  chat(1,'tester','deita no chao');assert(s.last('prfrp:chatCommand').args[1]=='deitar')
  chat(1,'tester','mão na cabeça');assert(s.last('prfrp:chatCommand').args[1]=='maonacabeca')
  chat(1,'tester','reforco 5');assert(s.last('prfrp:chatCommand').args[2][1]=='5')
  chat(1,'tester','/desce do carro');assert(s.last('prfrp:chatCommand').args[1]=='descer')
  local n=s.count('prfrp:chatCommand');chat(1,'tester','ele desce do carro e anda');assert(s.count('prfrp:chatCommand')==n)
end)
print('PRF pedestrian server behavior passed')
