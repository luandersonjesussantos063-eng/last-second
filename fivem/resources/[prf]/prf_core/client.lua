-- Visual/ambientacao locais. Permissoes e validacao de ocorrencia sao do servidor.
local onDuty = false
local call = nil
local routeBlip = nil
local stationBlip = nil
local customBaseBlip = nil
local patrol = 0
PrfGetPatrolVehicle = function()
  return patrol~=0 and DoesEntityExist(patrol) and patrol or 0
end
local citizen = 0
local lastComplete = 0
local sceneProps = {}
local lightbarEnabled = false
local sirenSoundEnabled = false
local placingAtBase = false
local baseSpawnPed = 0

local function message(value)
  local text = 'PRF RP: ' .. tostring(value)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandThefeedPostTicker(false, false)
  print('[PRF RP] ' .. tostring(value))
  TriggerEvent('prfrp:chatNotice',value)
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

-- Localiza uma via trafegável, em vez de usar o telhado/garagem visual da delegacia.
-- Se o pathfinding não encontrar rua válida, NÃO cria a viatura no local errado.
local function safeRoadSpawn(playerCoords)
  local seeds = {
    playerCoords,
    GetResourceState(Config.CustomBaseResource) == 'started' and Config.CustomBase or Config.Garage
  }
  for _, at in ipairs(seeds) do
    RequestCollisionAtCoord(at.x, at.y, at.z)
    local found, road, heading = GetClosestVehicleNodeWithHeading(
      at.x, at.y, at.z, 1, 3.0, 0)
    if found and road and heading and math.abs(road.z - playerCoords.z) < 7.0
       and (road.x-playerCoords.x)^2+(road.y-playerCoords.y)^2 < 80^2
       and not IsAnyVehicleNearPoint(road.x, road.y, road.z, 4.5) then
      return road, heading
    end
  end
  return nil, nil
end

local function setEmergency(lights, sound)
  lightbarEnabled = lights == true
  sirenSoundEnabled = lightbarEnabled and sound == true
  if patrol ~= 0 and DoesEntityExist(patrol) and GetVehicleClass(patrol) == 18 then
    -- Sirene GTA: o nativo liga o giroflex e 'muted' separa som de luzes.
    SetVehicleHasMutedSirens(patrol, not sirenSoundEnabled)
    SetVehicleSiren(patrol, lightbarEnabled)
  else
    lightbarEnabled, sirenSoundEnabled = false, false
  end
end

AddEventHandler('prfrp:toggleEmergencyLights', function()
  if not onDuty or patrol == 0 or not DoesEntityExist(patrol) then
    message('Pegue uma viatura policial primeiro.')
    return
  end
  setEmergency(not lightbarEnabled, false)
  message(lightbarEnabled and 'Giroflex ligado (sem som).' or 'Giroflex desligado.')
end)

AddEventHandler('prfrp:toggleSirenSound', function()
  if not onDuty or patrol == 0 or not DoesEntityExist(patrol) then
    message('Pegue uma viatura policial primeiro.')
    return
  end
  setEmergency(true, not sirenSoundEnabled)
  message(sirenSoundEnabled and 'Sirene ligada.' or 'Sirene em silencio; giroflex ligado.')
end)

