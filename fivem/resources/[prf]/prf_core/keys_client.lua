-- Controles independentes do mapa de INPUT_CONTROL do GTA V.
-- F6 abre menu; números 1-9 são RegisterKeyMapping EXPLÍCITOS.
-- Isso corrige o antigo erro: opção 4 acionava outro comando.
local menuOpen = false
local duty = false
local fleetIndex = 0
local weaponDrawn = false
local selected = 1

local function request(action, data)
  TriggerServerEvent('prfrp:requestAction', action, data)
end
local function nextFleet()
  if not duty then
    request('vehicle')
    return
  end
  local fleet = Config.Fleet or {}
  if #fleet == 0 then return end
  fleetIndex = fleetIndex % #fleet + 1
  request('vehicle', fleet[fleetIndex].model)
end
local function toggleWeapon()
  request('weapon')
end
RegisterCommand('prftecladoturno', function() request('duty') end, false)
RegisterKeyMapping('prftecladoturno', 'PRF RP: iniciar/encerrar turno', 'keyboard', 'F5')
RegisterCommand('prfmenu', function()
  menuOpen = not menuOpen
  if menuOpen then TriggerEvent('prfrp:closeOpsMenu') end
end, false)
AddEventHandler('prfrp:closeCoreMenu', function() menuOpen = false end)
RegisterKeyMapping('prfmenu', 'PRF RP: abrir/fechar menu operacional', 'keyboard', 'F6')
RegisterCommand('prftecladocopom', function() request('call') end, false)
RegisterKeyMapping('prftecladocopom', 'PRF RP: chamar COPOM', 'keyboard', 'F7')
RegisterCommand('prftecladogaragem', nextFleet, false)
RegisterKeyMapping('prftecladogaragem', 'PRF RP: próxima viatura', 'keyboard', 'F9')
RegisterCommand('prftecladoarma', toggleWeapon, false)
RegisterKeyMapping('prftecladoarma', 'PRF RP: sacar/guardar fuzil de servico', 'keyboard', 'K')
RegisterCommand('prftecladoequipe', function() TriggerEvent('prfrp:squadRally') end, false)
RegisterKeyMapping('prftecladoequipe', 'PRF RP: reagrupar equipe', 'keyboard', 'J')
RegisterCommand('prftecladogiroflex', function() TriggerEvent('prfrp:toggleEmergencyLights') end, false)
RegisterKeyMapping('prftecladogiroflex', 'PRF RP: ligar/desligar giroflex', 'keyboard', 'L')
RegisterCommand('prftecladosirene', function() TriggerEvent('prfrp:toggleSirenSound') end, false)
RegisterKeyMapping('prftecladosirene', 'PRF RP: ativar/silenciar sirene', 'keyboard', 'O')

local dutyRifleGranted = false
local dutyRiflePed = 0
local function dutyWeapon()
  return GetHashKey(Config.DutyWeapon or 'WEAPON_CARBINERIFLE')
end
local function grantDutyRifle()
  if not duty then return end
  local ped = PlayerPedId()
  if not DoesEntityExist(ped) then return end
  local rifle = dutyWeapon()
  if not HasPedGotWeapon(ped, rifle, false) then
    GiveWeaponToPed(ped, rifle, 180, false, false)
    dutyRifleGranted = true
  else
    dutyRifleGranted = false
  end
  dutyRiflePed = ped
  SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
  weaponDrawn = false
end
local function clearDutyRifle()
  local ped = PlayerPedId()
  if dutyRifleGranted and dutyRiflePed == ped and DoesEntityExist(ped) then
    RemoveWeaponFromPed(ped, dutyWeapon())
  end
  dutyRifleGranted = false
  dutyRiflePed = 0
  weaponDrawn = false
end
RegisterNetEvent('prfrp:setDuty', function(enabled)
  duty = enabled == true
  if duty then grantDutyRifle()
  else
    clearDutyRifle()
    menuOpen = false
  end
end)
RegisterNetEvent('prfrp:uniformApplied', function()
  -- SetPlayerModel cria outro ped e remove a arma anterior.
  dutyRifleGranted = false
  dutyRiflePed = 0
  if duty then grantDutyRifle() end
end)
AddEventHandler('playerSpawned', function()
  if not duty then return end
  CreateThread(function()
    Wait(250)
    if duty then grantDutyRifle() end
  end)
end)
RegisterNetEvent('prfrp:toggleWeapon', function()
  if not duty then return end
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then return end
  local rifle = dutyWeapon()
  if not weaponDrawn then
    if not HasPedGotWeapon(ped, rifle, false) then
      GiveWeaponToPed(ped, rifle, 180, false, false)
      dutyRifleGranted = true
      dutyRiflePed = ped
    end
    SetCurrentPedWeapon(ped, rifle, true)
    weaponDrawn = true
  else
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    weaponDrawn = false
  end
end)

local options = {
  '1  Iniciar/encerrar servico',
  '2  Proxima viatura',
  '3  Receber chamado COPOM',
  '4  Equipar/retirar uniforme',
  '5  Cancelar ocorrencia',
  '6  Reagrupar equipe',
  '7  Sacar/guardar fuzil',
  '8  Consultar status',
  '9  Fechar menu'
}
local actions = {
  function() request('duty') end,
  nextFleet,
  function() request('call') end,
  function() request('uniform') end,
  function() request('cancel') end,
  function() TriggerEvent('prfrp:squadRally') end,
  toggleWeapon,
  function() request('status') end,
  function() menuOpen = false end
}

local function choose(index)
  if not menuOpen then return end
  if type(index) ~= 'number' or not actions[index] then return end
  menuOpen = false
  actions[index]()
end

for i = 1, 9 do
  local index = i
  RegisterCommand('prfmenuitem' .. i, function() choose(index) end, false)
  RegisterKeyMapping('prfmenuitem' .. i,
    'PRF RP: opcao ' .. i .. ' (somente menu F6)', 'keyboard', tostring(i))
end

local function drawText(x, y, scale, value, accent)
  SetTextFont(4)
  SetTextScale(scale, scale)
  if accent then SetTextColour(250, 219, 90, 255)
  else SetTextColour(255, 255, 255, 245) end
  SetTextOutline()
  SetTextEntry('STRING')
  AddTextComponentString(value)
  DrawText(x, y)
end

CreateThread(function()
  while true do
    local sleep = 500
    if menuOpen then
      sleep = 0
      DrawRect(0.18, 0.30, 0.32, 0.47, 8, 28, 48, 215)
      drawText(0.038, 0.085, 0.39, 'PRF RP | F6 fechar | 1-9 escolher')
      for i, item in ipairs(options) do
        drawText(0.039, 0.12 + i * 0.035, 0.31,
          (selected == i and '> ' or '  ') .. item, selected == i)
      end
      -- Além dos números: setas e Enter também funcionam no notebook.
      if IsControlJustReleased(0, 172) then selected = selected == 1 and #options or selected - 1 end
      if IsControlJustReleased(0, 173) then selected = selected == #options and 1 or selected + 1 end
      if IsControlJustReleased(0, 191) then choose(selected) end
      if IsControlJustReleased(0, 200) then menuOpen = false end
    end
    Wait(sleep)
  end
end)

AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() then
    clearDutyRifle()
    menuOpen, duty, weaponDrawn = false, false, false
  end
end)
