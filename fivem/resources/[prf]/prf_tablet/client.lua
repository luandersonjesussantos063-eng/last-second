-- O comando só solicita abertura: autorização ocorre no servidor.
local open = false

local function closeTablet()
  if not open then return end
  open = false
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'prf:close' })
end

RegisterCommand('prftablet', function()
  if open then return end
  TriggerServerEvent('prf_tablet:request')
end, false)

RegisterNetEvent('prf_tablet:open', function(payload)
  if type(payload) ~= 'table' or open then return end
  -- Defesa adicional de interface; a decisão de acesso permanece no servidor.
  local player = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
  local job = player and player.job
  if not job or job.name ~= 'prf' or job.onduty ~= true then return end
  open = true
  SetNuiFocus(true, true)
  SendNUIMessage({ type = 'prf:open', calls = payload.calls or {}, demo = payload.demo == true })
end)

RegisterNetEvent('prf_tablet:denied', function(message)
  closeTablet()
  TriggerEvent('chat:addMessage', {
    color = { 249, 194, 74 },
    args = { 'PRF RP', tostring(message or 'Sem permissão') },
  })
end)

-- Uma troca de emprego ou saída de serviço não pode deixar o tablet visível.
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
  if not job or job.name ~= 'prf' or job.onduty ~= true then
    closeTablet()
  end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', closeTablet)

RegisterNUICallback('close', function(_, cb)
  closeTablet()
  cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(name)
  if name ~= GetCurrentResourceName() then return end
  closeTablet()
  -- Também libera foco se o recurso parar antes de abrir o tablet.
  SetNuiFocus(false, false)
end)
