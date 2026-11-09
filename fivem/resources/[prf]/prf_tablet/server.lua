-- Dados fictícios: NÃO consulta DETRAN, polícia real ou dados de cidadãos.
local QBCore = exports['qb-core']:GetCoreObject()
local lastRequest = {}
local calls = {
  { id = 'TESTE-101', title = 'Veículo parado no acostamento', kind = 'Apoio', status = 'Aberto', route = 'Trecho fictício 01' },
  { id = 'TESTE-102', title = 'Objeto na pista', kind = 'Segurança viária', status = 'Em análise', route = 'Trecho fictício 02' },
}

local function authorized(src)
  local player = QBCore.Functions.GetPlayer(src)
  if not player or not player.PlayerData then return false end
  local job = player.PlayerData.job
  return job and job.name == 'prf' and job.onduty == true
end

RegisterNetEvent('prf_tablet:request', function()
  local src = source
  if type(src) ~= 'number' or src < 1 then return end
  local now = os.time()
  if lastRequest[src] and now - lastRequest[src] < 2 then return end
  lastRequest[src] = now
  if not authorized(src) then
    TriggerClientEvent('prf_tablet:denied', src, 'Tablet disponível somente para PRF em serviço.')
    return
  end
  TriggerClientEvent('prf_tablet:open', src, { calls = calls, demo = true })
end)

AddEventHandler('playerDropped', function()
  lastRequest[source] = nil
end)
