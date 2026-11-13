local root='fivem/resources/[prf]/prf_core/'
local events,commands,threads,network,animations,cleared={},{},{},{},{},{}
local now,aim,nui,ally,animReady=3000,true,false,false,true
local live={[1]=true,[100]=true,[200]=true}
local cuffs,vehicle,enteredSeat,following=false,0,nil,0
local custodyBlips,removedCustody=0,0
local env=setmetatable({
  exports=function() end,
    RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) events[n]=fn end,
  RegisterCommand=function(n,fn) commands[n]=fn end,
  CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
  Wait=function(ms) now=now+ms;coroutine.yield() end,GetGameTimer=function() return now end,
  PlayerPedId=function() return 1 end,PlayerId=function() return 1 end,
  DoesEntityExist=function(id) return live[id] end,IsEntityAPed=function() return true end,
  IsPedHuman=function() return true end,IsEntityDead=function() return false end,
  IsPedInAnyVehicle=function(id) return id==100 and vehicle~=0 end,PrfIsCompanion=function() return ally end,
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
  TaskPlayAnim=function(ped,dict,clip,_,_,_,flag) animations[#animations+1]={ped,dict,clip,flag} end,
  SetCurrentPedWeapon=function() end,SetBlockingOfNonTemporaryEvents=function() end,
  SetPedKeepTask=function() end,IsEntityPlayingAnim=function() return true end,
  SetEnableHandcuffs=function(_,value) cuffs=value end,SetPedCanSwitchWeapon=function() end,
  GetPlayerFromServerId=function() return 1 end,GetPlayerPed=function() return 1 end,
  TaskFollowToOffsetOfEntity=function() following=following+1 end,
  GetVehiclePedIsIn=function(id) return id==100 and vehicle or 0 end,
  GetVehicleMaxNumberOfPassengers=function() return 3 end,
  IsVehicleSeatFree=function(_,seat) return seat==2 end,
  TaskEnterVehicle=function(_,car,_,seat) vehicle=car;enteredSeat=seat end,
  TaskLeaveVehicle=function() vehicle=0 end,
  AddBlipForCoord=function() custodyBlips=custodyBlips+1;return custodyBlips end,
  RemoveBlip=function() removedCustody=removedCustody+1 end,
  SetBlipSprite=function() end,SetBlipColour=function() end,SetBlipRoute=function() end,
  BeginTextCommandSetBlipName=function() end,AddTextComponentString=function() end,EndTextCommandSetBlipName=function() end,
  HasPedGotWeapon=function() return true end,IsPedAPlayer=function() return false end,
  TaskWanderStandard=function() end,GetCurrentResourceName=function() return 'prf_core' end,
  TriggerEvent=function(n,...) if events[n] then events[n](...) end end,
  GetGamePool=function() return {100} end,HasEntityClearLosToEntity=function() return true end,
}, {__index=_G})
assert(loadfile(root..'config.lua','t',env))()
assert(loadfile(root..'gameplay_config.lua','t',env))()
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
events['prfrp:person:hold'](100,1,{mode='prone',revision=10});tick(1)
assert(animations[#animations][2]=='missfbi3_sniping','prone order uses a lying down pose')
local n=#animations
events['prfrp:person:hold'](100,1,{mode='head',revision=9});tick(1);assert(#animations==n,'stale orders cannot overwrite a new posture')
events['prfrp:person:hold'](100,1,{mode='cuffed',cuffed=true,revision=11});tick(1)
assert(cuffs and animations[#animations][2]=='mp_arresting')
events['prfrp:person:hold'](100,1,{mode='follow',cuffed=true,revision=12});tick(1)
assert(following>0 and cuffs and animations[#animations][4]==49,'cuffed escort leaves legs free to walk')
events['prfrp:person:hold'](100,1,{mode='enter',cuffed=true,vehicle=200,revision=13});tick(1)
assert(vehicle==200 and enteredSeat==2,'transport selects an available rear passenger seat')
events['prfrp:person:hold'](100,1,{mode='exit',cuffed=true,revision=14});tick(1)
assert(vehicle==0 and cuffs)
events['prfrp:person:custody']({x=1,y=2,z=3});assert(custodyBlips==1)
local beforeBooking=#cleared
events['prfrp:person:booked'](100)
assert(#cleared==beforeBooking and not env.PrfIsPersonStopped(100),'booked NPC must not resume wandering')
events['prfrp:person:custody'](false);assert(removedCustody==1)
events['prfrp:person:hold'](100,1,{mode='cuffed',cuffed=true,revision=20});tick(1)
local beforeStop=#cleared
events.onResourceStop('prf_core');assert(#cleared==beforeStop+1 and not cuffs,'resource stop releases cuffs and tasks')
assert(loadfile(root..'commands_client.lua','t',env))()
commands.viatura();assert(network[#network].name=='prfrp:requestAction' and network[#network].args[1]=='vehicle')
commands.revistar();assert(network[#network].name=='prfrp:ops:action' and network[#network].args[1]=='search')
commands.documento();assert(network[#network].args[1]=='documents')
commands.registrarprisao();assert(network[#network].name=='prfrp:person:bookArrest')
commands.prisoes();assert(network[#network].name=='prfrp:person:arrestHistory')
assert(not commands.prfmenuitem1,'chat actions do not register numeric bindings')
print('PRF pedestrian client and chat behavior passed')
