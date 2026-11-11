-- Atalhos e painel F6 simples, sem NUI pesada.
-- Teclas remapeáveis em Configurações > Key Bindings > FiveM.
local menuOpen = false
local duty = false
local fleetIndex = 0
local weaponDrawn = false

local function request(action, data)
  TriggerServerEvent('prfrp:requestAction', action, data)
end
local function nextFleet()
  if not duty then request('vehicle'); return end
  local fleet = Config.Fleet or {}
  if #fleet == 0 then return end
  fleetIndex = fleetIndex % #fleet + 1
  request('vehicle', fleet[fleetIndex].model)
end

RegisterCommand('prftecladoturno', function() request('duty') end, false)
RegisterKeyMapping('prftecladoturno', 'PRF RP: iniciar/encerrar turno', 'keyboard', 'F5')
RegisterCommand('prfmenu', function() menuOpen = not menuOpen end, false)
RegisterKeyMapping('prfmenu', 'PRF RP: menu operacional', 'keyboard', 'F6')
RegisterCommand('prftecladocopom', function() request('call') end, false)
RegisterKeyMapping('prftecladocopom', 'PRF RP: chamar COPOM', 'keyboard', 'F7')
RegisterCommand('prftecladogaragem', function() nextFleet() end, false)
RegisterKeyMapping('prftecladogaragem', 'PRF RP: próxima viatura', 'keyboard', 'F9')
RegisterCommand('prftecladoarma', function() request('weapon') end, false)
RegisterKeyMapping('prftecladoarma', 'PRF RP: sacar/guardar arma', 'keyboard', 'K')
RegisterCommand('prftecladoequipe', function() TriggerEvent('prfrp:squadRally') end, false)
RegisterKeyMapping('prftecladoequipe', 'PRF RP: reagrupar equipe', 'keyboard', 'J')

RegisterNetEvent('prfrp:setDuty', function(enabled)
  duty = enabled == true
  weaponDrawn = false
  if not duty then menuOpen = false end
end)
RegisterNetEvent('prfrp:toggleWeapon', function()
  if not duty then return end
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then return end
  local weapon = GetHashKey('WEAPON_PISTOL')
  if not weaponDrawn then
    if not HasPedGotWeapon(ped, weapon, false) then
      GiveWeaponToPed(ped, weapon, 60, false, false)
    end
    SetCurrentPedWeapon(ped, weapon, true)
    weaponDrawn = true
  else
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    weaponDrawn = false
  end
end)
local options = {
  '1  Iniciar/encerrar servico',
  '2  Proxima viatura da frota',
  '3  Receber chamado COPOM',
  '4  Farda PRF',
  '5  Cancelar ocorrencia',
  '6  Reagrupar 3 policiais',
  '7  Sacar/guardar arma',
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
  function() request('weapon') end,
  function() request('status') end,
  function() menuOpen = false end
}
local function drawText(x, y, scale, value)
  SetTextFont(4)
  SetTextScale(scale, scale)
  SetTextColour(255, 255, 255, 235)
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
      DrawRect(0.177, 0.30, 0.31, 0.45, 8, 28, 48, 205)
      drawText(0.037, 0.087, 0.39, 'PRF RP - NOVA BYTE | F6 fecha')
      for i, option in ipairs(options) do
        drawText(0.039, 0.12 + i * 0.035, 0.31, option)
        local control = 156 + i
        DisableControlAction(0, control, true)
        if IsDisabledControlJustReleased(0, control) then
          actions[i]()
          menuOpen = false
        end
      end
    end
    Wait(sleep)
  end
end)
AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() then
    menuOpen, duty, weaponDrawn = false, false, false
  end
end)
