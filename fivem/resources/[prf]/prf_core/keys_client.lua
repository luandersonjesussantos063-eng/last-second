-- Atalhos diretos opcionais; todas as acoes tambem existem no chat T.
-- Os antigos F6/F11 e numeros nao abrem nem controlam paineis.
local duty = false
local fleetIndex = 0
local weaponDrawn = false

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
  TriggerEvent('prfrp:chatHelp')
end, false)
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
  if duty then fleetIndex = 0; grantDutyRifle()
  else
    clearDutyRifle()
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

-- Compatibilidade com binds salvos: numeros antigos nao executam operacoes.
for i = 1, 9 do
  RegisterCommand('prfmenuitem' .. i, function() end, false)
end

AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() then
    clearDutyRifle()
    duty, weaponDrawn = false, false
  end
end)
