-- Visual/ambientacao locais. Permissoes e validacao de ocorrencia sao do servidor.
local onDuty = false
local call = nil
local routeBlip = nil
local stationBlip = nil
local patrol = 0
local citizen = 0
local lastComplete = 0

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
  if not HasModelLoaded(hash) then return nil end
  return hash
end

local function cleanupCitizen()
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
    cleanupCall()
    return
  end
  if Config.TeleportOnDuty then
    local ped = PlayerPedId()
    RequestCollisionAtCoord(Config.Base.x, Config.Base.y, Config.Base.z)
    SetEntityCoordsNoOffset(ped, Config.Base.x, Config.Base.y, Config.Base.z, false, false, false)
    SetEntityHeading(ped, Config.Base.heading)
  end
  message('Base de testes: Delegacia Sandy Shores. /prfajuda para comandos.')
end)

RegisterNetEvent('prfrp:spawnPatrol', function(model, plate)
  if not onDuty or type(model) ~= 'string' or model ~= Config.Vehicle then return end
  local hash = loadModel(model)
  if not hash or not IsModelAVehicle(hash) then
    message('Modelo de viatura indisponivel: ' .. model)
    return
  end
  if patrol ~= 0 and DoesEntityExist(patrol) then
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
  end
  local player = PlayerPedId()
  local p = GetEntityCoords(player)
  local heading = GetEntityHeading(player)
  patrol = CreateVehicle(hash, p.x + 3.0, p.y + 2.0, p.z, heading, true, false)
  if patrol == 0 or not DoesEntityExist(patrol) then
    message('Falha ao criar a viatura.')
    SetModelAsNoLongerNeeded(hash)
    return
  end
  SetVehicleOnGroundProperly(patrol)
  SetVehicleNumberPlateText(patrol, plate or 'PRF RP')
  SetVehicleDirtLevel(patrol, 0.0)
  SetVehicleEngineOn(patrol, true, true, false)
  SetPedIntoVehicle(player, patrol, -1)
  SetEntityAsMissionEntity(patrol, true, true)
  SetModelAsNoLongerNeeded(hash)
  message('Viatura disponibilizada. Use /prfchamado para iniciar uma ocorrencia.')
end)

RegisterNetEvent('prfrp:setCall', function(data)
  cleanupCall()
  if not onDuty or type(data) ~= 'table' then return end
  if type(data.x) ~= 'number' or type(data.y) ~= 'number'
    or type(data.z) ~= 'number' or type(data.id) ~= 'string' then return end
  call = data
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
end)

CreateThread(function()
  stationBlip = AddBlipForCoord(Config.Base.x, Config.Base.y, Config.Base.z)
  SetBlipSprite(stationBlip, 60)
  SetBlipColour(stationBlip, 3)
  SetBlipScale(stationBlip, 0.8)
  SetBlipAsShortRange(stationBlip, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString('PRF RP | Base de testes')
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
        local model = loadModel('a_m_m_farmer_01')
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
          AddTextComponentSubstringPlayerName('Pressione ~INPUT_CONTEXT~ para concluir a ocorrencia PRF')
          EndTextCommandDisplayHelp(0, false, true, -1)
          if IsControlJustReleased(0, 38) and GetGameTimer() - lastComplete > 1800 then
            lastComplete = GetGameTimer()
            TriggerServerEvent('prfrp:completeCall', call.id)
          end
        end
      end
    end
    Wait(sleep)
  end
end)

AddEventHandler('onResourceStop', function(name)
  if name ~= GetCurrentResourceName() then return end
  cleanupCall()
  if stationBlip then RemoveBlip(stationBlip) end
  if patrol ~= 0 and DoesEntityExist(patrol) then
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
  end
  onDuty = false
end)
