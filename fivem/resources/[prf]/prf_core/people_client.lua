local duty, selected, pending, lastAttempt = false, 0, 0, 0
local held = {}
local custodyBlip
local function clearCustody(keepSeat)
  if custodyBlip then RemoveBlip(custodyBlip);custodyBlip=nil end
  if not keepSeat and PrfClearCustodySeat then PrfClearCustodySeat() end
end
RegisterNetEvent('prfrp:person:reserveSeat',function(id)
  local car=NetworkGetEntityFromNetworkId(id)
  if car~=0 and DoesEntityExist(car) and PrfReserveCustodySeat then PrfReserveCustodySeat(car) end
end)
RegisterNetEvent('prfrp:person:custody',function(point)
  clearCustody(type(point)=='table')
  if type(point)~='table' then return end
  custodyBlip=AddBlipForCoord(point.x,point.y,point.z)
  SetBlipSprite(custodyBlip,60);SetBlipColour(custodyBlip,3);SetBlipRoute(custodyBlip,true)
  BeginTextCommandSetBlipName('STRING');AddTextComponentString('PRF | Entrega de preso');EndTextCommandSetBlipName(custodyBlip)
end)
RegisterNetEvent('prfrp:person:booked',function(id)
  -- A entrega remove o NPC no servidor; nao restaura suas tarefas de pedestre.
  held[id]=nil
  if selected==id then selected=0 end
end)
local dict, clip = 'random@arrests@busted', 'idle_a'
local poses={head={dict,clip},handsup={'random@mugging3','handsup_standing_base'},
  prone={'missfbi3_sniping','prone_dave'},kneel={'random@arrests','kneeling_arrest_idle'},
  cuffed={'mp_arresting','idle'}}
local function notice(text) TriggerEvent('prfrp:chatNotice',text) end
local function eligible(target)
  return target and target ~= 0 and target ~= PlayerPedId() and DoesEntityExist(target)
    and IsEntityAPed(target) and IsPedHuman(target) and not IsEntityDead(target)
    and not IsPedInAnyVehicle(target,false)
    and not (PrfIsCompanion and PrfIsCompanion(target))
    and not (PrfIsBackup and PrfIsBackup(target))
    and not (PrfIsServiceStaff and PrfIsServiceStaff(target))
end
local function distance(target)
  local p,q = GetEntityCoords(PlayerPedId()),GetEntityCoords(target)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2
end
local function aimedPerson()
  local found,target = GetEntityPlayerIsFreeAimingAt(PlayerId())
  if found and eligible(target) and distance(target) <= 15^2 then return target end
end
local function approach(target)
  if not duty or pending ~= 0 or not eligible(target) then return end
  if PrfCanApproachPerson and not PrfCanApproachPerson() then return end
  if IsPedInAnyVehicle(PlayerPedId(),false) then return end
  if selected ~= 0 and NetworkGetEntityFromNetworkId(selected) == target then return end
  if GetGameTimer()-lastAttempt < 2000 then return end
  lastAttempt,pending = GetGameTimer(),target
  CreateThread(function()
    if not NetworkGetEntityIsNetworked(target) then
      NetworkRegisterEntityAsNetworked(target)
      Wait(150) -- permite replicar o NPC local antes de enviar seu ID ao servidor
    end
    local started = GetGameTimer()
    local id = 0
    repeat
      if not duty or pending ~= target or not eligible(target) then pending=0; return end
      id = NetworkGetNetworkIdFromEntity(target)
      if id ~= 0 then break end
      Wait(50)
    until GetGameTimer()-started > 1500
    pending=0
    if id == 0 then notice('Pessoa ainda carregando. Aproxime-se e tente novamente.'); return end
    TriggerServerEvent('prfrp:person:approach',id)
  end)
