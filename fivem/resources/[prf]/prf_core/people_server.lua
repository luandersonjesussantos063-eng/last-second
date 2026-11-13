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
      alcohol = math.random(8)==1 and '0.34 mg/L' or '0.00 mg/L',
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
  stops[src] = { id = id, entity = target, model = GetEntityModel(target), owner = owner,
    updated = os.time(),mode='head',cuffed=false,revision=1 }
  locks[id] = src
  record(id,target)
  TriggerClientEvent('prfrp:person:selected',src,id)
  TriggerClientEvent('prfrp:person:hold',owner,id,src,{mode='head',cuffed=false,revision=1})
  notify(src, 'Pessoa abordada. Aproxime-se e use T > documento, revistar ou liberar.')
end)

-- Chamado pelo servidor de operacoes, com as mesmas acoes de carros e pessoas.
PrfPersonAction = function(src, action)
  local stop = stops[src]
  if not stop or (action ~= 'documents' and action ~= 'search' and action ~= 'release'
    and action ~= 'tow' and action~='breathalyzer') then return false end
  if not allowed(src) then return true end
  if action == 'release' then PrfReleasePerson(src); notify(src,'Pessoa liberada.'); return true end
  local target = resolve(stop)
  if not target then PrfReleasePerson(src); notify(src,'Pessoa indisponivel. Faca nova abordagem.'); return true end
  if action == 'tow' then notify(src,'Guincho serve para veiculos. Libere a pessoa e aborde um carro.'); return true end
  if not nearby(src,target,3.0) then notify(src,'Aproxime-se da pessoa (ate 3 metros).'); return true end
  if GetVehiclePedIsIn(GetPlayerPed(src),false) ~= 0 then notify(src,'Desembarque para fiscalizar.'); return true end
  if GetVehiclePedIsIn(target,false)~=0 then notify(src,'Mande a pessoa descer primeiro.');return true end
  if stop.actionAt and os.time()-stop.actionAt < 2 then return true end
  stop.updated, stop.actionAt = os.time(), os.time()
  local value = record(stop.id,target)
  local lines
  if action == 'documents' then
    lines = { 'DOCUMENTO FICTICIO | '..value.name..' | '..value.document,
      'ANTECEDENTES SIMULADOS | '..value.history,
      value.wanted and 'Consulta ficticia: mandado pendente.' or 'Consulta ficticia: sem mandado pendente.' }
  elseif action=='search' then
    lines = { 'REVISTA PESSOAL SIMULADA | '..value.name, value.item }
  else lines={'BAFOMETRO SIMULADO | '..value.name..' | '..value.alcohol..' (resultado ficticio).'}
  end
  TriggerClientEvent('prfrp:person:report',src,stop.id,action,lines)
  return true
end

local function sendOrder(src,stop)
  stop.revision=stop.revision+1
  TriggerClientEvent('prfrp:person:hold',stop.owner,stop.id,src,
    {mode=stop.mode,cuffed=stop.cuffed,vehicle=stop.vehicle,revision=stop.revision})
end
RegisterNetEvent('prfrp:person:order',function(action,data)
  local src=source
  if not allowed(src) or type(action)~='string' or not Config.PersonOrders[action] then return end
  local stop=stops[src]
  if not stop then notify(src,'Aborde uma pessoa primeiro.');return end
  local target=resolve(stop)
  if not target then PrfReleasePerson(src);return end
  if not nearby(src,target,15) or GetVehiclePedIsIn(GetPlayerPed(src),false)~=0 then
    notify(src,'Desembarque e aproxime-se da pessoa abordada.');return
  end
  if (action=='cuff' or action=='uncuff' or action=='enter') and not nearby(src,target,3) then
    notify(src,'Aproxime-se da pessoa (ate 3 metros).');return
  end
  if stop.orderAt and os.time()-stop.orderAt<1 then return end
  if GetVehiclePedIsIn(target,false)~=0 and action~='exit' then notify(src,'Mande descer do carro primeiro.');return end
  if stop.cuffed and (action=='head' or action=='handsup' or action=='prone' or action=='kneel') then
    notify(src,'Retire as algemas antes de mudar a posicao dos bracos.');return
  end
  if action=='enter' then
    local id=type(data)=='table' and data.vehicle
    if type(id)~='number' or id<=0 or id%1~=0 then notify(src,'Pegue sua viatura e aproxime-a da pessoa.');return end
    local car=NetworkGetEntityFromNetworkId(id)
    if car==0 or not DoesEntityExist(car) or GetEntityType(car)~=2 or not nearby(src,car,10) then
      notify(src,'A viatura precisa estar proxima.');return
    end
    local permitted=false
    for _,entry in ipairs(Config.Fleet) do if GetHashKey(entry.model)==GetEntityModel(car) then permitted=true;break end end
    if not permitted or GetEntitySpeed(car)>0.5 then notify(src,'Use uma viatura da frota parada.');return end
    stop.vehicle=id
  else stop.vehicle=nil end
  if action=='cuff' then stop.cuffed=true;stop.mode='cuffed'
  elseif action=='uncuff' then stop.cuffed=false;stop.mode='head'
  else stop.mode=action end
  stop.updated,stop.orderAt=os.time(),os.time()
  sendOrder(src,stop)
  notify(src,({head='Maos na cabeca.',handsup='Maos para cima.',prone='Deite no chao.',
    kneel='Ajoelhe.',stand='Levante.',stay='Permaneça no local.',follow='Acompanhe o policial.',
    cuff='Pessoa algemada.',uncuff='Algemas retiradas.',enter='Entre na viatura.',exit='Desca do carro.'})[action])
end)
RegisterNetEvent('prfrp:person:orderFailed',function(id,revision)
  for src,stop in pairs(stops) do
    if stop.id==id and stop.owner==source and stop.revision==revision then
      stop.mode=stop.cuffed and 'cuffed' or 'head';stop.vehicle=nil
      sendOrder(src,stop);notify(src,'Nao foi possivel concluir a ordem. Confira o acesso e os assentos livres.');return
    end
  end
end)
PrfOrderExitVehicle = function(src,car)
  local total=0
  for seat=-1,31 do
    local ped=GetPedInVehicleSeat(car,seat)
    if ped~=0 and DoesEntityExist(ped) then
      local owner=NetworkGetEntityOwner(ped)
      if owner and owner>0 then
        TriggerClientEvent('prfrp:person:leaveVehicle',owner,NetworkGetNetworkIdFromEntity(ped),
          NetworkGetNetworkIdFromEntity(car),src)
        total=total+1
      end
    end
  end
  notify(src,total>0 and 'Ordem de desembarque enviada. Aborde a pessoa quando sair.' or 'Veiculo sem ocupantes.')
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
          sendOrder(src,stop)
        end
      end
    end
    for id, value in pairs(records) do
      if not DoesEntityExist(value.entity) or (not locks[id] and os.time()-value.seen > 1800) then records[id] = nil end
    end
  end
end)
