local duty, selected, pending, lastAttempt = false, 0, 0, 0
local held = {}
local dict, clip = 'random@arrests@busted', 'idle_a'
local function notice(text) TriggerEvent('prfrp:chatNotice',text) end
local function eligible(target)
  return target and target ~= 0 and target ~= PlayerPedId() and DoesEntityExist(target)
    and IsEntityAPed(target) and IsPedHuman(target) and not IsEntityDead(target)
    and not IsPedInAnyVehicle(target,false)
    and not (PrfIsCompanion and PrfIsCompanion(target))
    and not (PrfIsBackup and PrfIsBackup(target))
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
  if selected~=0 then TriggerEvent('prfrp:person:detained',NetworkGetEntityFromNetworkId(selected)) end
end)
PrfIsPersonStopped = function(ped)
  return selected~=0 and NetworkGetEntityFromNetworkId(selected)==ped
end
local function release(id)
  local state=held[id]
  held[id]=nil
  if not state or not state.applied then return end
  local ped=state.ped
  if DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) and not IsEntityDead(ped) then
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped,false)
    SetPedKeepTask(ped,false)
    if state.weapon and HasPedGotWeapon(ped,state.weapon,false) then SetCurrentPedWeapon(ped,state.weapon,true) end
    if not IsPedAPlayer(ped) then TaskWanderStandard(ped,10.0,10) end
  end
end
RegisterNetEvent('prfrp:person:release',release)
RegisterNetEvent('prfrp:person:hold',function(id,officer)
  release(id)
  local state={officer=officer}
  held[id]=state
  CreateThread(function()
    local started=GetGameTimer()
    local ped=0
    repeat
      if held[id]~=state then return end
      ped=NetworkGetEntityFromNetworkId(id)
      if ped~=0 and DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then break end
      Wait(50)
    until GetGameTimer()-started>3000
    if ped==0 or not DoesEntityExist(ped) or not NetworkHasControlOfEntity(ped)
      or IsEntityDead(ped) then held[id]=nil; return end
    state.ped,state.weapon=ped,GetSelectedPedWeapon(ped)
    RequestAnimDict(dict)
    started=GetGameTimer()
    while held[id]==state and not HasAnimDictLoaded(dict) and GetGameTimer()-started<3000 do Wait(50) end
    if held[id]~=state or not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    state.applied=true
    ClearPedTasks(ped)
    SetCurrentPedWeapon(ped,GetHashKey('WEAPON_UNARMED'),true)
    SetBlockingOfNonTemporaryEvents(ped,true)
    SetPedKeepTask(ped,true)
    if HasAnimDictLoaded(dict) then
      TaskPlayAnim(ped,dict,clip,8.0,-8.0,-1,1,0.0,false,false,false)
    else TaskHandsUp(ped,-1,PlayerPedId(),-1,true) end
  end)
end)
RegisterNetEvent('prfrp:person:report',function(id,action,lines)
  if not duty or id~=selected or type(lines)~='table' then return end
  for _,line in ipairs(lines) do notice(line) end
  local ped=PlayerPedId()
  if not IsPedInAnyVehicle(ped,false) then
    CreateThread(function()
      local scenario=action=='documents' and 'WORLD_HUMAN_CLIPBOARD' or 'CODE_HUMAN_MEDIC_KNEEL'
      TaskStartScenarioInPlace(ped,scenario,0,true)
      Wait(1800)
      if DoesEntityExist(ped) and IsPedUsingScenario(ped,scenario) then ClearPedTasks(ped) end
    end)
  end
end)
RegisterNetEvent('prfrp:setDuty',function(value)
  duty=value==true
  if not duty then selected,pending=0,0 end
end)
AddEventHandler('prfrp:baseArrival',function()
  selected,pending=0,0
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
      elseif ped and state.applied and NetworkHasControlOfEntity(ped)
        and HasAnimDictLoaded(dict) and not IsEntityPlayingAnim(ped,dict,clip,3) then
        TaskPlayAnim(ped,dict,clip,8.0,-8.0,-1,1,0.0,false,false,false)
      end
    end
    Wait(wait)
  end
end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for id in pairs(held) do release(id) end
  duty,selected,pending=false,0,0
end)
