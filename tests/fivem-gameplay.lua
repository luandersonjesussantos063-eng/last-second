local root='fivem/resources/[prf]/prf_core/'
local support=dofile('tests/fivem-support.lua')
local function file(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function server(storage)
  local handlers,events,threads={}, {}, {}
  local now,duty=1000,true
  local entities={
    [1]={x=0,y=0,z=0,kind=1,model='officer',health=200,owner=1},
    [2]={x=0,y=0,z=0,kind=1,model='owner',health=200,owner=2},
    [100]={x=2,y=0,z=0,kind=1,model='citizen',health=200,owner=2},
    [200]={x=4,y=0,z=0,kind=2,model='police',health=1000,owner=1}
  }
  local env=setmetatable({source=1,
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,
    AddEventHandler=function(n,fn) local old=handlers[n];handlers[n]=function(...) if old then old(...) end;fn(...) end end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,to=to,args={...}} end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,Wait=function() coroutine.yield() end,
    PrfHasDuty=function(src) return duty and src==1 end,
    GetPlayers=function() return {'1','2'} end,GetPlayerPed=function(id) return id end,
    GetEntityCoords=function(id) return assert(entities[id],id) end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityType=function(id) return entities[id].kind end,GetEntityHealth=function(id) return entities[id].health end,
    GetEntityModel=function(id) return entities[id].model end,GetEntitySpeed=function(id) return entities[id].speed or 0 end,
    GetHashKey=function(n) return n end,GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,
    GetPedInVehicleSeat=function() return 0 end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,NetworkGetEntityOwner=function(id) return entities[id].owner end,
    GetResourceState=function() return 'started' end,DeleteEntity=function(id) entities[id]=nil end,
    GetGameTimer=function() return now*1000 end,os={time=function() return now end},
  },{__index=_G})
  file('config.lua',env);file('operations_config.lua',env);file('gameplay_config.lua',env)
  storage=support.progress(env,storage)
  for _,n in ipairs({'inventory_server.lua','people_server.lua','blitz_server.lua','services_server.lua','operations_server.lua'}) do file(n,env) end
  return {env=env,events=events,entities=entities,storage=storage,
    call=function(name,src,...) env.source=src;assert(handlers[name],name)(...) end,
    advance=function(n) now=now+(n or 3) end,duty=function(value) duty=value end,
    last=function(n) for i=#events,1,-1 do if events[i].name==n then return events[i] end end end,
    count=function(n) local c=0;for _,e in ipairs(events) do if e.name==n then c=c+1 end end;return c end}
end
check('profiles survive resource reloads, isolate officers and recover the backup without resetting corrupt data',function()
  local s=server();assert(s.env.PrfProgressStat(1,'missions',3))
  assert(s.env.PrfMutateProfile(1,function(p) p.inventory.WEAPON_PISTOL=1 end))
  assert(s.env.PrfLoadProfile(2).stats.missions==0)
  local r=server(s.storage);assert(r.env.PrfLoadProfile(1).stats.missions==3 and r.env.PrfLoadProfile(1).inventory.WEAPON_PISTOL==1)
  s.storage.fail=true;assert(not r.env.PrfProgressStat(1,'missions',2));assert(r.env.PrfLoadProfile(1).stats.missions==3)
  s.storage.fail=false
  local key='prfrp:profile:v1:test-license-1'
  s.storage.data[key]='broken JSON';local b=server(s.storage);assert(b.env.PrfLoadProfile(1).stats.missions==3)
  s.storage.data[key..':backup']='also broken';local bad=server(s.storage);local p,err=bad.env.PrfLoadProfile(1)
  assert(not p and err:find('preservado') and s.storage.data[key]=='broken JSON')
  local noid=server();noid.env.GetPlayerIdentifierByType=function() end;assert(not noid.env.PrfLoadProfile(1))
end)
local function inspection(s)
  s.call('prfrp:person:approach',1,100)
  s.env.PrfPersonAction(1,'search')
  return s.last('prfrp:inventory:inspect').args[2]
