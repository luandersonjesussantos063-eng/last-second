local root='fivem/resources/[prf]/prf_core/'
local function file(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local mt={};local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__sub=function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__len=function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
local function setup()
  local serverEvents,clientEvents,threads,events,requests={},{},{},{},{}
  local now,duty,urgent,aim=100000,true,false,false
  local waypoint,aimed=vec(300,0,0),0
  local entities={
    [1]={kind=1,model='officer',p=vec(0,0,0),car=10,health=200,weapons={},selected='WEAPON_UNARMED'},
    [2]={kind=1,model='s_m_y_hwaycop_01',p=vec(0,0,0),health=200,owner=2},
    [10]={kind=2,model='police',p=vec(0,0,0),health=1000,speed=0,seats={[-1]=1,[0]=20,[1]=21,[2]=22}},
    [20]={kind=1,model='s_m_y_hwaycop_01',p=vec(0,0,0),car=10,owner=1,health=200},
    [21]={kind=1,model='s_m_y_hwaycop_01',p=vec(0,0,0),car=10,owner=1,health=200},
    [22]={kind=1,model='s_m_y_hwaycop_01',p=vec(0,0,0),car=10,owner=1,health=200},
    [30]={kind=1,model='citizen',p=vec(16,0,0),owner=1,health=200},
    [31]={kind=1,model='citizen',p=vec(14,0,0),owner=1,health=200},
    [40]={kind=2,model='asea',p=vec(50,0,0),health=1000,speed=12,seats={[-1]=50}},
    [50]={kind=1,model='citizen',p=vec(50,0,0),car=40,owner=1,health=200}
  }
  local tasks,sirenWrites={},0
  local rayMode,rayCount,deferClear,delayedClear=false,0,false,false
  local function coords(id) local e=assert(entities[id],id);return e.car and e.car~=0 and entities[e.car].p or e.p end
  local function seat(ped,car,index)
    local old=entities[ped].car
    if old and entities[old] then for i,p in pairs(entities[old].seats) do if p==ped then entities[old].seats[i]=nil end end end
    entities[ped].car=car
    if car~=0 then entities[car].seats[index]=ped else entities[ped].p=coords(old) end
  end
  local shared={
    GetHashKey=function(n) return n end,GetPlayerPed=function(id) return id end,GetPlayers=function() return {'1','2'} end,
    DoesEntityExist=function(id) return entities[id]~=nil end,GetEntityCoords=coords,
    GetEntityType=function(id) return entities[id].kind end,GetEntityModel=function(id) return entities[id].model end,
    GetEntityHealth=function(id) return entities[id].health end,GetEntitySpeed=function(id) return entities[id].speed or 0 end,
    GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,
    GetPedInVehicleSeat=function(id,index) return entities[id].seats[index] or 0 end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return entities[id] and id or 0 end,
    NetworkGetEntityOwner=function(id) return entities[id].owner or 1 end,
    GetVehicleNumberPlateText=function() return 'RP0001' end,
    os={time=function() return math.floor(now/1000) end},
    GetCurrentResourceName=function() return 'prf_core' end,
  }
  local function add(list,name,fn) local old=list[name];list[name]=function(...) if old then old(...) end;fn(...) end end
  local function env(extra) return setmetatable(extra,{__index=function(_,k) return shared[k] or _G[k] end}) end
  local pursuit=0
  local server=env({source=1,
    RegisterNetEvent=function(n,fn) serverEvents[n]=fn end,AddEventHandler=function(n,fn) add(serverEvents,n,fn) end,
    PrfHasDuty=function(src) return duty and src==1 end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,Wait=function(ms) coroutine.yield(ms) end,
    TriggerClientEvent=function(n,to,...)
      events[#events+1]={name=n,to=to,args={...}}
      if n=='prfrp:ops:stop' then local id,info=...;pursuit=info.flee and id or 0 end
      if n=='prfrp:driver:clear' and deferClear then delayedClear=true
      elseif clientEvents[n] then clientEvents[n](...) end
    end,
    TriggerEvent=function(n,...) if serverEvents[n] then serverEvents[n](...) end end,
  })
  for _,name in ipairs({'config.lua','operations_config.lua','gameplay_config.lua','driver_server.lua','people_server.lua','operations_server.lua'}) do file(name,server) end
  server.Config.Operations.nonComplianceChance=0
  local client=env({
    RegisterNetEvent=function(n,fn) clientEvents[n]=fn end,AddEventHandler=function(n,fn) add(clientEvents,n,fn) end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,Wait=function(ms) coroutine.yield(ms) end,
    GetGameTimer=function() return now end,PlayerPedId=function() return 1 end,PlayerId=function() return 1 end,
    TriggerEvent=function(n,...) if clientEvents[n] then clientEvents[n](...) end end,
    TriggerServerEvent=function(n,...) requests[#requests+1]={name=n,args={...}};if serverEvents[n] then serverEvents[n](...) end end,
    NetworkGetEntityIsNetworked=function() return true end,NetworkRegisterEntityAsNetworked=function() end,
    NetworkHasControlOfEntity=function() return true end,
    PrfGetSquadOfficer=function() return 20 end,PrfGetPatrolVehicle=function() return 10 end,
    IsEntityDead=function(id) return entities[id].health<=0 end,
    SetVehicleHandbrake=function(id,on) entities[id].brake=on end,
    TaskVehicleTempAction=function(_,car) entities[car].speed=0;tasks[car]='brake' end,
    TaskLeaveVehicle=function(ped) if entities[ped].car and entities[ped].car~=0 then seat(ped,0) end end,
    SetPedIntoVehicle=seat,TaskEnterVehicle=function(ped,car,_,index) seat(ped,car,index) end,
    GetVehicleMaxNumberOfPassengers=function() return 3 end,
    IsVehicleSeatFree=function(car,index) return not entities[car].seats[index] end,
    ClearPedTasks=function() end,SetDriverAbility=function() end,SetDriverAggressiveness=function() end,
    GiveWeaponToPed=function(ped,name) entities[ped].weapons[name]=true end,
    HasPedGotWeapon=function(ped,name) return entities[ped].weapons[name] end,
    SetCurrentPedWeapon=function(ped,name) entities[ped].selected=name end,GetSelectedPedWeapon=function(ped) return entities[ped].selected end,
    RemoveWeaponFromPed=function(ped,name) entities[ped].weapons[name]=nil end,
    IsPedArmed=function(ped) return entities[ped].selected~='WEAPON_UNARMED' end,
    IsPlayerFreeAiming=function() return aim and not rayMode end,
    PrfIsAimHeld=function() return aim and rayMode end,
    GetGameplayCamCoord=function() return vec(0,0,1.5) end,GetGameplayCamRot=function() return vec(0,-90,0) end,
    StartShapeTestRay=function(_,_,_,_,_,_,_,ignored) assert(ignored==10);rayCount=rayCount+1;return 1 end,
    GetShapeTestResult=function() return 2,true,vec(50,0,0),vec(0,0,1),aimed end,IsNuiFocused=function() return false end,
    GetEntityPlayerIsFreeAimingAt=function() return aimed~=0 and not rayMode,aimed end,
    PrfIsCompanion=function(ped) return ped>=20 and ped<=22 end,
    PrfIsEmergencyDriving=function() return urgent end,
    PrfGetPursuitVehicle=function() return pursuit end,
    GetFirstBlipInfoId=function() return waypoint and 8 or 0 end,DoesBlipExist=function(id) return id==8 and waypoint~=nil end,
    GetBlipInfoIdCoord=function() return waypoint end,
    GetClosestVehicleNodeWithHeading=function(x,y,z) return true,vec(x,y,z),0 end,
    TaskVehicleDriveToCoordLongrange=function(_,car,x,y,z,speed) tasks[car]={kind='route',x=x,y=y,z=z,speed=speed} end,
    TaskVehicleChase=function(_,target) tasks[10]={kind='chase',target=target} end,
    SetDriveTaskDrivingStyle=function() end,SetDriveTaskCruiseSpeed=function(_,speed) if type(tasks[10])=='table' then tasks[10].speed=speed end end,
    SetVehicleSiren=function() sirenWrites=sirenWrites+1 end,
    vector3=vec,
  })
  file('config.lua',client);file('driver_client.lua',client);clientEvents['prfrp:setDuty'](true)
  local h={client=client,server=server,entities=entities,events=events,requests=requests,tasks=tasks}
  h.step=function(ms)
    now=now+(ms or 250)
    for i=1,#threads do local t=threads[i];if coroutine.status(t.co)~='dead' and now>=t.due then local ok,wait=coroutine.resume(t.co);assert(ok,wait);t.due=now+math.max(1,wait or 1) end end
  end
  h.run=function(n,ms) for _=1,n do h.step(ms) end end
  h.command=function(action) clientEvents['prfrp:driver:command'](action) end
  h.call=function(name,...) server.source=1;serverEvents[name](...) end
  h.start=function() h.command('driverStart');h.run(15);assert(client.PrfDriverIsPassenger(),'driver must take wheel and player must sit as passenger') end
  h.aim=function(id) aim,aimed=true,id end
  h.ray=function(value) rayMode=value end
  h.rays=function() return rayCount end
  h.deferClear=function() deferClear=true end
  h.flushClear=function() if delayedClear then clientEvents['prfrp:driver:clear']();delayedClear=false end end
  h.waypoint=function(p) waypoint=p end
  h.urgent=function(value) urgent=value end
  h.sirenWrites=function() return sirenWrites end
  h.last=function(name) for i=#events,1,-1 do if events[i].name==name then return events[i] end end end
  h.duty=function(value) duty=value;clientEvents['prfrp:setDuty'](value) end
  return h
end
check('NPC takes the wheel, player becomes passenger and a changed waypoint updates the actual driving task',function()
  local s=setup();s.start()
  assert(s.entities[10].seats[-1]==20 and s.entities[10].seats[0]==1)
  assert(s.tasks[10].kind=='route' and s.tasks[10].x==300 and s.tasks[10].speed==22)
  s.waypoint(vec(600,100,0));s.run(5);assert(s.tasks[10].x==600 and s.tasks[10].y==100)
  s.urgent(true);s.run(5);assert(s.tasks[10].speed==35 and s.sirenWrites()==0,'sirens remain under user control')
end)
check('stop holds even when waypoint changes; resume continues and takeover preserves all original entities',function()
  local s=setup();s.start();s.command('driverStop');s.waypoint(vec(700,0,0));s.run(8)
  assert(s.entities[10].brake and s.tasks[10]=='brake')
  s.command('driverResume');s.run(6);assert(s.tasks[10].x==700)
  s.command('driverTakeover');s.run(12)
  assert(s.entities[10].seats[-1]==1 and not s.client.PrfIsChauffeur(20) and s.entities[20])
  assert(not s.entities[1].weapons.WEAPON_COMBATPISTOL,'temporary aim weapon removed')
end)
check('aiming at a person brakes before the server accepts a passenger stop; unrelated people remain protected',function()
  local s=setup();s.start();s.aim(30);s.run(8)
  s.entities[10].p=vec(7,0,0);s.run(8)
  assert(s.entities[10].brake and s.last('prfrp:person:selected').args[1]==30)
  s.run(8);s.call('prfrp:person:approach',31)
  assert(s.last('prfrp:person:selected').args[1]==30,'passenger exception only applies to authorized target')
end)
check('aiming at a car intercepts it and a fleeing target keeps the NPC driver in pursuit',function()
  local s=setup();s.start();s.server.Config.Operations.nonComplianceChance=100
  s.aim(40);s.run(8);assert(s.tasks[10].kind=='chase' and s.tasks[10].target==40)
  s.entities[10].p=vec(25,0,0);s.run(6);assert(s.last('prfrp:ops:stop').args[1]==40 and s.last('prfrp:ops:stop').args[2].flee)
  s.entities[40].speed=0;s.run(16)
  assert(not s.entities[10].brake,'brief slow-down with an active pursuit must not park the patrol')
end)
check('an obedient car is held for inspection and nearby allies cannot be auto-targeted',function()
  local s=setup();s.start();s.aim(20);s.run(8);assert(not s.last('prfrp:driver:intercept'))
  s.aim(40);s.run(8);s.entities[10].p=vec(35,0,0);s.entities[40].speed=0;s.run(20)
  assert(s.last('prfrp:ops:stop').args[2].flee==false and s.entities[10].brake)
end)
check('server rejects invalid IDs, human drivers, foreign NPCs and remote vehicles',function()
  for _,kind in ipairs({'nil','human','owner','distance'}) do
    local s=setup();local driver=20
    if kind=='nil' then s.call('prfrp:driver:request',nil,nil)
    else
      if kind=='human' then driver=2 elseif kind=='owner' then s.entities[20].owner=2 else s.entities[10].p=vec(100,0,0);s.entities[1].car=0 end
      s.call('prfrp:driver:request',10,driver)
    end
    assert(not s.last('prfrp:driver:approved'),kind)
  end
end)
check('leaving duty cancels navigation and never confiscates a pistol the player already owned',function()
  local s=setup();s.entities[1].weapons.WEAPON_COMBATPISTOL=true;s.start();s.duty(false);s.run(8)
  assert(not s.client.PrfGetDriverVehicle() or s.client.PrfGetDriverVehicle()==0)
  assert(s.entities[1].weapons.WEAPON_COMBATPISTOL and s.entities[10] and s.entities[20])
end)
check('Z aiming uses a camera ray when drive-by aiming does not return a native target',function()
  local s=setup();s.start();s.ray(true);s.aim(40);s.run(8)
  assert(s.rays()>0 and s.last('prfrp:driver:intercept').args[3]=='vehicle')
end)
check('a delayed server clear after takeover cannot leave the human driver with a locked handbrake',function()
  local s=setup();s.start();s.deferClear();s.command('driverTakeover');s.run(8)
  assert(s.entities[10].seats[-1]==1 and not s.entities[10].brake)
  s.flushClear();s.run(8);assert(s.entities[10].seats[-1]==1 and not s.entities[10].brake)
end)
print('PRF NPC driver and interception behavior passed')
