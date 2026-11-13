local root='fivem/resources/[prf]/prf_core/'
local function load(name,env) assert(loadfile(root..name,'t',env))() end
local function check(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));print('ok '..name) end
check('server dispatches PRF as default, requires the asset and preserves duty checks',function()
  local commands,events,resources={},{},{}
  local now,authorized=100,true
  local env=setmetatable({source=1,
    RegisterCommand=function(n,fn) commands[n]=fn end,
    exports=function() end,
    RegisterNetEvent=function() end,AddEventHandler=function() end,
    TriggerClientEvent=function(n,to,...) events[#events+1]={name=n,args={...}} end,
    IsPlayerAceAllowed=function() return authorized end,
    GetResourceState=function(n) return resources[n] or 'stopped' end,
    os={time=function() return now end},
  },{__index=_G})
  load('config.lua',env);load('operations_config.lua',env);load('gameplay_config.lua',env)
  dofile('tests/fivem-support.lua').progress(env)
  load('server.lua',env)
  local function count() local n=0;for _,e in ipairs(events) do if e.name=='prfrp:spawnPatrol' then n=n+1 end end;return n end
  commands.prfviatura(1,{});assert(count()==0)
  commands.prfservico(1,{});commands.prfviatura(1,{});assert(count()==0,'missing replace must not spawn a native police car')
  resources.prf_equinox_replace='started';now=now+6;commands.prfviatura(1,{})
  assert(count()==1 and events[#events].args[1]=='police')
  resources.prf_equinox_replace='stopped';resources.prf_trailblazer='started';now=now+6;commands.prfviatura(1,{})
  assert(count()==2)
  now=now+6;commands.prfviatura(1,{'adder'});assert(count()==2)
  authorized=false;now=now+6;commands.prfviatura(1,{});assert(count()==2)
end)
check('client preserves PRF paint and keeps the previous car if its asset stops',function()
  local events,resources,live={},{prf_equinox_replace='started'},{[1]=true}
  local created,painted,deleted=0,0,0
  local env=setmetatable({
    exports=function() end,
    RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) events[n]=fn end,
    RegisterCommand=function() end,RegisterKeyMapping=function() end,CreateThread=function() end,
    GetHashKey=function(n) return n end,IsModelInCdimage=function() return true end,
    RequestModel=function() end,GetGameTimer=function() return 5000 end,HasModelLoaded=function() return true end,
    IsModelAVehicle=function() return true end,PlayerPedId=function() return 1 end,
    GetEntityCoords=function() return {x=0,y=0,z=0} end,
    GetResourceState=function(n) return resources[n] or 'stopped' end,
    GetClosestVehicleNodeWithHeading=function() return true,{x=1,y=1,z=0},0 end,
    IsAnyVehicleNearPoint=function() return false end,DoesEntityExist=function(id) return live[id] end,
    CreateVehicle=function() created=created+1;local id=100+created;live[id]=true;return id end,
    DeleteVehicle=function(id) deleted=deleted+1;live[id]=nil end,
    IsEntityInAir=function() return false end,GetEntityHeightAboveGround=function() return 0 end,
    GetVehicleClass=function() return 18 end,
    SetVehicleCustomPrimaryColour=function() painted=painted+1 end,
    SetVehicleCustomSecondaryColour=function() painted=painted+1 end,
    print=function() end,
  },{__index=_G})
  for _,n in ipairs({'BeginTextCommandThefeedPost','AddTextComponentSubstringPlayerName','EndTextCommandThefeedPostTicker',
    'TriggerEvent','RequestCollisionAtCoord','SetModelAsNoLongerNeeded','SetEntityAsMissionEntity','Wait',
    'SetVehicleOnGroundProperly','SetVehicleNumberPlateText','SetVehicleDirtLevel','SetVehicleEngineOn',
    'SetVehicleHasMutedSirens','SetVehicleSiren','SetPedIntoVehicle'}) do env[n]=function() end end
  load('config.lua',env);env.Config.TeleportOnDuty=false;load('client.lua',env)
  events['prfrp:setDuty'](true);events['prfrp:spawnPatrol']('police','PRF')
  assert(created==1 and painted==0,'original PRF livery and paint')
  resources.prf_equinox_replace='stopped';events['prfrp:spawnPatrol']('police','PRF')
  assert(created==1 and deleted==0,'missing asset keeps the previous car')
  events['prfrp:spawnPatrol']('police3','PRF');assert(created==2 and painted==2)
end)
check('F9 starts with PRF on each duty shift and old panel number binds are inert',function()
  local events,commands,requests,mappings={},{},{},{}
  local env=setmetatable({
    exports=function() end,
    RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) events[n]=fn end,
    RegisterCommand=function(n,fn) commands[n]=fn end,
    RegisterKeyMapping=function(n) mappings[n]=true end,CreateThread=function() end,
    TriggerServerEvent=function(n,...) requests[#requests+1]={...} end,
    TriggerEvent=function() end,PlayerPedId=function() return 1 end,
    GetHashKey=function(n) return n end,DoesEntityExist=function() return true end,
    HasPedGotWeapon=function() return true end,SetCurrentPedWeapon=function() end,
  },{__index=_G})
  load('config.lua',env);load('keys_client.lua',env)
  events['prfrp:setDuty'](true);commands.prftecladogaragem();assert(requests[#requests][2]=='police')
  commands.prftecladogaragem();assert(requests[#requests][2]=='police3')
  events['prfrp:setDuty'](false);events['prfrp:setDuty'](true);commands.prftecladogaragem();assert(requests[#requests][2]=='police')
  local n=#requests
  commands.prfmenu();for i=1,9 do commands['prfmenuitem'..i]() end
  assert(#requests==n and not mappings.prfmenu and not mappings.prfmenuitem1)
end)
print('PRF fleet behavior passed')