end
AddEventHandler('prfrp:person:approachCommand',function()
  if PrfDriverIsPassenger and PrfDriverIsPassenger() then TriggerEvent('prfrp:driver:approach');return end
  if not duty then notice('Use T > servico para entrar em servico.'); return end
  local target = aimedPerson()
  if not target and not IsPedInAnyVehicle(PlayerPedId(),false) then
    local pos,forward = GetEntityCoords(PlayerPedId()),GetEntityForwardVector(PlayerPedId())
    local best=6^2
    for _,ped in ipairs(GetGamePool('CPed')) do
      if eligible(ped) and HasEntityClearLosToEntity(PlayerPedId(),ped,17) then
        local p=GetEntityCoords(ped)
        local d=(p.x-pos.x)^2+(p.y-pos.y)^2+(p.z-pos.z)^2
        if d<best and (p.x-pos.x)*forward.x+(p.y-pos.y)*forward.y>0 then target,best=ped,d end
      end
    end
  end
  if target then approach(target)
  else TriggerEvent('prfrp:ops:command','stop') end
end)

RegisterNetEvent('prfrp:person:selected',function(id)
  selected = type(id)=='number' and id or 0
  if selected==0 and PrfClearCustodySeat then PrfClearCustodySeat() end
  if selected~=0 then TriggerEvent('prfrp:person:detained',NetworkGetEntityFromNetworkId(selected)) end
end)
PrfHasPersonStop=function() return selected~=0 end
PrfIsPersonStopped = function(ped)
  if selected~=0 and NetworkGetEntityFromNetworkId(selected)==ped then return true end
  for _,state in pairs(held) do if state.ped==ped then return true end end
  return false
end
exports('IsPersonStopped',function(ped) return PrfIsPersonStopped(ped) end)
AddEventHandler('prfrp:person:orderCommand',function(action)
  if not duty then notice('Digite servico no T primeiro.');return end
  if selected==0 then
    if action=='exit' then TriggerEvent('prfrp:ops:command','exit')
    else notice('Aborde uma pessoa primeiro, apontando a arma ou usando abordar.') end
    return
  end
  local data={}
  if action=='enter' and PrfGetPatrolVehicle then
    local car=PrfGetPatrolVehicle()
    if car~=0 then data.vehicle=NetworkGetNetworkIdFromEntity(car) end
  end
  TriggerServerEvent('prfrp:person:order',action,data)
end)
local function release(id)
  local state=held[id]
  held[id]=nil
  if not state or not state.applied then return end
  local ped=state.ped
  if DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) and not IsEntityDead(ped) then
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped,false)
    SetPedCanSwitchWeapon(ped,true)
    SetBlockingOfNonTemporaryEvents(ped,false)
    SetPedKeepTask(ped,false)
    if state.weapon and HasPedGotWeapon(ped,state.weapon,false) then SetCurrentPedWeapon(ped,state.weapon,true) end
    if not IsPedAPlayer(ped) then TaskWanderStandard(ped,10.0,10) end
  end
end
RegisterNetEvent('prfrp:person:release',release)
local function officerPed(state)
  local player=GetPlayerFromServerId(state.officer)
  return player~=-1 and GetPlayerPed(player) or 0
end
local function current(id,state,revision)
  return held[id]==state and state.revision==revision and DoesEntityExist(state.ped) and not IsEntityDead(state.ped)
end
local function playPose(id,state,revision,pose,flag)
  RequestAnimDict(pose[1])
  local started=GetGameTimer()
  while current(id,state,revision) and not HasAnimDictLoaded(pose[1]) and GetGameTimer()-started<3000 do Wait(50) end
  if not current(id,state,revision) then return end
  state.pose,state.poseFlag=pose,flag or 1
  if HasAnimDictLoaded(pose[1]) then
    TaskPlayAnim(state.ped,pose[1],pose[2],8.0,-8.0,-1,state.poseFlag,0.0,false,false,false)
  else TaskHandsUp(state.ped,-1,PlayerPedId(),-1,true) end
