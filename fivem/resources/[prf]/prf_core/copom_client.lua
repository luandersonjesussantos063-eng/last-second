local duty,epoch=false,0
local call,blip,work=nil,nil,nil
local actors,done={},{}
local spawning,registered=false,false
local pendingMode,lastStart=false,0
local function notice(text) TriggerEvent('prfrp:chatNotice','COPOM: '..text) end
local function position(anchor,offset)
  local h=math.rad(anchor.heading or 0)
  return vector3(anchor.x+math.cos(h)*offset.x-math.sin(h)*offset.y,anchor.y+math.sin(h)*offset.x+math.cos(h)*offset.y,anchor.z)
end
local function valid(token) return duty and call and epoch==token end
local function remove(e)
  if e and e~=0 and DoesEntityExist(e) and not (PrfIsPersonStopped and PrfIsPersonStopped(e)) then
    StopEntityFire(e);SetEntityAsMissionEntity(e,true,true);DeleteEntity(e)
  end
end
local function stopWork()
  if work and DoesEntityExist(work.ped) then ClearPedTasks(work.ped) end
  work=nil
end
local function clear()
  epoch=epoch+1;stopWork()
  for _,e in pairs(actors) do remove(e) end
  actors,done={},{}
  if blip then RemoveBlip(blip) end
  blip,call=nil,nil;spawning,registered=false,false;pendingMode=false
end
local function model(name,token)
  local hash=GetHashKey(name)
  if not IsModelInCdimage(hash) then return end
  RequestModel(hash);local started=GetGameTimer()
  while valid(token) and not HasModelLoaded(hash) and GetGameTimer()-started<6000 do Wait(0) end
  if valid(token) and HasModelLoaded(hash) then return hash end
  SetModelAsNoLongerNeeded(hash)
end
local function ground(at,token)
  local started=GetGameTimer()
  repeat
    RequestCollisionAtCoord(at.x,at.y,at.z)
    local ok,z=GetGroundZFor_3dCoord(at.x,at.y,at.z+4.0,false)
    if ok and math.abs(z-at.z)<2.5 then return vector3(at.x,at.y,z) end
    Wait(100)
  until not valid(token) or GetGameTimer()-started>3000
end
local function route(at,entity)
  if blip then RemoveBlip(blip) end
  blip=entity and AddBlipForEntity(entity) or AddBlipForCoord(at.x,at.y,at.z)
  SetBlipSprite(blip,1);SetBlipColour(blip,5);SetBlipRoute(blip,true)
  BeginTextCommandSetBlipName('STRING');AddTextComponentString('COPOM | '..call.definition.name);EndTextCommandSetBlipName(blip)
  SetNewWaypoint(at.x,at.y)
