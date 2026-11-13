local root='fivem/resources/[prf]/prf_core/'
local vector,meta
meta={__sub=function(a,b) return vector(a.x-b.x,a.y-b.y,a.z-b.z) end,
  __len=function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end}
vector=function(x,y,z) return setmetatable({x=x,y=y,z=z},meta) end
local events,threads={},{ }
local now,nextId=1000,100
local entities={ [1]={position=vector(0,0,0),car=10},[10]={position=vector(0,0,0),seats={[-1]=1}} }
local function leave(ped)
  local car=entities[ped].car
  if car then for seat,occupant in pairs(entities[car].seats) do if occupant==ped then entities[car].seats[seat]=nil end end end
  entities[ped].car=nil
end
local env=setmetatable({
  RegisterNetEvent=function(n,fn) events[n]=fn end,AddEventHandler=function(n,fn) events[n]=fn end,
  CreateThread=function(fn) threads[#threads+1]=coroutine.create(fn) end,
  Wait=function() coroutine.yield() end,GetGameTimer=function() return now end,
  PlayerPedId=function() return 1 end,GetHashKey=function(n) return n end,
  GetResourceState=function() return 'started' end,
  DoesEntityExist=function(id) return entities[id]~=nil end,IsEntityDead=function() return false end,
  IsModelInCdimage=function() return true end,IsModelAPed=function() return true end,
  HasModelLoaded=function() return true end,
  GetEntityCoords=function(id) return entities[id].position end,GetEntityHeading=function() return 0 end,
  GetVehiclePedIsIn=function(id) return entities[id].car or 0 end,
  IsPedInAnyVehicle=function(id) return entities[id].car~=nil end,
  GetVehicleMaxNumberOfPassengers=function() return 3 end,
  GetPedInVehicleSeat=function(car,seat) return entities[car].seats[seat] or 0 end,
  IsVehicleSeatFree=function(car,seat) return entities[car].seats[seat]==nil end,
  GetPedRelationshipGroupHash=function() return 1 end,GetGamePool=function() return {} end,
  CreatePed=function(_,_,x,y,z) nextId=nextId+1;entities[nextId]={position=vector(x,y,z)};return nextId end,
  SetPedIntoVehicle=function(ped,car,seat) leave(ped);entities[ped].car=car;entities[car].seats[seat]=ped end,
  TaskLeaveVehicle=function(ped) leave(ped) end,
  SetEntityCoordsNoOffset=function(ped,x,y,z) entities[ped].position=vector(x,y,z) end,
  DeletePed=function(ped) leave(ped);entities[ped]=nil end,
  GetCurrentResourceName=function() return 'prf_core' end,
}, {__index=_G})
for _,name in ipairs({'BeginTextCommandThefeedPost','AddTextComponentSubstringPlayerName','EndTextCommandThefeedPostTicker',
  'RequestModel','SetModelAsNoLongerNeeded','SetEntityAsMissionEntity','SetCurrentPedWeapon','TaskFollowToOffsetOfEntity',
  'SetPedKeepTask','SetPedRelationshipGroupHash','SetCanAttackFriendly','SetPedAsEnemy','SetBlockingOfNonTemporaryEvents',
  'SetPedFleeAttributes','SetPedDiesWhenInjured','SetPedCombatAbility','SetPedCombatMovement','SetPedCombatRange',
  'SetPedAccuracy','SetPedArmour','SetPedDropsWeaponsWhenDead','GiveWeaponToPed'}) do env[name]=function() end end
assert(loadfile(root..'config.lua','t',env))();assert(loadfile(root..'squad_client.lua','t',env))()
local function tick()
  now=now+1700
  for i=1,#threads do if coroutine.status(threads[i])~='dead' then local ok,err=coroutine.resume(threads[i]);assert(ok,err) end end
end
events['prfrp:setDuty'](true);tick();tick()
local car=entities[10]
assert(car.seats[0] and car.seats[1] and car.seats[2],'team normally fills all three passenger seats')
local displaced=car.seats[2]
env.PrfReserveCustodySeat(10)
assert(not car.seats[2] and not entities[displaced].car,'a teammate leaves the reserved rear seat')
for i=1,4 do tick() end
assert(not car.seats[2],'teammate must not take the reserved seat back')
entities[199]={position=vector(0,0,0)};env.SetPedIntoVehicle(199,10,2);tick()
assert(car.seats[2]==199 and not entities[displaced].car,'prisoner keeps the rear seat while the team follows')
leave(199);entities[199]=nil;env.PrfClearCustodySeat();tick()
assert(car.seats[2]==displaced,'teammate can return after booking or release')
local chauffeur=env.PrfGetSquadOfficer(1)
env.PrfIsChauffeur=function(ped) return ped==chauffeur end
env.PrfGetDriverVehicle=function() return 10 end
env.SetPedIntoVehicle(1,10,0);env.SetPedIntoVehicle(chauffeur,10,-1)
for i=1,4 do tick() end
assert(car.seats[-1]==chauffeur and car.seats[0]==1,'NPC driver and human passenger retain their seats')
events['prfrp:squadRally']();tick()
assert(car.seats[-1]==chauffeur,'rally must not pull the NPC driver out of the patrol')
local cleared={}
env.ClearPedTasks=function(ped) cleared[ped]=true end
env.TaskCombatPed=function() end
env.GetEntityType=function(id) return id==10 and 2 or 1 end
entities[200]={position=vector(2,0,0)}
events.entityDamaged(1,200);tick()
assert(car.seats[-1]==chauffeur and not cleared[chauffeur],'defense must not overwrite chauffeur driving tasks')
events['prfrp:person:detained'](200);tick()
assert(not cleared[chauffeur],'surrender cleanup must preserve the active driver')
print('PRF custody seat reservation behavior passed')
