-- Visual/ambientacao locais. Permissoes e validacao de ocorrencia sao do servidor.
local onDuty = false
local call = nil
local routeBlip = nil
local stationBlip = nil
local patrol = 0
local spawning = false
local spawnGeneration = 0
local citizen = 0
local lastComplete = 0
local sceneProps = {}

local function message(value)
  local text = 'PRF RP: ' .. tostring(value)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandThefeedPostTicker(false, false)
  print('[PRF RP] ' .. tostring(value))
end

local function loadModel(name)
  local hash = type(name) == 'number' and name or GetHashKey(name)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local started = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - started < 8000 do
    Wait(0)
  end
  if not HasModelLoaded(hash) then
    SetModelAsNoLongerNeeded(hash)
    return nil
  end
  return hash
end

local function cleanupCitizen()
  for _, object in ipairs(sceneProps) do
    if object ~= 0 and DoesEntityExist(object) then DeleteObject(object) end
  end
  sceneProps = {}
  if citizen ~= 0 and DoesEntityExist(citizen) then
    DeletePed(citizen)
  end
  citizen = 0
end

local function cleanupCall()
  if routeBlip then
    RemoveBlip(routeBlip)
    routeBlip = nil
  end
  cleanupCitizen()
  call = nil
end

RegisterNetEvent('prfrp:notify', message)

RegisterNetEvent('prfrp:setDuty', function(enabled)
  onDuty = enabled == true
  if not onDuty then
    spawnGeneration = spawnGeneration + 1
    cleanupCall()
    return
  end
  if Config.TeleportOnDuty then
    local ped = PlayerPedId()
    RequestCollisionAtCoord(Config.Base.x, Config.Base.y, Config.Base.z)
    SetEntityCoordsNoOffset(ped, Config.Base.x, Config.Base.y, Config.Base.z, false, false, false)
    SetEntityHeading(ped, Config.Base.heading)
  end
  message(Config.Base.name .. '. F6 menu, F7 COPOM, F9 garagem, K arma.')
end)

local function applyFleetAppearance(vehicle, entry)
  SetVehicleModKit(vehicle, 0)
  local livery = entry.livery
  if type(livery) == 'number' and livery >= 0 and livery % 1 == 0
    and livery < GetVehicleLiveryCount(vehicle) then
    SetVehicleLivery(vehicle, livery)
  end
  local modLivery = entry.modLivery
  if type(modLivery) == 'number' and modLivery >= 0 and modLivery % 1 == 0
    and modLivery < GetNumVehicleMods(vehicle, 48) then
    SetVehicleMod(vehicle, 48, modLivery, false)
  end
  for id, enabled in pairs(entry.extras or {}) do
    local extra = tonumber(id)
    if extra and extra >= 0 and extra <= 20 and extra % 1 == 0
      and type(enabled) == 'boolean' and DoesExtraExist(vehicle, extra) then
      SetVehicleExtra(vehicle, extra, not enabled)
    end
  end
  if entry.demoColours then
    SetVehicleCustomPrimaryColour(vehicle, 245, 245, 245)
    SetVehicleCustomSecondaryColour(vehicle, 17, 55, 103)
  end
end

local function spawnAreaClear(x, y, z)
  for _, vehicle in ipairs(GetGamePool('CVehicle')) do
    if vehicle ~= patrol and DoesEntityExist(vehicle) then
      local p = GetEntityCoords(vehicle)
      local dx, dy, dz = p.x - x, p.y - y, p.z - z
      if dx * dx + dy * dy + dz * dz < 3.0 * 3.0 then return false end
    end
  end
  return true
end