end
local function spawn(token)
  spawning=true
  local location=call.location
  local found,node,heading=GetClosestVehicleNodeWithHeading(location.x,location.y,location.z,1,3.0,0)
  local success=found and node and #(node-vector3(location.x,location.y,location.z))<130
  local anchor=success and {x=node.x,y=node.y,z=node.z,heading=heading} or nil
  if success then call.anchor=anchor end
  for _,def in ipairs(call.definition.actors) do
    if not success or not valid(token) then break end
    local hash=model(def.model,token)
    if not hash then success=false;break end
    local at=ground(position(anchor,def),token)
    if not at or not valid(token) then SetModelAsNoLongerNeeded(hash);success=false;break end
    local e=0
    if def.kind=='vehicle' then
      if not IsAnyVehicleNearPoint(at.x,at.y,at.z,2.5) then
        e=CreateVehicle(hash,at.x,at.y,at.z+0.4,heading+(def.turn or 0),true,false)
        if e~=0 then
          SetVehicleOnGroundProperly(e);SetVehicleNumberPlateText(e,('RP%04d'):format(call.session%10000))
          if def.damage then SetVehicleEngineHealth(e,def.damage);SetVehicleBodyHealth(e,def.damage) end
          if def.broken then SetVehicleUndriveable(e,true);SetVehicleEngineOn(e,false,true,true) end
          if def.cargo then SetVehicleDoorOpen(e,2,false,false);SetVehicleDoorOpen(e,3,false,false) end
        end
      end
    elseif def.kind=='ped' then
      local safe,p=GetSafeCoordForPed(at.x,at.y,at.z,true,16)
      if safe and #(p-at)<5 and math.abs(p.z-at.z)<2 then at=p end
      e=CreatePed(4,hash,at.x,at.y,at.z+0.5,heading,true,true)
      if e~=0 then
        SetBlockingOfNonTemporaryEvents(e,true);SetPedDropsWeaponsWhenDead(e,false)
        if def.weapon then GiveWeaponToPed(e,GetHashKey(def.weapon),120,false,true) end
        if def.driver then SetPedIntoVehicle(e,actors[def.driver],-1) end
        if not def.hostile and not def.driver then SetEntityInvincible(e,true) end
        if def.injured then
          SetEntityHealth(e,135);SetPedCanRagdoll(e,false)
          local dict='combat@damage@writhe';RequestAnimDict(dict)
          local start=GetGameTimer()
          while valid(token) and not HasAnimDictLoaded(dict) and GetGameTimer()-start<2000 do Wait(0) end
          if valid(token) and HasAnimDictLoaded(dict) then TaskPlayAnim(e,dict,'writhe_loop',8.0,-8.0,-1,1,0,false,false,false) end
        end
      end
    else
      e=CreateObjectNoOffset(hash,at.x,at.y,at.z,true,true,false)
      if e~=0 then PlaceObjectOnGroundProperly(e);FreezeEntityPosition(e,true) end
    end
    SetModelAsNoLongerNeeded(hash)
    if not valid(token) then remove(e);return end
    if e==0 then success=false;break end
    actors[def.key]=e;SetEntityAsMissionEntity(e,true,true)
  end
  if not valid(token) then return end
  if not success then TriggerServerEvent('prfrp:copom:spawnFailed',call.session);return end
  local ids={}
  for key,e in pairs(actors) do ids[key]=NetworkGetNetworkIdFromEntity(e) end
  for attempt=1,15 do
    if not valid(token) then return end
    TriggerServerEvent('prfrp:copom:register',call.session,anchor,ids)
    Wait(400)
    if registered then break end
  end
  if not valid(token) then return end
  if not registered then TriggerServerEvent('prfrp:copom:spawnFailed',call.session);return end
  for _,def in ipairs(call.definition.actors) do
    local e=actors[def.key]
    if def.fire then StartEntityFire(e) end
    if def.driver then
      local car=actors[def.driver]
      if DoesEntityExist(car) then TaskVehicleDriveWander(e,car,12.0,786603);route(GetEntityCoords(car),car) end
    elseif def.wander then TaskWanderInArea(e,anchor.x,anchor.y,anchor.z,6.0,1.0,3.0)
    elseif def.kind=='ped' and not def.injured and not def.hostile then TaskStartScenarioInPlace(e,'WORLD_HUMAN_STAND_MOBILE',0,true) end
  end
  if not call.definition.actors[1].moving then route(anchor) end
  notice('Cena localizada. '..call.definition.details)
end
PrfHasCopom=function() return call~=nil end
PrfGetCopomServiceTarget=function(kind)
  if not call or not registered then return 0 end
  local best,target=35.0,0
  for _,g in ipairs(call.definition.objectives) do
    local e=actors[g.actor]
    if g.kind==kind and not done[g.key] and e and DoesEntityExist(e) then
      local d=#(GetEntityCoords(e)-GetEntityCoords(PlayerPedId()))
      if d<best then target,best=e,d end
    end
  end
  return target
end
local function nearest(kind)
  if not call or not registered then return end
  local best,target=7.0,nil
  for _,g in ipairs(call.definition.objectives) do
    local e=actors[g.actor]
    if not done[g.key] and e and DoesEntityExist(e) and (not kind or g.kind==kind or (kind=='physical' and g.kind~='talk'))
      and ({talk=true,clear=true,cargo=true,load=true})[g.kind] then
      local ready=true;for _,key in ipairs(g.needs or {}) do if not done[key] then ready=false end end
      local d=#(GetEntityCoords(e)-GetEntityCoords(PlayerPedId()))
      if ready and d<best and d<(g.kind=='load' and 6.0 or 3.5) then target,best=g,d end
    end
  end
  return target
end
local function startWork(goal,hold)
  if not goal or work or GetGameTimer()-lastStart<1200 then return end
  lastStart=GetGameTimer();pendingMode=hold==true
  TriggerServerEvent('prfrp:copom:workStart',call.session,goal.key)