end
check('actual weapons become saved evidence only after removal; shared ammo and replay never duplicate items',function()
  local s=server();local token=inspection(s)
  local items={{name='WEAPON_PISTOL',ammo=12},{name='WEAPON_COMBATPISTOL',ammo=12},{name='WEAPON_CARBINERIFLE',ammo=90}}
  s.call('prfrp:inventory:inspection',3,100,token,items);assert(not s.last('prfrp:inventory:seize'))
  s.call('prfrp:inventory:inspection',2,100,token,items);assert(s.last('prfrp:inventory:seize').to==2)
  assert(not next(s.env.PrfLoadProfile(1).inventory),'no grant before actual removal')
  s.call('prfrp:inventory:removed',3,100,token,items);assert(not next(s.env.PrfLoadProfile(1).inventory))
  s.call('prfrp:inventory:removed',2,100,token,items)
  local p=s.env.PrfLoadProfile(1)
  assert(p.inventory.WEAPON_CARBINERIFLE==1 and p.inventory.AMMO_PISTOL==12 and p.inventory.AMMO_RIFLE==90 and p.stats.seizures==3)
  s.call('prfrp:inventory:removed',2,100,token,items);assert(s.env.PrfLoadProfile(1).inventory.AMMO_PISTOL==12)
  assert(server(s.storage).env.PrfLoadProfile(1).inventory.WEAPON_PISTOL==1)
  s.advance();local second=inspection(s);s.call('prfrp:inventory:inspection',2,100,second,{})
  assert(s.last('prfrp:person:report').args[3][2]:find('Nenhuma arma'))
end)
check('failed saves, expired tokens and moving away roll back removal instead of losing evidence',function()
  for _,reason in ipairs({'save','distance','expired'}) do
    local s=server();local token=inspection(s);local items={{name='WEAPON_PISTOL',ammo=15}}
    s.call('prfrp:inventory:inspection',2,100,token,items)
    if reason=='save' then s.storage.fail=true elseif reason=='distance' then s.entities[1].x=20 else s.advance(13) end
    s.call('prfrp:inventory:removed',2,100,token,items)
    assert(not next(s.env.PrfLoadProfile(1).inventory));assert(s.last('prfrp:inventory:restore').args[2]==token)
  end
  local s=server();local token=inspection(s);s.call('prfrp:inventory:inspection',2,100,token,{{name='WEAPON_PISTOL',ammo=1/0}})
  assert(not s.last('prfrp:inventory:seize'))
end)
check('empty searches report no weapons and searches never manufacture random contraband',function()
  local s=server();local token=inspection(s);s.call('prfrp:inventory:inspection',2,100,token,{})
  assert(s.last('prfrp:person:report').args[3][2]:find('Nenhuma arma') and not next(s.env.PrfLoadProfile(1).inventory))
end)
check('cones require duty, foot placement, finite nearby coordinates and the issued owner/model',function()
  local s=server();s.duty(false);s.call('prfrp:blitz:place',1,{x=2,y=0,z=0});assert(not s.last('prfrp:blitz:authorized'))
  s.duty(true)
  for _,p in ipairs({{x=0/0,y=0,z=0},{x=20,y=0,z=0},{x=2,y=0,z='bad'}}) do s.call('prfrp:blitz:place',1,p) end
  assert(not s.last('prfrp:blitz:authorized'))
  s.call('prfrp:blitz:place',1,{x=2,y=0,z=0});local token=s.last('prfrp:blitz:authorized').args[1]
  s.entities[300]={x=2,y=0,z=0,kind=3,model='prop_roadcone02a',owner=2}
  s.call('prfrp:blitz:spawned',1,token,300);assert(not s.last('prfrp:blitz:registered'))
  s.entities[300].owner=1;s.call('prfrp:blitz:spawned',1,token,300);assert(s.last('prfrp:blitz:registered'))
  s.advance(1);s.call('prfrp:blitz:place',1,{x=3,y=0,z=0});assert(s.count('prfrp:blitz:authorized')==2,'next cone does not wait for timeout')
  s.call('prfrp:blitz:clear',1);assert(not s.entities[300] and s.last('prfrp:blitz:clear'))
end)
check('support services reject remote targets and spoofed crews and perform once after a real arrival',function()
  for _,kind in ipairs({'ambulance','mechanic','fire'}) do
    local s=server();s.duty(false);s.call('prfrp:services:request',1,kind,{vehicle=200});assert(not s.last('prfrp:services:dispatch'))
    s.duty(true);s.entities[200].x=100;s.call('prfrp:services:request',1,'mechanic',{vehicle=200});assert(not s.last('prfrp:services:dispatch'))
    s.entities[200].x=4;s.call('prfrp:services:request',1,kind,{vehicle=200});local token=s.last('prfrp:services:dispatch').args[2]
    local def=s.env.Config.Services[kind]
    s.entities[300]={x=30,y=0,z=0,kind=2,model=def.vehicle,owner=1}
    s.entities[301]={x=30,y=0,z=0,kind=1,model=def.ped,owner=2,health=200}
    s.call('prfrp:services:spawned',1,kind,token,300,301);assert(not s.last('prfrp:services:registered'))
    s.entities[301].owner=1;s.call('prfrp:services:spawned',1,kind,token,300,301);assert(s.last('prfrp:services:registered'))
    s.call('prfrp:services:arrived',1,kind,token);assert(not s.last('prfrp:services:perform'))
    s.entities[301].x=2;s.call('prfrp:services:arrived',1,kind,token);s.call('prfrp:services:arrived',1,kind,token)
    assert(s.count('prfrp:services:perform')==1)
    s.call('prfrp:services:finished',1,kind,token,true);assert(not s.entities[300] and not s.entities[301] and s.entities[200])
  end
end)
check('faction incidents issue six specific combatants and save completion only after all are resolved',function()
  local s=server();s.call('prfrp:ops:action',1,'factionWar');local p=s.last('prfrp:ops:mission').args[1].point
  for k,v in pairs(p) do s.entities[1][k]=v end
  s.call('prfrp:ops:missionStep',1);s.advance(4);s.call('prfrp:ops:missionStep',1)
  local definitions=s.last('prfrp:ops:encounter').args[2];assert(#definitions==6)
  local ids={}
  for i,def in ipairs(definitions) do ids[i]=400+i;s.entities[400+i]={x=p.x,y=p.y,z=p.z,kind=1,model=def.model,owner=1,health=200} end
  s.entities[401].owner=2;s.call('prfrp:ops:registerEnemies',1,ids);assert(not s.last('prfrp:ops:enemiesRegistered'))
  s.entities[401].owner=1;s.entities[401].model='adder';s.call('prfrp:ops:registerEnemies',1,ids);assert(not s.last('prfrp:ops:enemiesRegistered'))
  s.entities[401].model=definitions[1].model;s.call('prfrp:ops:registerEnemies',1,ids);assert(s.last('prfrp:ops:enemiesRegistered'))
  s.advance();s.call('prfrp:ops:missionStep',1);assert(s.env.PrfLoadProfile(1).stats.missions==0)
  for _,id in ipairs(ids) do s.entities[id].health=0 end
  s.storage.fail=true;s.advance();s.call('prfrp:ops:missionStep',1);assert(s.env.PrfLoadProfile(1).stats.missions==0)
  s.storage.fail=false;s.advance();s.call('prfrp:ops:missionStep',1);assert(s.env.PrfLoadProfile(1).stats.missions==1)
  assert(s.last('prfrp:ops:mission').args[1]==false)
end)
check('native inventory scanning removes visible weapons and restores their actual ammo once on rollback',function()
  local callbacks,sent={},{}
  local guns={WEAPON_PISTOL=true,WEAPON_COMBATPISTOL=true,WEAPON_CARBINERIFLE=true}
  local ammo={AMMO_PISTOL=12,AMMO_RIFLE=90}
  local env=setmetatable({Config={},RegisterNetEvent=function(n,fn) callbacks[n]=fn end,CreateThread=function() end,
    NetworkGetEntityFromNetworkId=function(id) return id end,DoesEntityExist=function() return true end,
    IsPedAPlayer=function() return false end,NetworkHasControlOfEntity=function() return true end,
    GetHashKey=function(n) return n end,GetGameTimer=function() return 0 end,
    TriggerServerEvent=function(n,...) sent[#sent+1]={n,{...}} end,
    HasPedGotWeapon=function(_,name) return guns[name] end,
    GetAmmoInPedWeapon=function(_,name) return ammo[name=='WEAPON_CARBINERIFLE' and 'AMMO_RIFLE' or 'AMMO_PISTOL'] or 0 end,
    SetPedAmmo=function(_,name,count) ammo[name=='WEAPON_CARBINERIFLE' and 'AMMO_RIFLE' or 'AMMO_PISTOL']=count end,
    RemoveWeaponFromPed=function(_,name) guns[name]=nil end,
    GiveWeaponToPed=function(_,name,count) guns[name]=true;local kind=name=='WEAPON_CARBINERIFLE' and 'AMMO_RIFLE' or 'AMMO_PISTOL';ammo[kind]=(ammo[kind] or 0)+count end,
  },{__index=_G})
  file('config.lua',env);file('gameplay_config.lua',env);file('inventory_client.lua',env)
  callbacks['prfrp:inventory:inspect'](100,7);local found=sent[#sent][2][3];assert(#found==3)
  callbacks['prfrp:inventory:seize'](100,7,found);assert(not next(guns) and ammo.AMMO_PISTOL==0)
  callbacks['prfrp:inventory:restore'](100,7);callbacks['prfrp:inventory:restore'](100,7)
  assert(guns.WEAPON_PISTOL and guns.WEAPON_CARBINERIFLE and ammo.AMMO_PISTOL==12 and ammo.AMMO_RIFLE==90)
end)
print('PRF persistent gameplay behavior passed')
