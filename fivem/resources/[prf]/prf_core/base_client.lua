-- Base operacional fictícia usando cenários e objetos nativos do GTA V.
-- Fardamento adicional carregado pelo recurso definido em Config.Uniform.
local active = false
local props = {}
local dressed = false
local originalModel = nil
local uniformBusy = false
local uniformGeneration = 0
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
  -- Limite da base standalone: restaura o modelo e roupas padrao, nao o rosto,
  -- cabelo, tatuagens ou todas as roupas personalizadas anteriores.
  if dressed and originalModel then
    if not IsModelInCdimage(originalModel) or not IsModelAPed(originalModel) then
      inform('Nao foi possivel carregar o modelo anterior do personagem.')
      return false
    end
    RequestModel(originalModel)
    local start = GetGameTimer()
    while not HasModelLoaded(originalModel) and GetGameTimer() - start < 5500 do
      Wait(0)
    end
    if HasModelLoaded(originalModel) then
      SetPlayerModel(PlayerId(), originalModel)
      SetPedDefaultComponentVariation(PlayerPedId())
      SetModelAsNoLongerNeeded(originalModel)
    else
      SetModelAsNoLongerNeeded(originalModel)
      inform('O modelo anterior nao carregou. Tente remover o uniforme novamente.')
      return false
    end
  end
  dressed, originalModel = false, nil
  return true
end

local collectionNatives = {
  'GetPedCollectionsCount', 'GetPedCollectionName',
  'IsPedCollectionComponentVariationValid',
  'GetNumberOfPedCollectionPropDrawableVariations',
  'GetNumberOfPedCollectionPropTextureVariations',
  'SetPedCollectionComponentVariation', 'SetPedCollectionPropIndex'
}

local function integer(value, minimum, maximum)
  return type(value) == 'number' and value % 1 == 0
    and value >= minimum and (not maximum or value <= maximum)
end

local function validateUniform(ped, profile)
  local collections = { [''] = true }
  for i = 0, GetPedCollectionsCount(ped) - 1 do
    collections[GetPedCollectionName(ped, i)] = true
  end
  for _, item in ipairs(profile.components) do
    if type(item) ~= 'table' or not integer(item.component, 0, 11)
      or type(item.collection) ~= 'string' or not collections[item.collection]
      or not integer(item.drawable, 0) or not integer(item.texture or 0, 0)
      or not integer(item.palette or 0, 0, 3)
      or not IsPedCollectionComponentVariationValid(ped, item.component,
        item.collection, item.drawable, item.texture or 0) then
      return false, 'Componente/colecao do uniforme indisponivel. Confira Config.Uniform e o game build.'
    end
  end
  for _, item in ipairs(profile.props) do
    if type(item) ~= 'table' or not integer(item.anchor, 0, 7)
      or type(item.collection) ~= 'string' or not collections[item.collection]
      or not integer(item.drawable, 0) or not integer(item.texture or 0, 0)
      or item.drawable >= GetNumberOfPedCollectionPropDrawableVariations(ped, item.anchor, item.collection)
      or (item.texture or 0) >= GetNumberOfPedCollectionPropTextureVariations(
        ped, item.anchor, item.collection, item.drawable) then
      return false, 'Bone/acessorio do uniforme indisponivel. Confira a colecao e o indice local.'
    end
  end
  return true
end

