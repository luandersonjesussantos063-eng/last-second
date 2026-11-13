local root='fivem/resources/[prf]/prf_core/'
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function setup(human)
  local handlers,threads,requests,blips={},{},{},{}
  local now,blipId=1000,0
  local entities={ [1]={p={x=0,y=0,z=0}},
    [100]={p={x=0,y=0,z=0},speed=5,driver=200},[200]={car=100},
    [101]={p={x=20,y=0,z=0},speed=5,driver=201},[201]={car=101} }
  local env=setmetatable({
    RegisterNetEvent=function(n,fn) handlers[n]=fn end,AddEventHandler=function(n,fn) handlers[n]=fn end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,
    Wait=function(ms) coroutine.yield(ms) end,GetGameTimer=function() return now end,
    PlayerPedId=function() return 1 end,GetCurrentResourceName=function() return 'prf_core' end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return id end,
    NetworkHasControlOfEntity=function() return true end,NetworkRequestControlOfEntity=function() end,
    GetEntityCoords=function(id) return entities[id].p or entities[entities[id].car].p end,
    GetEntitySpeed=function(id) return entities[id].speed end,
    GetPedInVehicleSeat=function(id,seat) return seat==-1 and entities[id].driver or 0 end,
    GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,
    IsPedAPlayer=function(ped) return human and ped==200 end,
    IsEntityDead=function() return false end,
    GetOffsetFromEntityInWorldCoords=function(id,x,y,z) local p=entities[id].p;return {x=p.x+x,y=p.y+y,z=p.z+z} end,
    GetGroundZFor_3dCoord=function() return true,0 end,
    SetVehicleHandbrake=function(id,value) entities[id].brake=value end,
    SetVehicleEngineOn=function(id,value) entities[id].engine=value end,
    SetEntityAsMissionEntity=function(id) entities[id].mission=true end,
    SetEntityAsNoLongerNeeded=function(id) entities[id].mission=false end,
    SetPedAsNoLongerNeeded=function(id) entities[id].mission=false end,
    SetBlockingOfNonTemporaryEvents=function(id,value) entities[id].blocked=value end,
    SetPedKeepTask=function() end,
    TaskVehicleDriveToCoordLongrange=function(_,id,x,y,z) entities[id].destination={x=x,y=y,z=z} end,
    TaskVehicleTempAction=function(_,id) entities[id].speed=0 end,
    TaskVehicleDriveWander=function(_,id,speed) entities[id].wander=speed;entities[id].speed=speed end,
    TaskWanderStandard=function() end,
    AddBlipForEntity=function(id) blipId=blipId+1;blips[blipId]=id;return blipId end,
    RemoveBlip=function(id) blips[id]=nil end,
    TriggerEvent=function(n,...) if handlers[n] then handlers[n](...) end end,
    TriggerServerEvent=function(n,...)
      requests[#requests+1]={name=n,args={...}}
      if n=='prfrp:ops:pursuitEnded' then handlers['prfrp:traffic:resolved'](...) end
    end,
  },{__index=_G})
  for _,n in ipairs({'SetBlipSprite','SetBlipColour','SetBlipRoute','BeginTextCommandSetBlipName',
    'AddTextComponentString','EndTextCommandSetBlipName'}) do env[n]=function() end end
  assert(loadfile(root..'traffic_client.lua','t',env))()
  handlers['prfrp:setDuty'](true)
  local function step(ms)
    now=now+(ms or 500)
    for i=1,#threads do
      local t=threads[i]
      if coroutine.status(t.co)~='dead' and t.due<=now then
        local ok,wait=coroutine.resume(t.co);assert(ok,wait);t.due=now+(wait or 1)
      end
    end
  end
  return {env=env,handlers=handlers,entities=entities,requests=requests,blips=blips,step=step,
    run=function(n,ms) for i=1,n do step(ms) end end,
    stop=function(id,flee) handlers['prfrp:ops:stop'](id,{flee=flee}) end,
    arrive=function(id) entities[id].p=entities[id].destination;entities[id].speed=0;step() end}
end
check('compliant drivers reach the shoulder and remain stopped until explicit release',function()
  local s=setup();s.stop(100,false);s.step()
  local car=s.entities[100];car.speed=0;s.run(10)
  assert(not car.brake,'a temporary stop before reaching the shoulder is not completion')
  s.arrive(100);assert(car.brake and car.engine==false and s.entities[200].blocked)
  s.run(1200);assert(car.brake and not car.wander,'there is no automatic release timeout')
  s.stop(101,false);s.step();s.arrive(101)
  assert(car.brake and s.entities[101].brake,'selecting a new car keeps the previous stop')
  s.handlers['prfrp:ops:release'](101);assert(car.brake and not s.entities[101].brake)
  s.handlers['prfrp:ops:release'](false);assert(not car.brake and car.wander==15 and not s.entities[200].blocked)
end)
check('a refusing driver starts pursuit and remains held after being caught',function()
  local s=setup();s.stop(100,true);s.step();local car=s.entities[100]
  assert(car.wander==30 and s.env.PrfGetPursuitVehicle()==100 and next(s.blips))
  s.run(20);assert(s.env.PrfGetPursuitVehicle()==100)
  car.p={x=10,y=0,z=0};car.speed=0;s.run(16)
  assert(s.env.PrfGetPursuitVehicle()==0 and not next(s.blips) and car.brake)
  assert(s.requests[#s.requests].name=='prfrp:ops:pursuitEnded')
  s.handlers['prfrp:ops:release'](false);assert(not car.brake and car.wander==15)
end)
check('tow and duty cleanup do not leave a vehicle brake or driver task stuck',function()
  local s=setup();s.stop(100,false);s.step();s.arrive(100)
  local car=s.entities[100]
  s.handlers['prfrp:traffic:towing'](100,true);car.brake=false;s.run(5);assert(not car.brake,'tow can move the car')
  s.handlers['prfrp:traffic:towing'](100,false);s.step();assert(car.brake)
  s.handlers['prfrp:setDuty'](false);s.run(10);assert(not car.brake and not car.mission)
end)
check('human drivers remain in control and voluntary refusal starts a pursuit marker',function()
  local s=setup(true);s.stop(100,false);s.step();assert(not s.entities[100].destination)
  s.entities[100].p={x=30,y=0,z=0};s.entities[100].speed=20;s.step()
  assert(s.env.PrfGetPursuitVehicle()==100 and not s.entities[100].wander)
end)
print('PRF traffic stop and pursuit behavior passed')