RegisterNetEvent('prfrp:spawnPatrol', function(model)
  if not onDuty or spawning or type(model) ~= 'string' then return end
  local entry = nil
  for _, vehicle in ipairs(Config.Fleet or {}) do
    if vehicle.model == model then entry = vehicle; break end
  end
  if not entry then return end
  if entry.resource and entry.resource ~= '' and GetResourceState(entry.resource) ~= 'started' then
    message('Resource do veiculo indisponivel: ' .. entry.resource)
    return
  end
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    message('Desembarque antes de solicitar outro veiculo.')
    return
  end
  spawning = true
  local generation = spawnGeneration
  local hash = loadModel(model)
  spawning = false
  if generation ~= spawnGeneration or not onDuty then
    if hash then SetModelAsNoLongerNeeded(hash) end
    return
  end
  if not hash or not IsModelAVehicle(hash) then
    if hash then SetModelAsNoLongerNeeded(hash) end
    message('Modelo de veiculo indisponivel: ' .. model .. '. Confira o pacote e o nome de spawn.')
    return
  end
  local player = PlayerPedId()
  if IsPedInAnyVehicle(player, false) then
    SetModelAsNoLongerNeeded(hash)
    message('Desembarque antes de solicitar outro veiculo.')
    return
  end
  if patrol ~= 0 and DoesEntityExist(patrol) then
    if not NetworkHasControlOfEntity(patrol) then
      SetModelAsNoLongerNeeded(hash)
      message('Seu veiculo anterior esta sob controle de outro jogador.')
      return
    end
    for seat = -1, GetVehicleMaxNumberOfPassengers(patrol) - 1 do
      if not IsVehicleSeatFree(patrol, seat, true) then
        SetModelAsNoLongerNeeded(hash)
        message('Aguarde todos desembarcarem do veiculo anterior.')
        return
      end
    end
  end
  local p = GetEntityCoords(player)
  local heading = GetEntityHeading(player)
  local spawnX, spawnY, spawnZ = p.x + 3.0, p.y + 2.0, p.z
  local bx, by = p.x - Config.Base.x, p.y - Config.Base.y
  if bx * bx + by * by < 80 * 80 then
    spawnX, spawnY, spawnZ = Config.Garage.x, Config.Garage.y, Config.Garage.z
    heading = Config.Garage.heading
  end
  if not spawnAreaClear(spawnX, spawnY, spawnZ) then
    SetModelAsNoLongerNeeded(hash)
    message('Libere a area da garagem para receber o veiculo.')
    return
  end
  local nextPatrol = CreateVehicle(hash, spawnX, spawnY, spawnZ, heading, true, false)
  if nextPatrol == 0 or not DoesEntityExist(nextPatrol) then
    message('Falha ao criar o veiculo. Seu veiculo anterior foi preservado.')
    SetModelAsNoLongerNeeded(hash)
    return
  end
  SetEntityAsMissionEntity(nextPatrol, true, true)
  if patrol ~= 0 and DoesEntityExist(patrol) then
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
    if DoesEntityExist(patrol) then
      DeleteVehicle(nextPatrol)
      SetModelAsNoLongerNeeded(hash)
      message('Nao foi possivel recolher o veiculo anterior. Tente novamente.')
      return
    end
  end
  patrol = nextPatrol
  SetVehicleOnGroundProperly(patrol)
  SetVehicleNumberPlateText(patrol, Config.Plate)
  SetVehicleDirtLevel(patrol, 0.0)
  applyFleetAppearance(patrol, entry)
  SetVehicleEngineOn(patrol, true, true, false)
  SetPedIntoVehicle(player, patrol, -1)
  SetModelAsNoLongerNeeded(hash)
  message((entry.name or model) .. ' disponibilizada. F7: novo chamado COPOM.')
  TriggerEvent('prfrp:squadVehicleChanged')
end)

RegisterNetEvent('prfrp:routeBase', function()
  if not onDuty then return end
  if Config.Base.mapResource and Config.Base.mapResource ~= ''
    and GetResourceState(Config.Base.mapResource) ~= 'started' then
    message('Mapa da base indisponivel.')
    return
  end
  SetNewWaypoint(Config.Base.x, Config.Base.y)
  message(Config.Base.name .. ' marcada no GPS.')
end)

