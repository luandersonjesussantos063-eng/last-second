local root='fivem/resources/[prf]/prf_core/'
local events,commands,threads,network,animations,cleared={},{},{},{},{},{}
local now,aim,nui,ally,animReady=3000,true,false,false,true
local live={[1]=true,[100]=true}
local env=setmetatable({
  RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) events[n]=fn end,
  RegisterCommand=function(n,fn) commands[n]=fn end,
  CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
  Wait=function(ms) now=now+ms;coroutine.yield() end,GetGameTimer=function() return now end,
  PlayerPedId=function() return 1 end,PlayerId=function() return 1 end,
  DoesEntityExist=function(id) return live[id] end,IsEntityAPed=function() return true end,
  IsPedHuman=function() return true end,IsEntityDead=function() return false end,
  IsPedInAnyVehicle=function() return false end,PrfIsCompanion=function() return ally end,
  GetEntityCoords=function(id) return {x=id==1 and 0 or 2,y=0,z=0} end,
  GetEntityForwardVector=function() return {x=1,y=0,z=0} end,
  GetEntityPlayerIsFreeAimingAt=function() return true,100 end,
  IsNuiFocused=function() return nui end,IsPedArmed=function() return true end,
  IsPlayerFreeAiming=function() return aim end,
  NetworkGetEntityIsNetworked=function() return true end,
  NetworkGetNetworkIdFromEntity=function(id) return id end,
  NetworkGetEntityFromNetworkId=function(id) return id end,
  NetworkHasControlOfEntity=function() return true end,
  TriggerServerEvent=function(n,...) network[#network+1]={name=n,args={...}} end,
  GetSelectedPedWeapon=function() return 'original' end,GetHashKey=function(n) return n end,
  RequestAnimDict=function() end,HasAnimDictLoaded=function() return animReady end,
  ClearPedTasks=function(ped) cleared[#cleared+1]=ped end,
  TaskPlayAnim=function(ped,dict,clip) animations[#animations+1]={ped,dict,clip} end,
  SetCurrentPedWeapon=function() end,SetBlockingOfNonTemporaryEvents=function() end,
  SetPedKeepTask=function() end,IsEntityPlayingAnim=function() return true end,
  HasPedGotWeapon=function() return true end,IsPedAPlayer=function() return false end,
  TaskWanderStandard=function() end,GetCurrentResourceName=function() return 'prf_core' end,
  TriggerEvent=function(n,...) if events[n] then events[n](...) end end,
  GetGamePool=function() return {100} end,HasEntityClearLosToEntity=function() return true end,
}, {__index=_G})
assert(loadfile(root..'config.lua','t',env))()
assert(loadfile(root..'people_client.lua','t',env))()
local function tick(n)
  for j=1,n or 1 do
    local count=#threads
    for i=1,count do
      if coroutine.status(threads[i])~='dead' then local ok,err=coroutine.resume(threads[i]);assert(ok,err) end
    end
  end
end
tick(2);assert(#network==0,'off-duty aim cannot stop a person')
events['prfrp:setDuty'](true)
nui=true;tick(8);assert(#network==0,'chat focus cannot trigger an approach')
nui=false;ally=true;tick(8);assert(#network==0,'squad cannot be held')
ally=false;tick(7);assert(#network==1 and network[1].name=='prfrp:person:approach')
events['prfrp:person:selected'](100);tick(30);assert(#network==1,'aiming at the selected person does not spam requests')
events['prfrp:person:hold'](100,1);tick(1)
assert(#animations==1 and animations[1][2]=='random@arrests@busted','hands on head animation')
aim=false;tick(3);assert(#animations==1,'person remains surrendered after lowering the weapon')
events['prfrp:person:release'](100);assert(#cleared==2,'release restores the person tasks')
animReady=false;events['prfrp:person:hold'](100,1);tick(1)
events['prfrp:person:release'](100);animReady=true;tick(2)
assert(#animations==1,'cancel during animation streaming cannot start a stale surrender')
events['prfrp:person:hold'](100,1);tick(1);assert(#animations==2)
events.onResourceStop('prf_core');assert(#cleared==4,'resource stop releases a held person')
assert(loadfile(root..'commands_client.lua','t',env))()
commands.viatura();assert(network[#network].name=='prfrp:requestAction' and network[#network].args[1]=='vehicle')
commands.revistar();assert(network[#network].name=='prfrp:ops:action' and network[#network].args[1]=='search')
commands.documento();assert(network[#network].args[1]=='documents')
assert(not commands.prfmenuitem1,'chat actions do not register numeric bindings')
print('PRF pedestrian client and chat behavior passed')