end
RegisterNetEvent('prfrp:person:hold',function(id,officer,order)
  order=type(order)=='table' and order or {mode='head',cuffed=false}
  local state=held[id] or {officer=officer}
  local revision=order.revision or (state.revision or 0)+1
  if state.revision and revision<=state.revision then return end
  state.officer,state.revision,state.mode,state.cuffed=officer,revision,order.mode,order.cuffed==true
  state.pose=nil
  held[id]=state
  CreateThread(function()
    local started=GetGameTimer()
    local ped=0
    repeat
      if held[id]~=state or state.revision~=revision then return end
      ped=NetworkGetEntityFromNetworkId(id)
      if ped~=0 and DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then break end
      Wait(50)
    until GetGameTimer()-started>3000
    if ped==0 or not DoesEntityExist(ped) or not NetworkHasControlOfEntity(ped)
      or IsEntityDead(ped) then held[id]=nil; return end
    state.ped=ped
    if not state.applied then state.weapon=GetSelectedPedWeapon(ped) end
    if not current(id,state,revision) then return end
    state.applied=true
    ClearPedTasks(ped)
    SetCurrentPedWeapon(ped,GetHashKey('WEAPON_UNARMED'),true)
    SetBlockingOfNonTemporaryEvents(ped,true)
    SetPedKeepTask(ped,true)
    SetEnableHandcuffs(ped,state.cuffed)
    SetPedCanSwitchWeapon(ped,not state.cuffed)
    if state.mode=='enter' then
      local car=order.vehicle and NetworkGetEntityFromNetworkId(order.vehicle) or 0
      if car==0 or not DoesEntityExist(car) then TriggerServerEvent('prfrp:person:orderFailed',id,revision);return end
      if GetVehiclePedIsIn(ped,false)~=car then
        local seat,max=-2,GetVehicleMaxNumberOfPassengers(car)
        local preferred=max-1
        started=GetGameTimer()
        while current(id,state,revision) and not IsVehicleSeatFree(car,preferred,true)
          and GetGameTimer()-started<3000 do Wait(100) end
        if not current(id,state,revision) then return end
        for i=max-1,1,-1 do if IsVehicleSeatFree(car,i,true) then seat=i;break end end
        if seat==-2 and max==1 and IsVehicleSeatFree(car,0,true) then seat=0 end
        if seat==-2 then TriggerServerEvent('prfrp:person:orderFailed',id,revision);return end
        TaskEnterVehicle(ped,car,8000,seat,1.5,1,0)
        started=GetGameTimer()
        while current(id,state,revision) and GetVehiclePedIsIn(ped,false)~=car and GetGameTimer()-started<8000 do Wait(200) end
        if not current(id,state,revision) then return end
        if GetVehiclePedIsIn(ped,false)~=car then TriggerServerEvent('prfrp:person:orderFailed',id,revision);return end
      end
      state.mode='seated'
    elseif state.mode=='exit' then
      local car=GetVehiclePedIsIn(ped,false)
      if car~=0 then TaskLeaveVehicle(ped,car,0) end
      started=GetGameTimer()
      while current(id,state,revision) and IsPedInAnyVehicle(ped,false) and GetGameTimer()-started<8000 do Wait(200) end
      if not current(id,state,revision) then return end
      if IsPedInAnyVehicle(ped,false) then TriggerServerEvent('prfrp:person:orderFailed',id,revision);return end
      state.mode=state.cuffed and 'cuffed' or 'head'
      playPose(id,state,revision,poses[state.mode])
    elseif state.mode=='follow' then
      local leader=officerPed(state)
      if leader~=0 then TaskFollowToOffsetOfEntity(ped,leader,0.0,-1.5,0.0,1.5,-1,1.2,true) end
      state.nextTask=GetGameTimer()+4000
      if state.cuffed then playPose(id,state,revision,poses.cuffed,49) end
    elseif poses[state.mode] then playPose(id,state,revision,poses[state.mode])
    elseif state.cuffed then playPose(id,state,revision,poses.cuffed)
    else TaskStandStill(ped,-1) end
  end)
end)
RegisterNetEvent('prfrp:person:leaveVehicle',function(id,carId,officer)
  CreateThread(function()
    local ped,car=NetworkGetEntityFromNetworkId(id),NetworkGetEntityFromNetworkId(carId)
    if ped==0 or car==0 or not DoesEntityExist(ped) or not NetworkHasControlOfEntity(ped)
      or GetVehiclePedIsIn(ped,false)~=car then return end
    TaskLeaveVehicle(ped,car,0)
    local started=GetGameTimer()
    while DoesEntityExist(ped) and IsPedInAnyVehicle(ped,false) and GetGameTimer()-started<8000 do Wait(200) end
    if DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) then
      local player=GetPlayerFromServerId(officer)
      TaskHandsUp(ped,15000,player~=-1 and GetPlayerPed(player) or PlayerPedId(),-1,true)
    end
  end)
