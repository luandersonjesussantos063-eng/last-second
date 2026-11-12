-- PRF RP Legacy: três companheiros NPC (roupa rodoviária nativa GTA V).
-- Defesa somente contra agressores identificados; não atacam civis aleatórios.
local enabled = false
local squad, nextTaskAt = {}, {}
local pendingThreat = 0
local threatUntil = 0
local lastDefense = 0
local models = Config.Team or { 's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_m_y_hwaycop_01' }
local function skinReady()
  return GetResourceState(Config.PRFSkinResource or 'prf_skin_replace') == 'started'
end
local offsets = {
  { x = -1.6, y = -2.4 },
  { x = 1.6, y = -2.4 },
  { x = 0.0, y = -4.0 },
}
local function inform(msg)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName('PRF RP - Equipe: ' .. msg)
  EndTextCommandThefeedPostTicker(false, false)
end
local function ready(name)
  local hash = GetHashKey(name)
  if not IsModelInCdimage(hash) or not IsModelAPed(hash) then return nil end
  RequestModel(hash)
  local since = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - since < 6500 do Wait(0) end
  if HasModelLoaded(hash) then return hash end
  return nil
end
local function isOfficer(ped)
  for _, officer in ipairs(squad) do
    if officer == ped then return true end
  end
  return false
end
local function removeTeam()
  pendingThreat, threatUntil = 0, 0
  for _, officer in ipairs(squad) do
    if officer ~= 0 and DoesEntityExist(officer) then
      SetEntityAsMissionEntity(officer, true, true)
      DeletePed(officer)
    end
  end
  squad, nextTaskAt = {}, {}
end
local function follow(officer, player, index)
  local offset = offsets[index] or offsets[1]
  TaskFollowToOffsetOfEntity(officer, player, offset.x, offset.y, 0.0,
    2.2, -1, 2.3, true)
  SetPedKeepTask(officer, true)
  nextTaskAt[index] = GetGameTimer() + 3800
end
local function configureAlly(officer, player)
  -- Grupo do jogador evita que o NPC trate o policial como um inimigo.
  SetPedRelationshipGroupHash(officer, GetPedRelationshipGroupHash(player))
  SetCanAttackFriendly(officer, false, false)
  SetPedAsEnemy(officer, false)
  SetBlockingOfNonTemporaryEvents(officer, true)
  SetPedFleeAttributes(officer, 0, false)
  SetPedDiesWhenInjured(officer, false)
  SetPedCombatAbility(officer, 2)
  SetPedCombatMovement(officer, 2)
  SetPedCombatRange(officer, 1)
  SetPedAccuracy(officer, 45)
  SetPedArmour(officer, 50)
  SetPedDropsWeaponsWhenDead(officer, false)
  GiveWeaponToPed(officer, GetHashKey(Config.DutyWeapon or 'WEAPON_CARBINERIFLE'), 180, false, false)
  SetCurrentPedWeapon(officer, GetHashKey('WEAPON_UNARMED'), true)