local function configuredUniform(generation)
  local uniform = Config.Uniform
  if type(uniform) ~= 'table' or type(uniform.resource) ~= 'string'
    or uniform.resource == '' or GetResourceState(uniform.resource) ~= 'started' then
    inform('Inicie o resource do uniforme configurado antes de usar o vestiario.')
    return
  end
  for _, native in ipairs(collectionNatives) do
    if type(_G[native]) ~= 'function' then
      inform('Natives de roupa por colecao indisponiveis. Atualize o FiveM/FXServer; uniforme nao aplicado.')
      return
    end
  end
  local original = GetEntityModel(PlayerPedId())
  local sex = uniform.defaultSex or 'male'
  if original == GetHashKey('mp_m_freemode_01') then sex = 'male'
  elseif original == GetHashKey('mp_f_freemode_01') then sex = 'female' end
  local expected = sex == 'male' and 'mp_m_freemode_01'
    or sex == 'female' and 'mp_f_freemode_01' or nil
  local profile = uniform[sex]
  if not expected or type(profile) ~= 'table' or profile.model ~= expected
    or type(profile.components) ~= 'table' or #profile.components == 0
    or type(profile.props) ~= 'table' then
    inform('Perfil freemode masculino/feminino invalido em Config.Uniform.')
    return
  end
  local model = GetHashKey(profile.model)
  if not IsModelInCdimage(model) or not IsModelAPed(model) then
    inform('Modelo freemode do uniforme indisponivel.')
    return
  end
  local hash = modelReady(profile.model)
  if not hash then
    SetModelAsNoLongerNeeded(model)
    inform('O modelo freemode nao carregou. Uniforme nao aplicado.')
    return
  end
  if not active or generation ~= uniformGeneration
    or GetEntityModel(PlayerPedId()) ~= original
    or IsPedInAnyVehicle(PlayerPedId(), false)
    or GetResourceState(uniform.resource) ~= 'started' then
    SetModelAsNoLongerNeeded(hash)
    return
  end
  -- Valida tudo no modelo correto ANTES de trocar o personagem ou suas roupas.
  local preview = 0
  local ped = PlayerPedId()
  if hash ~= original then
    local p = GetEntityCoords(ped)
    preview = CreatePed(4, hash, p.x, p.y, p.z - 100.0, 0.0, false, false)
    if preview == 0 or not DoesEntityExist(preview) then
      SetModelAsNoLongerNeeded(hash)
      inform('Nao foi possivel validar o uniforme no modelo freemode.')
      return
    end
    SetEntityVisible(preview, false, false)
    SetEntityCollision(preview, false, false)
    FreezeEntityPosition(preview, true)
    ped = preview
  end
  local ok, valid, reason = pcall(validateUniform, ped, profile)
  if preview ~= 0 then DeletePed(preview) end
  if not ok or not valid then
    SetModelAsNoLongerNeeded(hash)
    inform(ok and reason or 'Falha ao validar as colecoes. Uniforme nao aplicado.')
    return
  end
  originalModel = original
  if hash ~= original then SetPlayerModel(PlayerId(), hash) end
  ped = PlayerPedId()
  SetPedDefaultComponentVariation(ped)
  ClearAllPedProps(ped)
  for _, item in ipairs(profile.components) do
    SetPedCollectionComponentVariation(ped, item.component, item.collection,
      item.drawable, item.texture or 0, item.palette or 0)
  end
  for _, item in ipairs(profile.props) do
    SetPedCollectionPropIndex(ped, item.anchor, item.collection,
      item.drawable, item.texture or 0, true)
  end
  dressed = true
  SetModelAsNoLongerNeeded(hash)
  inform('Uniforme PRF de wlukaas equipado. F6 ou vestiario para remover.')
end

RegisterNetEvent('prfrp:setDuty', function(enabled)
  active = enabled == true
  if not active then
    uniformGeneration = uniformGeneration + 1
    restoreModel()
  else
    inform('Posto PRF RP: garagem, vestiario, COPOM e equipamentos marcados.')
  end
end)
RegisterNetEvent('prfrp:toggleUniform', function()
  if not active or uniformBusy then return end
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    inform('Saia da viatura antes de trocar o uniforme.')
    return
  end
  if dressed then
    uniformBusy = true
    local restored = restoreModel()
    uniformBusy = false
    if restored then
      inform('Uniforme removido. O modelo anterior foi restaurado (roupas customizadas podem mudar).')
    end
    return
  end
  if Config.Uniform then
    uniformBusy = true
    configuredUniform(uniformGeneration)
    uniformBusy = false
    return
  end
  local original = GetEntityModel(PlayerPedId())
  local model = GetHashKey('s_m_y_hwaycop_01')
  if not IsModelInCdimage(model) or not IsModelAPed(model) then
    inform('Modelo de policial GTA indisponivel.')
    return
  end
  uniformBusy = true
  local generation = uniformGeneration
  local hash = modelReady('s_m_y_hwaycop_01')
  uniformBusy = false
  if not hash then
    SetModelAsNoLongerNeeded(model)
    inform('Modelo de policial GTA indisponivel.')
    return
  end
  if not active or generation ~= uniformGeneration
    or IsPedInAnyVehicle(PlayerPedId(), false)
    or GetEntityModel(PlayerPedId()) ~= original then
    SetModelAsNoLongerNeeded(hash)
    return
  end
  originalModel = original
  SetPlayerModel(PlayerId(), hash)
  SetPedDefaultComponentVariation(PlayerPedId())
  dressed = true
  SetModelAsNoLongerNeeded(hash)
  inform('Uniforme rodoviario PROVISORIO do GTA V equipado; nao e farda oficial PRF.')
end)

CreateThread(function()
  local base = vector3(Config.Base.x, Config.Base.y, Config.Base.z)
  while true do
    local sleep = 1500
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
  removeProps()
  restoreModel()
  active = false
end)