end)
RegisterNetEvent('prfrp:person:report',function(id,action,lines)
  if not duty or id~=selected or type(lines)~='table' then return end
  if action=='documents' or action=='breathalyzer' then
    TriggerEvent('prfrp:tablet:document',lines);return
  end
  for _,line in ipairs(lines) do notice(line) end
  local ped=PlayerPedId()
  if not IsPedInAnyVehicle(ped,false) then
    CreateThread(function()
      local scenario='CODE_HUMAN_MEDIC_KNEEL'
      TaskStartScenarioInPlace(ped,scenario,0,true)
      Wait(1800)
      if DoesEntityExist(ped) and IsPedUsingScenario(ped,scenario) then ClearPedTasks(ped) end
    end)
  end
end)
RegisterNetEvent('prfrp:setDuty',function(value)
  duty=value==true
  if not duty then selected,pending=0,0;clearCustody() end
end)
AddEventHandler('prfrp:baseArrival',function()
  selected,pending=0,0
  clearCustody()
  TriggerServerEvent('prfrp:person:cancel')
end)
CreateThread(function()
  local candidate,since=0,0
  while true do
    local wait=500
    if duty and not IsNuiFocused() and not IsEntityDead(PlayerPedId())
      and not IsPedInAnyVehicle(PlayerPedId(),false)
      and IsPedArmed(PlayerPedId(),4) and IsPlayerFreeAiming(PlayerId()) then
      wait=125
      local target=aimedPerson()
      if target~=candidate then candidate,since=target,GetGameTimer()
      elseif target and GetGameTimer()-since>=500 then approach(target) end
    else candidate,since=0,0 end
    for id,state in pairs(held) do
      local ped=state.ped
      if ped and (not DoesEntityExist(ped) or IsEntityDead(ped)) then held[id]=nil
      elseif ped and state.applied and NetworkHasControlOfEntity(ped) then
        local pose=state.pose
        if pose and HasAnimDictLoaded(pose[1]) and not IsEntityPlayingAnim(ped,pose[1],pose[2],3) then
          TaskPlayAnim(ped,pose[1],pose[2],8.0,-8.0,-1,state.poseFlag or 1,0.0,false,false,false)
        elseif state.mode=='follow' and GetGameTimer()>(state.nextTask or 0) then
          local leader=officerPed(state)
          if leader~=0 then TaskFollowToOffsetOfEntity(ped,leader,0.0,-1.5,0.0,1.5,-1,1.2,true) end
          state.nextTask=GetGameTimer()+4000
        end
        if ped==PlayerPedId() and state.cuffed then wait=0;DisablePlayerFiring(PlayerId(),true) end
      end
    end
    Wait(wait)
  end
end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for id in pairs(held) do release(id) end
  clearCustody()
  duty,selected,pending=false,0,0
end)