end
local function spawnTeam()
  removeTeam()
  if not enabled then return end
  local player = PlayerPedId()
  local at = GetEntityCoords(player)
  for index = 1, 3 do
    if not enabled then break end
    -- Se o mod gráfico não tiver um ped alternativo, usa o rodoviário do GTA V.
    local preferred = skinReady() and Config.PRFSkinModel or models[index]
    local hash = ready(preferred) or ready('s_m_y_hwaycop_01')
    if hash then
      local offset = offsets[index]
      local officer = CreatePed(4, hash, at.x + offset.x, at.y + offset.y,
        at.z, GetEntityHeading(player), false, true)
      if officer ~= 0 and DoesEntityExist(officer) then
        SetEntityAsMissionEntity(officer, true, true)
        configureAlly(officer, player)
        squad[#squad + 1] = officer
        follow(officer, player, #squad)
      end
      SetModelAsNoLongerNeeded(hash)
    end
  end
  inform(#squad .. '/3 policiais equipados com fuzil. ' ..
    (skinReady() and 'Farda PRF instalada.' or 'Farda PRF AUSENTE; skin GTA provisoria.') ..
    ' J: reagrupar.')
end

-- Reage a dano local recebido pelo jogador ou colega.
-- Não usa comandos de cliente para conceder privilégios no servidor.
local function engageThreat(candidate)
  if not enabled or candidate == 0 or not DoesEntityExist(candidate) then return end
  if candidate == PlayerPedId() or isOfficer(candidate) then return end
  if GetEntityType(candidate) == 2 then
    candidate = GetPedInVehicleSeat(candidate, -1)
  end
  if candidate == 0 or not DoesEntityExist(candidate) or GetEntityType(candidate) ~= 1
    or IsEntityDead(candidate) or isOfficer(candidate) then return end
  local player = PlayerPedId()
  if candidate == player then return end
  local distance = #(GetEntityCoords(player) - GetEntityCoords(candidate))
  if distance > 85.0 then return end
  local now = GetGameTimer()
  if pendingThreat == candidate and now < threatUntil then
    threatUntil = now + 20000
    return
  end
  if now - lastDefense < 800 then return end
  lastDefense, pendingThreat, threatUntil = now, candidate, now + 20000
  for _, officer in ipairs(squad) do
    if DoesEntityExist(officer) and not IsEntityDead(officer) then
      SetCurrentPedWeapon(officer, GetHashKey(Config.DutyWeapon or 'WEAPON_CARBINERIFLE'), true)
      if IsPedInAnyVehicle(officer, false) then
        TaskLeaveVehicle(officer, GetVehiclePedIsIn(officer, false), 0)
      end
    end
  end
  inform('Sob ataque! Equipe em apoio.')
end

AddEventHandler('entityDamaged', function(victim, culprit)
  if not enabled or not victim or not culprit then return end
  if victim ~= PlayerPedId() and not isOfficer(victim) then return end
  engageThreat(culprit)
end)

RegisterNetEvent('prfrp:setDuty', function(onDuty)
  enabled = onDuty == true
  if enabled then CreateThread(spawnTeam) else removeTeam() end
end)
AddEventHandler('prfrp:squadRally', function()
  if not enabled then inform('Entre em servico primeiro com F5.'); return end
  if #squad ~= 3 then CreateThread(spawnTeam); return end
  pendingThreat, threatUntil = 0, 0
  local player, at = PlayerPedId(), GetEntityCoords(PlayerPedId())
  for index, officer in ipairs(squad) do
    if DoesEntityExist(officer) and not IsEntityDead(officer) then
      if IsPedInAnyVehicle(officer, false) then
        TaskLeaveVehicle(officer, GetVehiclePedIsIn(officer, false), 0)
        nextTaskAt[index] = 0
      else
        SetEntityCoordsNoOffset(officer, at.x + offsets[index].x,
          at.y + offsets[index].y, at.z, false, false, false)
        SetCurrentPedWeapon(officer, GetHashKey('WEAPON_UNARMED'), true)
        follow(officer, player, index)
      end
    end
  end
  inform('Equipe reagrupada.')
end)
AddEventHandler('prfrp:squadVehicleChanged', function()
  for index in ipairs(squad) do nextTaskAt[index] = 0 end
end)

CreateThread(function()
  while true do
    if enabled and #squad > 0 then
      local player = PlayerPedId()
      local pos = GetEntityCoords(player)
      local vehicle = GetVehiclePedIsIn(player, false)
      local driver = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == player
      local seats = driver and GetVehicleMaxNumberOfPassengers(vehicle) or 0
      local now = GetGameTimer()
      -- Também socorre quando alguém DISPARA em nossa direção, mesmo sem acertar.
      -- Busca apenas pedestres próximos e realmente atirando para evitar agressão aleatória.
      if pendingThreat == 0 then
        local scanned = 0
        for _, suspect in ipairs(GetGamePool('CPed')) do
          scanned = scanned + 1
          if scanned > 100 then break end
          if suspect ~= player and not isOfficer(suspect)
            and DoesEntityExist(suspect) and not IsEntityDead(suspect)
            and #(GetEntityCoords(suspect) - pos) < 32.0
            and IsPedShooting(suspect) and IsPedFacingPed(suspect, player, 30.0) then
            engageThreat(suspect)
            break
          end
        end
      end
      if pendingThreat ~= 0 and
        (not DoesEntityExist(pendingThreat) or IsEntityDead(pendingThreat)
         or now > threatUntil or
         #(GetEntityCoords(pendingThreat) - pos) > 95.0) then
        pendingThreat, threatUntil = 0, 0
        for _, officer in ipairs(squad) do
          if DoesEntityExist(officer) and not IsEntityDead(officer) then
            ClearPedTasks(officer)
            SetCurrentPedWeapon(officer, GetHashKey('WEAPON_UNARMED'), true)
          end
        end
      end
      -- Apoio somente em situação real de dano. Jamais ataca pessoas aleatórias.
      if pendingThreat ~= 0 then
        for index, officer in ipairs(squad) do
          if DoesEntityExist(officer) and not IsEntityDead(officer) then
            if IsPedInAnyVehicle(officer, false) then
              TaskLeaveVehicle(officer, GetVehiclePedIsIn(officer, false), 0)
            elseif now > (nextTaskAt[index] or 0) then
              TaskCombatPed(officer, pendingThreat, 0, 16)
              nextTaskAt[index] = now + 4500
            end
          end
        end
      else
        for index, officer in ipairs(squad) do
          if DoesEntityExist(officer) and not IsEntityDead(officer) then
            local theirVehicle = GetVehiclePedIsIn(officer, false)
            local distance = #(GetEntityCoords(officer) - pos)
            -- Atualiza relação se o jogador trocou de modelo pelo vestiário.
            SetPedRelationshipGroupHash(officer, GetPedRelationshipGroupHash(player))
            if driver and index <= seats and IsVehicleSeatFree(vehicle, index - 1) then
              if distance > 45.0 then
                SetEntityCoordsNoOffset(officer, pos.x + 1.5, pos.y - 3.0,
                  pos.z, false, false, false)
              end
              SetPedIntoVehicle(officer, vehicle, index - 1)
              nextTaskAt[index] = now + 2500
            elseif theirVehicle ~= 0 and theirVehicle ~= vehicle then
              TaskLeaveVehicle(officer, theirVehicle, 0)
            elseif vehicle == 0 and theirVehicle ~= 0 then
              TaskLeaveVehicle(officer, theirVehicle, 0)
            elseif theirVehicle == 0 and now > (nextTaskAt[index] or 0) then
              if distance > 75.0 then
                SetEntityCoordsNoOffset(officer, pos.x + offsets[index].x,
                  pos.y + offsets[index].y, pos.z, false, false, false)
              end
              follow(officer, player, index)
            end
          end
        end
      end
    end
    Wait(1700)
  end
end)
AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() then
    enabled = false
    removeTeam()
  end
end)
