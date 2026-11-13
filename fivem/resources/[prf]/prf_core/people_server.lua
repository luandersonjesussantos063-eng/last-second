-- Identidades e antecedentes ficticios, estaveis durante a vida de cada NPC.
local stops, locks, records, lastRequest = {}, {}, {}, {}
local names = { 'Carlos Pereira', 'Ana Souza', 'Joao Oliveira', 'Marcos Lima',
  'Julia Santos', 'Paulo Ribeiro', 'Mariana Costa', 'Lucas Almeida' }
local histories = { 'Sem passagem.', 'Passagem por furto.', 'Passagem por roubo.',
  'Passagem por receptacao.' }

local function notify(src, message)
  TriggerClientEvent('prfrp:operationsNotify', src, message)
end
local function allowed(src)
  return type(src) == 'number' and src > 0 and PrfHasDuty and PrfHasDuty(src)
end
local function nearby(src, target, radius)
  local officer = GetPlayerPed(src)
  if officer == 0 or not DoesEntityExist(officer) then return false end
  local p, q = GetEntityCoords(officer), GetEntityCoords(target)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2 <= radius^2
end
local function resolve(stop)
  local target = NetworkGetEntityFromNetworkId(stop.id)
  if target == 0 or not DoesEntityExist(target) or target ~= stop.entity
    or GetEntityType(target) ~= 1 or GetEntityModel(target) ~= stop.model
    or GetEntityHealth(target) <= 0 then return nil end
  return target
end
PrfReleasePerson = function(src)
  local stop = stops[src]
  if not stop then return end
  stops[src], locks[stop.id] = nil, nil
  if stop.owner and stop.owner > 0 then
    TriggerClientEvent('prfrp:person:release', stop.owner, stop.id)
  end
  TriggerClientEvent('prfrp:person:selected', src, false)
end
local function record(id, target)
  local value = records[id]
  local model = GetEntityModel(target)
  if not value or value.entity ~= target or value.model ~= model then
    value = { entity = target, model = model, name = names[math.random(#names)],
      document = ('SIM-%d-%04d'):format(id, math.random(1000,9999)),
      history = math.random(4) == 1 and histories[math.random(2,#histories)] or histories[1],
      wanted = math.random(12) == 1,
      item = math.random(5) == 1 and 'Objeto suspeito encontrado (simulacao).' or 'Nada de irregular encontrado.' }
    records[id] = value
  end
  value.seen = os.time()
  return value
end

RegisterNetEvent('prfrp:person:approach', function(id)
  local src = source
  if not allowed(src) then notify(src, 'Entre em servico com T > servico.'); return end
  if lastRequest[src] and os.time()-lastRequest[src] < 1 then return end
  lastRequest[src] = os.time()
  if type(id) ~= 'number' or id % 1 ~= 0 or id <= 0 then return end
  local target = NetworkGetEntityFromNetworkId(id)
  if target == 0 or not DoesEntityExist(target) or GetEntityType(target) ~= 1
    or target == GetPlayerPed(src) or GetEntityHealth(target) <= 0 then return end
  if not nearby(src,target,15) then notify(src, 'Aproxime-se da pessoa para abordar.'); return end
  if GetVehiclePedIsIn(GetPlayerPed(src),false) ~= 0 or GetVehiclePedIsIn(target,false) ~= 0 then
    notify(src, 'Aborde pessoas a pe. Para um carro, use abordar olhando para o veiculo.'); return
  end
  if locks[id] and locks[id] ~= src then notify(src, 'Essa pessoa ja esta em outra abordagem.'); return end
  local owner = NetworkGetEntityOwner(target)
  if not owner or owner <= 0 then notify(src, 'Pessoa ainda carregando. Tente novamente.'); return end
  PrfReleasePerson(src)
  TriggerEvent('prfrp:ops:clearInspection',src)
  stops[src] = { id = id, entity = target, model = GetEntityModel(target), owner = owner, updated = os.time() }
  locks[id] = src
  record(id,target)
  TriggerClientEvent('prfrp:person:selected',src,id)
  TriggerClientEvent('prfrp:person:hold',owner,id,src)
  notify(src, 'Pessoa abordada. Aproxime-se e use T > documento, revistar ou liberar.')
end)

-- Chamado pelo servidor de operacoes, com as mesmas acoes de carros e pessoas.
PrfPersonAction = function(src, action)
  local stop = stops[src]
  if not stop or (action ~= 'documents' and action ~= 'search' and action ~= 'release' and action ~= 'tow') then return false end
  if not allowed(src) then return true end
  if action == 'release' then PrfReleasePerson(src); notify(src,'Pessoa liberada.'); return true end
  local target = resolve(stop)
  if not target then PrfReleasePerson(src); notify(src,'Pessoa indisponivel. Faca nova abordagem.'); return true end
  if action == 'tow' then notify(src,'Guincho serve para veiculos. Libere a pessoa e aborde um carro.'); return true end
  if not nearby(src,target,3.0) then notify(src,'Aproxime-se da pessoa (ate 3 metros).'); return true end
  if GetVehiclePedIsIn(GetPlayerPed(src),false) ~= 0 then notify(src,'Desembarque para fiscalizar.'); return true end
  if stop.actionAt and os.time()-stop.actionAt < 2 then return true end
  stop.updated, stop.actionAt = os.time(), os.time()
  local value = record(stop.id,target)
  local lines
  if action == 'documents' then
    lines = { 'DOCUMENTO FICTICIO | '..value.name..' | '..value.document,
      'ANTECEDENTES SIMULADOS | '..value.history,
      value.wanted and 'Consulta ficticia: mandado pendente.' or 'Consulta ficticia: sem mandado pendente.' }
  else
    lines = { 'REVISTA PESSOAL SIMULADA | '..value.name, value.item }
  end
  TriggerClientEvent('prfrp:person:report',src,stop.id,action,lines)
  return true
end

RegisterNetEvent('prfrp:person:cancel',function() PrfReleasePerson(source) end)
AddEventHandler('prfrp:ops:dutyEnded',function(src) PrfReleasePerson(src) end)
AddEventHandler('playerDropped',function()
  local src = source
  PrfReleasePerson(src); lastRequest[src] = nil
  for officer, stop in pairs(stops) do if stop.owner == src then PrfReleasePerson(officer) end end
end)
CreateThread(function()
  while true do
    Wait(5000)
    for src, stop in pairs(stops) do
      local target = resolve(stop)
      if not allowed(src) or not target or not nearby(src,target,40) or os.time()-stop.updated > 180 then
        PrfReleasePerson(src)
      else
        local owner = NetworkGetEntityOwner(target)
        if owner and owner > 0 and owner ~= stop.owner then
          TriggerClientEvent('prfrp:person:release',stop.owner,stop.id)
          stop.owner = owner
          TriggerClientEvent('prfrp:person:hold',owner,stop.id,src)
        end
      end
    end
    for id, value in pairs(records) do
      if not DoesEntityExist(value.entity) or (not locks[id] and os.time()-value.seen > 1800) then records[id] = nil end
    end
  end
end)
