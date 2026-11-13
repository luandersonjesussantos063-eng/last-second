local root='fivem/resources/[prf]/prf_core/'
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
local function setup()
  local serverEvents,clientEvents,events,threads={},{},{},{}
  local now,nextId,duty,blocked,modelsReady,pedFailures=1000,100,true,false,true,0
  local entities={ [1]={kind=1,model='player',p={x=0,y=0,z=0},owner=1},
    [10]={kind=2,model='police',p={x=0,y=0,z=0},owner=1,colour={70,71},extraColour={5,6},
      primary={1,2,3},secondary={4,5,6},livery=3,liveryMod=2,tint=1,extras={[2]=true,[4]=false}} }
  local deleted={}
  local function addHandler(list,n,fn)
    local prev=list[n];list[n]=function(...) if prev then prev(...) end;fn(...) end
  end
  local shared={
    GetHashKey=function(n) return n end,GetPlayerPed=function() return 1 end,
    DoesEntityExist=function(id) return entities[id]~=nil end,
    GetEntityType=function(id) return entities[id].kind end,
    GetEntityModel=function(id) return entities[id].model end,
    GetEntityCoords=function(id) return entities[id].p end,
    GetVehiclePedIsIn=function(id) return id==1 and 10 or (entities[id] and entities[id].car or 0) end,
    NetworkGetEntityFromNetworkId=function(id) return entities[id] and id or 0 end,
    NetworkGetNetworkIdFromEntity=function(id) return entities[id] and id or 0 end,
    NetworkGetEntityOwner=function(id) return entities[id].owner end,
    DeleteEntity=function(id) deleted[id]=true;entities[id]=nil end,
    GetResourceState=function() return 'started' end,
    GetCurrentResourceName=function() return 'prf_core' end,
  }
  local function environment(extra)
    local env=setmetatable(extra,{__index=function(_,key) return shared[key] or _G[key] end})
    assert(loadfile(root..'config.lua','t',env))();return env
  end
  local client
  local server=environment({source=1,
    RegisterNetEvent=function(n,fn) serverEvents[n]=fn end,
    AddEventHandler=function(n,fn) addHandler(serverEvents,n,fn) end,
    PrfHasDuty=function() return duty end,
    TriggerClientEvent=function(n,_,...)
      events[#events+1]={name=n,args={...}}
      if clientEvents[n] then clientEvents[n](...) end
    end,
  })
  assert(loadfile(root..'backup_server.lua','t',server))()
  client=environment({
    RegisterNetEvent=function(n,fn) clientEvents[n]=fn end,
    AddEventHandler=function(n,fn) addHandler(clientEvents,n,fn) end,
    TriggerEvent=function() end,
    TriggerServerEvent=function(n,...)
      if n=='prfrp:ops:action' then
        local action,data=...
        if action=='backup' then server.PrfRequestBackup(1,data)
        elseif action=='dismissBackup' then server.PrfDismissBackup(1) end
      elseif serverEvents[n] then serverEvents[n](...) end
    end,
    CreateThread=function(fn) threads[#threads+1]={co=coroutine.create(fn),due=now} end,
    Wait=function(ms) coroutine.yield(ms) end,GetGameTimer=function() return now end,
    PlayerPedId=function() return 1 end,
    IsModelInCdimage=function() return true end,HasModelLoaded=function() return modelsReady end,
    GetClosestVehicleNodeWithHeading=function(x,y,z) return not blocked,{x=x,y=y,z=z},0 end,
    IsAnyVehicleNearPoint=function() return false end,HasCollisionLoadedAroundEntity=function() return true end,
    CreateVehicle=function(model,x,y,z)
      nextId=nextId+1;entities[nextId]={kind=2,model=model,p={x=x,y=y,z=z},owner=1,extras={}};return nextId
    end,
    CreatePed=function(_,model,x,y,z)
      if pedFailures>0 then pedFailures=pedFailures-1;return 0 end
      nextId=nextId+1;entities[nextId]={kind=1,model=model,p={x=x,y=y,z=z},owner=1};return nextId
    end,
    SetPedIntoVehicle=function(ped,car) entities[ped].car=car end,
    TaskVehicleDriveToCoordLongrange=function(_,car,_,_,_,speed)
      entities[car].p={x=10,y=0,z=0};entities[car].routeSpeed=speed
    end,
    TaskLeaveVehicle=function(ped) entities[ped].car=0 end,
    IsEntityDead=function() return false end,
    IsPedInAnyVehicle=function(ped) return (entities[ped].car or 0)~=0 end,
    GetPedRelationshipGroupHash=function() return 1 end,
    GetVehicleColours=function(car) return table.unpack(entities[car].colour) end,
    GetVehicleExtraColours=function(car) return table.unpack(entities[car].extraColour) end,
    GetVehicleLivery=function(car) return entities[car].livery end,
    GetVehicleMod=function(car) return entities[car].liveryMod end,
    GetVehicleWindowTint=function(car) return entities[car].tint end,
    GetIsVehiclePrimaryColourCustom=function() return true end,
    GetIsVehicleSecondaryColourCustom=function() return true end,
    GetVehicleCustomPrimaryColour=function(car) return table.unpack(entities[car].primary) end,
    GetVehicleCustomSecondaryColour=function(car) return table.unpack(entities[car].secondary) end,
    DoesExtraExist=function(_,i) return i==2 or i==4 end,
    IsVehicleExtraTurnedOn=function(car,i) return entities[car].extras[i] end,
    SetVehicleColours=function(car,...) entities[car].colour={...} end,
    SetVehicleExtraColours=function(car,...) entities[car].extraColour={...} end,
    SetVehicleCustomPrimaryColour=function(car,...) entities[car].primary={...} end,
    SetVehicleCustomSecondaryColour=function(car,...) entities[car].secondary={...} end,
    SetVehicleLivery=function(car,value) entities[car].livery=value end,
    SetVehicleMod=function(car,_,value) entities[car].liveryMod=value end,
    SetVehicleWindowTint=function(car,value) entities[car].tint=value end,
    SetVehicleExtra=function(car,i,disabled) entities[car].extras[i]=not disabled end,
  })
  for _,name in ipairs({'RequestModel','SetModelAsNoLongerNeeded','SetEntityAsMissionEntity','RequestCollisionAtCoord',
    'FreezeEntityPosition','SetVehicleOnGroundProperly','SetVehicleModKit','SetVehicleNumberPlateText','SetVehicleDirtLevel',
    'SetVehicleEngineOn','SetPedRelationshipGroupHash','SetCanAttackFriendly','SetBlockingOfNonTemporaryEvents',
    'SetPedFleeAttributes','SetPedDropsWeaponsWhenDead','GiveWeaponToPed','SetVehicleHasMutedSirens','SetVehicleSiren',
    'TaskVehicleTempAction','SetCurrentPedWeapon','TaskFollowToOffsetOfEntity','SetPedKeepTask'}) do client[name]=function() end end
  assert(loadfile(root..'backup_client.lua','t',client))()
  clientEvents['prfrp:setDuty'](true)
  local function step(ms)
    now=now+(ms or 100)
    local n=#threads
    for i=1,n do
      local t=threads[i]
      if coroutine.status(t.co)~='dead' and t.due<=now then
        local ok,wait=coroutine.resume(t.co);assert(ok,wait);t.due=now+math.max(1,wait or 0)
      end
    end
  end
  local function count(kind)
    local n=0;for id,e in pairs(entities) do if id~=1 and id~=10 and e.kind==kind then n=n+1 end end;return n
  end
  return {server=server,client=client,events=events,entities=entities,deleted=deleted,
    request=function(n) clientEvents['prfrp:backup:request'](n) end,
    run=function(n) for i=1,n or 1 do step() end end,step=step,count=count,
    block=function(value) blocked=value end,models=function(value) modelsReady=value end,
    failPeds=function(n) pedFailures=n end,
    dismiss=function() server.PrfDismissBackup(1) end,
    register=function(request,car,peds) serverEvents['prfrp:ops:registerBackup'](request,car,peds) end,
    dropped=function() serverEvents.playerDropped() end,
    endDuty=function() duty=false;clientEvents['prfrp:setDuty'](false);serverEvents['prfrp:ops:dutyEnded'](1) end }
end
check('repeated calls add all requested PRF units and copy the player vehicle appearance',function()
  local s=setup();s.request(2);s.request(3);s.step()
  assert(s.count(2)==1,'units stream gradually')
  s.run(100);assert(s.count(2)==5 and s.count(1)==10)
  for id,car in pairs(s.entities) do if id~=10 and car.kind==2 then
    assert(car.model=='police' and car.colour[1]==70 and car.colour[2]==71)
    assert(car.primary[3]==3 and car.secondary[3]==6 and car.livery==3 and car.liveryMod==2 and car.tint==1)
    assert(car.extras[2] and car.extras[4]==false)
  end end
  s.request(2);s.run(50);assert(s.count(2)==7,'new requests preserve every previous unit')
  s.dismiss();s.run(20);assert(s.count(2)==0 and s.count(1)==0 and s.entities[10] and s.entities[1])
end)
check('blocked roads queue requests and failure of one unit preserves existing units',function()
  local s=setup();s.block(true);s.request(2);s.run(25);assert(s.count(2)==0)
  s.block(false);s.run(20);assert(s.count(2)>=1)
  s.failPeds(1);s.request(1);s.run(90);assert(s.count(2)==3 and s.count(1)==6)
end)
check('dismissal and duty end cancel model loading and prevent delayed spawning',function()
  local s=setup();s.models(false);s.request(2000);s.run(2);s.dismiss();s.models(true);s.run(20)
  assert(s.count(2)==0)
  s.request(1);s.run(30);assert(s.count(2)==1)
  s.endDuty();s.run(30);assert(s.count(2)==0 and s.count(1)==0)
end)
check('units called during pursuit stay in their vehicles and track the fleeing target',function()
  local s=setup();s.client.PrfGetPursuitVehicle=function() return 10 end
  s.request(1);s.run(50)
  for id,entity in pairs(s.entities) do
    if id~=1 and entity.kind==1 then assert(entity.car and entity.car~=0) end
    if id~=10 and entity.kind==2 then assert(entity.routeSpeed==25) end
  end
  s.client.PrfGetPursuitVehicle=function() return 0 end;s.run(50)
  for id,entity in pairs(s.entities) do if id~=1 and entity.kind==1 then assert(entity.car==0) end end
end)
check('server registers only requested owned police units and cleans them on disconnect',function()
  local forged=setup();forged.request(1)
  local request=forged.events[1].args[1].request
  forged.register(request,10,{1,1})
  forged.dismiss();assert(forged.entities[10] and forged.entities[1],'forged registration must not authorize deleting player or source vehicle')
  local s=setup();s.request(2);s.run(70);assert(s.count(2)==2)
  s.dropped();s.run(20);assert(s.count(2)==0 and s.entities[10] and s.entities[1])
  local before=#s.events;s.server.PrfRequestBackup(1,{count=-2});assert(#s.events==before+1)
end)
print('PRF multiple backup behavior passed')