end
AddEventHandler('prfrp:copom:command',function(action)
  if action=='copomStatus' or action=='copomFinish' then TriggerServerEvent('prfrp:copom:status',action=='copomFinish')
  elseif action=='copomSecure' then TriggerEvent('prfrp:blitz:toggle')
  else
    local goal=nearest(action=='copomTalk' and 'talk' or 'physical')
    if goal then startWork(goal,false) else notice('Aproxime-se da pessoa, objeto ou traseira do caminhao indicado. Use copom para ver o que falta.') end
  end
end)
RegisterNetEvent('prfrp:copom:call',function(data)
  clear()
  if not duty or type(data)~='table' then return end
  call=data;route(data.location)
end)
RegisterNetEvent('prfrp:copom:registered',function(session) if call and call.session==session then registered=true end end)
RegisterNetEvent('prfrp:copom:progress',function(session,list)
  if not call or call.session~=session then return end
  for _,g in ipairs(list) do done[g.key]=g.done==true end
end)
RegisterNetEvent('prfrp:copom:workBegin',function(session,key,seconds,kind)
  if not call or call.session~=session or work then return end
  local goal
  for _,g in ipairs(call.definition.objectives) do if g.key==key then goal=g end end
  local target=goal and actors[goal.actor]
  if not target or not DoesEntityExist(target) then return end
  local ped,token=PlayerPedId(),epoch
  work={ped=ped,target=target,key=key,hold=pendingMode}
  local active=work
  CreateThread(function()
    TaskTurnPedToFaceEntity(ped,target,800);Wait(800)
    if not valid(token) or work~=active then return end
    if kind=='talk' then
      if not (PrfIsPersonStopped and PrfIsPersonStopped(target)) then TaskTurnPedToFaceEntity(target,ped,seconds*1000) end
      TaskStartScenarioInPlace(ped,'WORLD_HUMAN_STAND_MOBILE',0,true)
    else TaskStartScenarioInPlace(ped,'CODE_HUMAN_MEDIC_KNEEL',0,true) end
    local started=GetGameTimer()
    while valid(token) and work==active and GetGameTimer()-started<seconds*1000 do
      if IsEntityDead(ped) or PlayerPedId()~=ped or IsPedInAnyVehicle(ped,false) or not DoesEntityExist(target)
        or #(GetEntityCoords(ped)-GetEntityCoords(target))>(kind=='load' and 6 or 3.5)
        or (active.hold and not IsControlPressed(0,38)) then
        TriggerServerEvent('prfrp:copom:workCancel',session,key);stopWork();notice('Acao interrompida. Aproxime-se e tente novamente.');return
      end
      DisablePlayerFiring(PlayerId(),true)
      BeginTextCommandDisplayHelp('STRING');AddTextComponentSubstringPlayerName(('COPOM | %s | %d%%'):format(goal.label,math.min(100,math.floor((GetGameTimer()-started)/(seconds*10)))))
      EndTextCommandDisplayHelp(0,false,true,-1);Wait(0)
    end
    if valid(token) and work==active then stopWork();TriggerServerEvent('prfrp:copom:workFinish',session,key) end
  end)
end)
RegisterNetEvent('prfrp:copom:closeLoad',function(id)
  local car=NetworkGetEntityFromNetworkId(id)
  if car~=0 and DoesEntityExist(car) and NetworkHasControlOfEntity(car) then SetVehicleDoorShut(car,2,false);SetVehicleDoorShut(car,3,false) end
end)
RegisterNetEvent('prfrp:setDuty',function(value) duty=value==true;if not duty then clear() end end)
AddEventHandler('prfrp:baseArrival',function() if call then clear();TriggerServerEvent('prfrp:requestAction','cancel') end end)
CreateThread(function()
  while true do
    local wait=750
    if duty and call then
      local ped=PlayerPedId();local p=GetEntityCoords(ped)
      if IsEntityDead(ped) then TriggerServerEvent('prfrp:requestAction','cancel');clear()
      elseif not spawning and #(p-vector3(call.location.x,call.location.y,call.location.z))<150 then
        local token=epoch;CreateThread(function() spawn(token) end);spawning=true
      elseif registered and not IsNuiFocused() then
        wait=150
        local nextGoal
        for _,g in ipairs(call.definition.objectives) do if not done[g.key] then nextGoal=g;break end end
        if nextGoal and not work then
          BeginTextCommandDisplayHelp('STRING');AddTextComponentSubstringPlayerName('COPOM | '..nextGoal.label..' | T > copom')
          EndTextCommandDisplayHelp(0,false,true,-1)
        end
        if call.definition.safe then
          local safe=position(call.anchor,call.definition.safe)
          DrawMarker(1,safe.x,safe.y,safe.z-1,0,0,0,0,0,0,6.0,6.0,1.0,50,190,100,110,false,false,2,false,nil,nil,false)
        end
        local goal=not work and nearest()
        if goal and IsControlPressed(0,38) and not IsPedInAnyVehicle(ped,false) then startWork(goal,true) end
        for _,def in ipairs(call.definition.actors) do
          local e=actors[def.key]
          if def.hostile and e and DoesEntityExist(e) and not IsEntityDead(e) and NetworkHasControlOfEntity(e)
            and not (PrfIsPersonStopped and PrfIsPersonStopped(e)) and #(GetEntityCoords(e)-p)<60 and not IsPedInCombat(e,ped) then
            SetPedCombatAbility(e,1);SetPedCombatMovement(e,2);SetPedCombatRange(e,1);SetPedAccuracy(e,22)
            SetPedFleeAttributes(e,0,false);TaskCombatPed(e,ped,0,16)
          end
        end
      end
    end
    Wait(wait)
  end
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then clear();duty=false end end)
