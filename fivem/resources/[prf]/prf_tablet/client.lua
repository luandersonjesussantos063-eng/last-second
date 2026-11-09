-- O comando só solicita abertura: autorização ocorre no servidor.
local open = false

RegisterCommand('prftablet', function()
  if open then return end
  TriggerServerEvent('prf_tablet:request')
end, false)

RegisterNetEvent('prf_tablet:open', function(payload)
  if type(payload) ~= 'table' or open then return end
  open = true
  SetNuiFocus(true, true)
  SendNUIMessage({ type = 'prf:open', calls = payload.calls or {}, demo = payload.demo == true })
end)

RegisterNetEvent('prf_tablet:denied', function(message)
  TriggerEvent('chat:addMessage', {
    color = { 249, 194, 74 },
    args = { 'PRF RP', tostring(message or 'Sem permissão') },
  })
end)

RegisterNUICallback('close', function(_, cb)
  open = false
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'prf:close' })
  cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(name)
  if name ~= GetCurrentResourceName() then return end
  open = false
  SetNuiFocus(false, false)
end)
