-- Equipe de 3 policiais NPC (GTA V Legacy), exclusivamente no cliente.
-- Mantém baixa carga: verifica deslocamento a cada 1,7 segundo, sem IA em servidor.
local enabled = false
local squad = {}
local nextTaskAt = {}
local models = Config.Team or {
  's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_f_y_cop_01'
}
local offsets = {
  { x = -1.6, y = -2.4 },
  { x =  1.6, y = -2.4 },
  { x =  0.0, y = -4.0 },
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
  while not HasModelLoaded(hash) and GetGameTimer() - since < 6500 do
    Wait(0)
  end
  if HasModelLoaded(hash) then return hash end
  return nil
end
local function removeTeam()
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
local function spawnTeam()
  removeTeam()
  if not enabled then return end
  local player = PlayerPedId()
  local at = GetEntityCoords(player)
  for index = 1, 3 do
    if not enabled then break end
    local hash = ready(models[index] or 's_m_y_hwaycop_01')
    if hash then
      local offset = offsets[index]
      local officer = CreatePed(4, hash, at.x + offset.x, at.y + offset.y,
        at.z, GetEntityHeading(player), false, true)
      if officer ~= 0 and DoesEntityExist(officer) then
        SetEntityAsMissionEntity(officer, true, true)
        SetPedAsEnemy(officer, false)
        SetBlockingOfNonTemporaryEvents(officer, true)
        SetPedFleeAttributes(officer, 0, false)
        SetPedDiesWhenInjured(officer, false)
        GiveWeaponToPed(officer, GetHashKey('WEAPON_PISTOL'), 45, false, false)
        SetCurrentPedWeapon(officer, GetHashKey('WEAPON_UNARMED'), true)
        squad[#squad + 1] = officer
        follow(officer, player, #squad)
      end
      SetModelAsNoLongerNeeded(hash)
    end
  end
  inform(#squad .. '/3 policiais NPC na equipe. J: reagrupar.')
end

RegisterNetEvent('prfrp:setDuty', function(onDuty)
  enabled = onDuty == true
  if enabled then
    CreateThread(spawnTeam)
  else
    removeTeam()
  end
end)
AddEventHandler('prfrp:squadRally', function()
  if not enabled then
    inform('Entre em servico primeiro com F5.')
    return
  end
  if #squad ~= 3 then
    CreateThread(spawnTeam)
    return
  end
  local player = PlayerPedId()
  local at = GetEntityCoords(player)
  for index, officer in ipairs(squad) do
    if DoesEntityExist(officer) then
      if IsPedInAnyVehicle(officer, false) then
        TaskLeaveVehicle(officer, GetVehiclePedIsIn(officer, false), 0)
      else
        SetEntityCoordsNoOffset(officer, at.x + offsets[index].x,
          at.y + offsets[index].y, at.z, false, false, false)
        follow(officer, player, index)
      end
    end
  end
  inform('Equipe convocada para sua posicao.')
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
      for index, officer in ipairs(squad) do
        if DoesEntityExist(officer) and not IsEntityDead(officer) then
          local theirVehicle = GetVehiclePedIsIn(officer, false)
          local distance = #(GetEntityCoords(officer) - pos)
          if driver and index <= seats and IsVehicleSeatFree(vehicle, index - 1) then
            if distance > 45.0 then
              SetEntityCoordsNoOffset(officer, pos.x + 1.5, pos.y - 3.0,
                pos.z, false, false, false)
            end
            SetPedIntoVehicle(officer, vehicle, index - 1)
            nextTaskAt[index] = GetGameTimer() + 2500
          elseif theirVehicle ~= 0 and theirVehicle ~= vehicle then
            TaskLeaveVehicle(officer, theirVehicle, 0)
          elseif vehicle == 0 and theirVehicle ~= 0 then
            TaskLeaveVehicle(officer, theirVehicle, 0)
          elseif theirVehicle == 0 and GetGameTimer() > (nextTaskAt[index] or 0) then
            if distance > 75.0 then
              SetEntityCoordsNoOffset(officer, pos.x + offsets[index].x,
                pos.y + offsets[index].y, pos.z, false, false, false)
            end
            follow(officer, player, index)
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