RegisterNetEvent('prfrp:setCall', function(data)
  cleanupCall()
  if not onDuty or type(data) ~= 'table' then return end
  if type(data.x) ~= 'number' or type(data.y) ~= 'number'
    or type(data.z) ~= 'number' or type(data.id) ~= 'string' then return end
  call = data
  call.stage = data.stage or 1
  routeBlip = AddBlipForCoord(data.x, data.y, data.z)
  SetBlipSprite(routeBlip, 1)
  SetBlipColour(routeBlip, 5)
  SetBlipScale(routeBlip, 0.95)
  SetBlipRoute(routeBlip, true)
  SetBlipRouteColour(routeBlip, 5)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString('PRF | ' .. data.id)
  EndTextCommandSetBlipName(routeBlip)
  SetNewWaypoint(data.x, data.y)
  message(data.details or data.name or 'Ocorrencia registrada no GPS.')
  if type(data.steps) == 'table' and data.steps[1] then
    message('Etapa 1/' .. #data.steps .. ': ' .. data.steps[1])
  end
end)

RegisterNetEvent('prfrp:setCallStage', function(id, stage)
  if call and call.id == id and type(stage) == 'number'
    and stage >= 1 and stage <= #(call.steps or {}) then
    call.stage = stage
    message('Etapa ' .. stage .. '/' .. #call.steps .. ': ' .. call.steps[stage])
  end
end)

CreateThread(function()
  stationBlip = AddBlipForCoord(Config.Base.x, Config.Base.y, Config.Base.z)
  SetBlipSprite(stationBlip, 60)
  SetBlipColour(stationBlip, 3)
  SetBlipScale(stationBlip, 0.8)
  SetBlipAsShortRange(stationBlip, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString('PRF RP | ' .. Config.Base.name)
  EndTextCommandSetBlipName(stationBlip)

  while true do
    local sleep = 1000
    if onDuty and call then
      local ped = PlayerPedId()
      local p = GetEntityCoords(ped)
      local dx = p.x - call.x
      local dy = p.y - call.y
      local dz = p.z - call.z
      local squareDistance = dx * dx + dy * dy + dz * dz

      if squareDistance < 100 * 100 and citizen == 0 then
        local model = loadModel(call.pedModel or 'a_m_m_farmer_01')
        if model then
          citizen = CreatePed(4, model, call.x + 3.0, call.y + 3.0,
            call.z, 90.0, false, true)
          if citizen ~= 0 and DoesEntityExist(citizen) then
            SetEntityInvincible(citizen, true)
            SetBlockingOfNonTemporaryEvents(citizen, true)
            TaskStartScenarioInPlace(citizen, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
          end
          SetModelAsNoLongerNeeded(model)
        end
      end

      if squareDistance < 50 * 50 then
        sleep = 0
        DrawMarker(1, call.x, call.y, call.z - 1.05,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          3.5, 3.5, 1.15, 233, 196, 61, 150,
          false, false, 2, false, nil, nil, false)
        if squareDistance < 14 * 14 then
          BeginTextCommandDisplayHelp('STRING')
          local stage = call.stage or 1
          local total = #(call.steps or {})
          local current = (call.steps or {})[stage] or 'Concluir ocorrencia'
          BeginTextCommandDisplayHelp('STRING')
          AddTextComponentSubstringPlayerName(
            'PRF ' .. call.id .. ' | ' .. stage .. '/' .. total ..
            ' - ' .. current .. ' | Pressione ~INPUT_CONTEXT~')
          EndTextCommandDisplayHelp(0, false, true, -1)
          if IsControlJustReleased(0, 38) and GetGameTimer() - lastComplete > 1800 then
            lastComplete = GetGameTimer()
            if stage < total then
              TriggerServerEvent('prfrp:advanceCall', call.id, stage)
            else
              TriggerServerEvent('prfrp:completeCall', call.id)
            end
          end
        end
      end
    end
    Wait(sleep)
  end
end)

AddEventHandler('onResourceStop', function(name)
  if name ~= GetCurrentResourceName() then return end
  spawnGeneration = spawnGeneration + 1
  cleanupCall()
  if stationBlip then RemoveBlip(stationBlip) end
  if patrol ~= 0 and DoesEntityExist(patrol) then
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
  end
  onDuty = false
end)
