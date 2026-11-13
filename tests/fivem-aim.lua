local root='fivem/resources/[prf]/prf_core/'
local events,commands,threads,mapping={},{},{},{}
local forced,nui,pause,armed,normal=false,false,false,true,0
local env=setmetatable({
  RegisterCommand=function(n,fn) commands[n]=fn end,
  exports=function() end,
    RegisterNetEvent=function(n,fn) events[n]=fn end,
  AddEventHandler=function(n,fn) events[n]=fn end,
  RegisterKeyMapping=function(n,_,_,key) mapping[n]=key end,
  CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
  Wait=function() coroutine.yield() end,
  PlayerId=function() return 1 end,PlayerPedId=function() return 1 end,
  IsNuiFocused=function() return nui end,IsPauseMenuActive=function() return pause end,
  IsEntityDead=function() return false end,IsPedArmed=function() return armed end,
  SetPlayerForcedAim=function(_,value) forced=value end,
  SetControlNormal=function(_,control,value) assert(control==25 and value==1);normal=normal+1 end,
  DisableControlAction=function(_,control) assert(control==20) end,
  GetCurrentResourceName=function() return 'prf_core' end,
  DoesEntityExist=function() return true end,
}, {__index=_G})
assert(loadfile(root..'config.lua','t',env))();assert(loadfile(root..'keys_client.lua','t',env))()
local function tick() local ok,err=coroutine.resume(threads[1]);assert(ok,err) end
assert(mapping['+prfmirar']=='Z')
commands['+prfmirar']();tick();assert(forced and normal==1,'Z holds aim')
nui=true;tick();assert(not forced,'typing in chat clears forced aim')
nui=false;tick();assert(forced,'held Z resumes when chat closes')
commands['-prfmirar']();tick();assert(not forced,'releasing Z releases aim')
armed=false;commands['+prfmirar']();tick();assert(not forced,'no forced aim without a firearm')
armed=true;pause=true;tick();assert(not forced,'pause blocks aim')
pause=false;tick();assert(forced)
events.onResourceStop('prf_core');assert(not forced);tick();assert(not forced,'resource stop cannot leave sticky aim')
print('PRF Z aim behavior passed')