-- Mapa PRF de LN3D3V: blip e rota só aparecem se o recurso do mapa estiver ativo.
-- Não muda o teleporte de serviço, para evitar nascimento em telhado.
local function refreshCustomBaseBlip()
  local installed = GetResourceState(Config.CustomBaseResource) == 'started'
  if not installed then
    if customBaseBlip then
      RemoveBlip(customBaseBlip)
      customBaseBlip = nil
    end
    return false
  end
  if not customBaseBlip then
    local base = Config.CustomBase
    customBaseBlip = AddBlipForCoord(base.x, base.y, base.z)
    SetBlipSprite(customBaseBlip, 60)
    SetBlipColour(customBaseBlip, 5)
    SetBlipScale(customBaseBlip, 0.95)
    SetBlipAsShortRange(customBaseBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('PRF RP | Nova base Chumash')
    EndTextCommandSetBlipName(customBaseBlip)
  end
  return true
end

RegisterCommand('prfbase', function()
  if not refreshCustomBaseBlip() then
    message('Base PRF nova nao carregada. No txAdmin: refresh; depois ensure prfMiniLN3d3v. Verifique /assetpacks.')
    return
  end
  local base = Config.CustomBase
  SetNewWaypoint(base.x, base.y)
  message('Rota para base PRF de Chumash marcada no GPS. Siga a Great Ocean Highway.')
end, false)
RegisterKeyMapping('prfbase', 'PRF RP: marcar nova base no GPS (Chumash)', 'keyboard', 'F10')

CreateThread(function()
  while true do
    refreshCustomBaseBlip()
    Wait(5000)
  end
end)

RegisterNetEvent('prfrp:notify', message)

local function placeAtBase()
  if placingAtBase or Config.SpawnAtBase == false then return end
  placingAtBase = true
  local custom = GetResourceState(Config.CustomBaseResource) == 'started'
  local target = custom and Config.SpawnBase or Config.Base
  local started = GetGameTimer()
  local groundFound = false
  baseSpawnPed = PlayerPedId()
  FreezeEntityPosition(baseSpawnPed, true)
  RequestCollisionAtCoord(target.x, target.y, target.z)
  SetEntityCoordsNoOffset(baseSpawnPed, target.x, target.y, target.z, false, false, false)
  repeat
    local ped = PlayerPedId()
    if ped ~= baseSpawnPed then
      if DoesEntityExist(baseSpawnPed) then FreezeEntityPosition(baseSpawnPed, false) end
      baseSpawnPed = ped
      FreezeEntityPosition(ped, true)
      SetEntityCoordsNoOffset(ped, target.x, target.y, target.z, false, false, false)
    end
    RequestCollisionAtCoord(target.x, target.y, target.z)
    local found, ground = GetGroundZFor_3dCoord(target.x, target.y, target.z + 1.0, false)
    if found and math.abs(ground - (target.z - 1.0)) <= 3.0
      and HasCollisionLoadedAroundEntity(ped) then
      SetEntityCoordsNoOffset(ped, target.x, target.y, ground + 1.0, false, false, false)
      SetEntityHeading(ped, target.heading or 0.0)
      groundFound = true
      break
    end
    Wait(0)
  until GetGameTimer() - started >= 8000
  if not groundFound then
    local fallback = Config.Base
    local ped = PlayerPedId()
    RequestCollisionAtCoord(fallback.x, fallback.y, fallback.z)
    SetEntityCoordsNoOffset(ped, fallback.x, fallback.y, fallback.z, false, false, false)
    SetEntityHeading(ped, fallback.heading)
    message('O piso da base nova nao carregou. Retorno ao posto de Sandy Shores.')
  elseif not custom then
    message('Mapa PRF parado: nascimento no posto provisório de Sandy Shores.')
  end
  if DoesEntityExist(baseSpawnPed) then FreezeEntityPosition(baseSpawnPed, false) end
  FreezeEntityPosition(PlayerPedId(), false)
  baseSpawnPed, placingAtBase = 0, false
  TriggerEvent('prfrp:baseArrival')
end

AddEventHandler('playerSpawned', function()
  CreateThread(placeAtBase)
end)

RegisterNetEvent('prfrp:setDuty', function(enabled)
  onDuty = enabled == true
  if not onDuty then
    cleanupCall()
    setEmergency(false, false)
    return
  end
  if Config.TeleportOnDuty then
    placeAtBase()
  end
  message('Servico PRF iniciado. T > viatura | fuzil | abordar | ajuda')
end)

RegisterNetEvent('prfrp:spawnPatrol', function(model, plate)
  if not onDuty or type(model) ~= 'string' then return end
  local selected
  for _, vehicle in ipairs(Config.Fleet or {}) do
    if vehicle.model == model then selected = vehicle; break end
  end
  if not selected then return end
  if selected.resource and GetResourceState(selected.resource) ~= 'started'
    and (not selected.alternateResource or GetResourceState(selected.alternateResource) ~= 'started') then
    message('Viatura PRF nao carregada. Reinicie o servidor apos executar setup-prf-update.cmd.')
    return
  end
  local hash = loadModel(model)
  if not hash or not IsModelAVehicle(hash) then
    message('Modelo de viatura indisponivel: ' .. model)
    return
  end
  local player = PlayerPedId()
  local p = GetEntityCoords(player)
  local road, heading = safeRoadSpawn(p)
  if not road then
    SetModelAsNoLongerNeeded(hash)
    message('Garagem sem rua livre/carregada. Saia do edificio e tente F9 novamente.')
    return
  end
  -- Não apaga a viatura anterior até confirmar que há ponto seguro.
  if patrol ~= 0 and DoesEntityExist(patrol) then
    setEmergency(false, false)
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
  end
  patrol = CreateVehicle(hash, road.x, road.y, road.z + 1.0, heading, true, false)
  if patrol == 0 or not DoesEntityExist(patrol) then
    message('Falha ao criar a viatura.')
    SetModelAsNoLongerNeeded(hash)
    return
  end
  RequestCollisionAtCoord(road.x, road.y, road.z)
  for attempt = 1, 8 do
    Wait(80)
    SetVehicleOnGroundProperly(patrol)
    if not IsEntityInAir(patrol) and GetEntityHeightAboveGround(patrol) < 2.0 then
      break
    end
  end
  -- Evita apresentar como pronto um carro suspenso em cobertura/estrutura.
  if IsEntityInAir(patrol) or GetEntityHeightAboveGround(patrol) > 2.5 then
    DeleteVehicle(patrol)
    patrol = 0
    message('Nao foi possivel assentar a viatura no asfalto. Tente outra area.')
    SetModelAsNoLongerNeeded(hash)
    return
  end
  SetVehicleNumberPlateText(patrol, plate or 'PRF RP')
  SetVehicleDirtLevel(patrol, 0.0)
  -- A viatura personalizada mantem as cores e a pintura do modelo original.
  if not selected.preservePaint and model ~= 'policeb' then
    SetVehicleCustomPrimaryColour(patrol, 245, 245, 245)
    SetVehicleCustomSecondaryColour(patrol, 17, 55, 103)
  end
  SetVehicleEngineOn(patrol, true, true, false)
  -- Modelos de emergência originais usam luzes/sirene padrão do próprio GTA.
  setEmergency(false, false)
  SetPedIntoVehicle(player, patrol, -1)
  SetEntityAsMissionEntity(patrol, true, true)
  SetModelAsNoLongerNeeded(hash)
  message((selected.name or model) .. ' pronta. L: giroflex | O: sirene | F7: COPOM.')
  TriggerEvent('prfrp:squadVehicleChanged')
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
  AddTextComponentString('PRF RP | Posto rodoviario')
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
  if baseSpawnPed ~= 0 and DoesEntityExist(baseSpawnPed) then FreezeEntityPosition(baseSpawnPed, false) end
  baseSpawnPed, placingAtBase = 0, false
  cleanupCall()
  setEmergency(false, false)
  if stationBlip then RemoveBlip(stationBlip) end
  if customBaseBlip then RemoveBlip(customBaseBlip) end
  if patrol ~= 0 and DoesEntityExist(patrol) then
    SetEntityAsMissionEntity(patrol, true, true)
    DeleteVehicle(patrol)
  end
  onDuty = false
end)
