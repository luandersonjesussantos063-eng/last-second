-- Base operacional fictícia usando cenários e objetos nativos do GTA V.
-- Não contém MLO nem arquitetura/insígnias oficiais PRF.
local active = false
local props = {}
local dressed = false
local originalModel = nil
local lastWantedUpdate = 0
local skinNotified = false
local uniformGeneration = 0
local uniformBusy = nil
local zones = {
  { coord = Config.Garage, name = 'GARAGEM | E: viatura', action = 'vehicle' },
  { coord = Config.Wardrobe, name = 'VESTIARIO | E: uniforme', action = 'uniform' },
  { coord = Config.Dispatch, name = 'COPOM | E: ocorrencia', action = 'call' },
  { coord = Config.Armory, name = 'EQUIPAMENTOS | E: arma', action = 'weapon' }
}

local function hint(value)
  BeginTextCommandDisplayHelp('STRING')
  AddTextComponentSubstringPlayerName(value)
  EndTextCommandDisplayHelp(0, false, true, -1)
end
local function inform(value)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName('PRF RP: ' .. value)
  EndTextCommandThefeedPostTicker(false, false)
end
local function squared(a, b)
  local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
  return dx * dx + dy * dy + dz * dz
end
local function modelReady(name)
  local hash = GetHashKey(name)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local start = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - start < 6500 do
    Wait(0)
  end
  if HasModelLoaded(hash) then return hash end
  return nil
end
local function removeProps()
  for _, object in ipairs(props) do
    if object ~= 0 and DoesEntityExist(object) then
      SetEntityAsMissionEntity(object, true, true)
      DeleteObject(object)
    end
  end
  props = {}
end
local function buildProps()
  if #props ~= 0 then return end
  for _, item in ipairs(Config.BaseProps or {}) do
    local hash = modelReady(item.model)
    if hash then
      local obj = CreateObject(hash, item.x, item.y, item.z, false, false, false)
      if obj ~= 0 and DoesEntityExist(obj) then
        SetEntityHeading(obj, item.heading or 0.0)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        props[#props + 1] = obj
      end
      SetModelAsNoLongerNeeded(hash)
    end
  end
end

local function restoreModel()
  if dressed and originalModel then
    RequestModel(originalModel)
    local start = GetGameTimer()
    while not HasModelLoaded(originalModel) and GetGameTimer() - start < 5500 do
      Wait(0)
    end
    if HasModelLoaded(originalModel) then
      SetPlayerModel(PlayerId(), originalModel)
      SetPedDefaultComponentVariation(PlayerPedId())
      SetModelAsNoLongerNeeded(originalModel)
    end
  end
  dressed, originalModel = false, nil
  TriggerEvent('prfrp:uniformApplied')
end

local function hasPrfSkin()
  return GetResourceState(Config.PRFSkinResource or 'prf_skin_replace') == 'started'
end

local function putOnUniform()
  if not active or dressed then return end
  if uniformBusy == uniformGeneration then return end
  if not hasPrfSkin() then
    if not skinNotified then
      inform('Farda PRF nao instalada. Execute setup-prf-skin.cmd e ensure prf_skin_replace.')
      skinNotified = true
    end
    return
  end
  local oldPed = PlayerPedId()
  if IsPedInAnyVehicle(oldPed, false) then
    inform('Saia da viatura para trocar a farda da PRF.')
    return
  end
  local token = uniformGeneration
  uniformBusy = token
  local hash = modelReady(Config.PRFSkinModel)
  if uniformBusy == token then uniformBusy = nil end
  if not hash then
    inform('Skin PRF indisponivel. Confira prf_skin_replace no txAdmin.')
    return
  end
  if not active or token ~= uniformGeneration or oldPed ~= PlayerPedId()
    or IsPedInAnyVehicle(oldPed,false) or IsEntityDead(oldPed) then
    SetModelAsNoLongerNeeded(hash)
    return
  end
  originalModel = originalModel or GetEntityModel(oldPed)
  local coords, heading = GetEntityCoords(oldPed), GetEntityHeading(oldPed)
  SetPlayerModel(PlayerId(), hash)
  local uniformPed = PlayerPedId()
  SetEntityCoordsNoOffset(uniformPed, coords.x, coords.y, coords.z, false, false, false)
  SetEntityHeading(uniformPed, heading)
  SetPedDefaultComponentVariation(uniformPed)
  dressed = true
  SetModelAsNoLongerNeeded(hash)
  TriggerEvent('prfrp:uniformApplied')
  inform('Farda PRF personalizada equipada. T > farda para alternar.')
end

RegisterNetEvent('prfrp:setDuty', function(enabled)
  active = enabled == true
  if not active then
    uniformGeneration = uniformGeneration + 1
    uniformBusy = nil
    SetPoliceIgnorePlayer(PlayerId(), false)
    SetDispatchCopsForPlayer(PlayerId(), true)
    restoreModel()
    skinNotified = false
  else
    ClearPlayerWantedLevel(PlayerId())
    SetPoliceIgnorePlayer(PlayerId(), true)
    SetDispatchCopsForPlayer(PlayerId(), false)
    inform('Posto PRF RP: garagem, vestiario, COPOM e equipamentos marcados.')
    -- Servico autorizado pelo FXServer: entra de farda se o mod estiver iniciado.
    putOnUniform()
  end
end)

AddEventHandler('playerSpawned', function()
  uniformGeneration = uniformGeneration + 1
  uniformBusy = nil
  dressed = false
  if active then
    local token = uniformGeneration
    CreateThread(function()
      Wait(200)
      if active and token == uniformGeneration then putOnUniform() end
    end)
  else originalModel = nil end
end)

RegisterNetEvent('prfrp:toggleUniform', function()
  if not active then return end
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    inform('Saia da viatura antes de trocar a farda.')
    return
  end
  if dressed then
    restoreModel()
    inform('Farda retirada. T > farda para vestir novamente.')
  else
    putOnUniform()
  end
end)

CreateThread(function()
  local base = vector3(Config.Base.x, Config.Base.y, Config.Base.z)
  while true do
    local sleep = 1500
    if active then
      -- Configuração apenas do jogador em serviço. Sem mudar leis dos demais.
      SetPoliceIgnorePlayer(PlayerId(), true)
      SetDispatchCopsForPlayer(PlayerId(), false)
      if GetPlayerWantedLevel(PlayerId()) > 0 then
        ClearPlayerWantedLevel(PlayerId())
      end
    end
    local coords = GetEntityCoords(PlayerPedId())
    local dist = squared(coords, base)
    if dist < 120.0 * 120.0 then
      buildProps()
    else
      removeProps()
    end
    if active and dist < 40.0 * 40.0 then
      sleep = 0
      for _, zone in ipairs(zones) do
        local d = squared(coords, zone.coord)
        if d < 30.0 * 30.0 then
          DrawMarker(1, zone.coord.x, zone.coord.y, zone.coord.z - 0.9,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            1.1, 1.1, 0.6, 20, 80, 150, 150,
            false, false, 2, false, nil, nil, false)
          if d < 2.5 * 2.5 then
            hint('PRF RP | ' .. zone.name)
            if IsControlJustReleased(0, 38) then
              TriggerServerEvent('prfrp:requestAction', zone.action)
              Wait(250)
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
  uniformGeneration = uniformGeneration + 1
  uniformBusy = nil
  removeProps()
  SetPoliceIgnorePlayer(PlayerId(), false)
  SetDispatchCopsForPlayer(PlayerId(), true)
  restoreModel()
  active = false
end)
