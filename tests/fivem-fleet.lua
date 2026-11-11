-- Behavioral checks of the real standalone Lua scripts with mocked Cfx natives.
-- Run from repository root: lua5.4 tests/fivem-fleet.lua
local root = 'fivem/resources/[prf]/prf_core/'
local function runFile(name, env)
  local chunk, err = loadfile(root .. name, 't', env)
  assert(chunk, err)
  return chunk()
end
local function check(name, callback)
  local ok, err = pcall(callback)
  if not ok then error(name .. ': ' .. tostring(err), 0) end
  print('ok - ' .. name)
end
local function server()
  local commands, events, states, allowed = {}, {}, {}, {}
  local now = 1000
  local env = setmetatable({
    RegisterCommand = function(name, callback) commands[name] = callback end,
    RegisterNetEvent = function() end,
    AddEventHandler = function() end,
    TriggerClientEvent = function(name, src, ...)
      events[#events + 1] = { name = name, src = src, args = { ... } }
    end,
    IsPlayerAceAllowed = function(src, ace)
      assert(ace == 'prfrp.officer')
      return allowed[src] == true
    end,
    GetResourceState = function(name) return states[name] or 'missing' end,
    os = { time = function() return now end },
  }, { __index = _G })
  runFile('config.lua', env)
  runFile('server.lua', env)
  local function command(name, src)
    assert(commands[name], 'Missing command: ' .. name)
    commands[name](src or 1, {})
  end
  local function count(name)
    local n = 0
    for _, e in ipairs(events) do if e.name == name then n = n + 1 end end
    return n
  end
  return {
    env = env, events = events, states = states, allowed = allowed,
    command = command, count = count,
    advance = function() now = now + 20 end,
    duty = function() allowed[1] = true; command('prfservico') end,
  }
end

check('shipped configuration keeps stock vehicle and disables absent photo assets', function()
  local s = server()
  assert(s.env.Config.Vehicle == 'police3')
  assert(s.env.Config.Fleet.viatura.model == 'police3')
  assert(not s.env.Config.Fleet.moto.model)
  assert(not s.env.Config.Base.mapResource)
end)

check('fleet and base commands require ACE and duty', function()
  local s = server()
  for _, name in ipairs({ 'prfviatura', 'prfmoto', 'prfbase' }) do s.command(name) end
  assert(s.count('prfrp:spawnPatrol') == 0)
  assert(s.count('prfrp:routeBase') == 0)
  s.allowed[1] = true
  s.advance()
  for _, name in ipairs({ 'prfviatura', 'prfmoto', 'prfbase' }) do s.command(name) end
  assert(s.count('prfrp:spawnPatrol') == 0)
  assert(s.count('prfrp:routeBase') == 0)
end)

check('absent motorcycle reports unavailability without substituting a stock bike', function()
  local s = server()
  s.duty()
  local before = s.count('prfrp:notify')
  s.command('prfmoto')
  assert(s.count('prfrp:spawnPatrol') == 0)
  assert(s.count('prfrp:notify') > before)
end)

check('custom fleet requires its started resource and dispatches only configured keys', function()
  local s = server()
  s.env.Config.Fleet.moto.model = 'actual_bmw_model'
  s.env.Config.Fleet.moto.resource = 'actual_bmw_resource'
  s.duty()
  s.states.actual_bmw_resource = 'stopped'
  s.command('prfmoto')
  assert(s.count('prfrp:spawnPatrol') == 0)
  s.advance()
  s.states.actual_bmw_resource = 'started'
  s.command('prfmoto')
  assert(s.count('prfrp:spawnPatrol') == 1)
  local event = s.events[#s.events]
  assert(event.name == 'prfrp:spawnPatrol')
  assert(event.args[1] == 'moto', 'server must send allowlisted fleet key')
end)

check('shared cooldown prevents alternating commands to create multiple vehicles', function()
  local s = server()
  s.env.Config.Fleet.moto.model = 'actual_bmw_model'
  s.duty()
  s.command('prfviatura')
  s.command('prfmoto')
  assert(s.count('prfrp:spawnPatrol') == 1)
  s.advance()
  s.command('prfmoto')
  assert(s.count('prfrp:spawnPatrol') == 2)
end)

check('base GPS route waits for configured map resource', function()
  local s = server()
  s.duty()
  s.env.Config.Base.mapResource = 'actual_base_map'
  s.command('prfbase')
  assert(s.count('prfrp:routeBase') == 0)
  s.states.actual_base_map = 'started'
  s.advance()
  s.command('prfbase')
  assert(s.count('prfrp:routeBase') == 1)
end)

check('duty cannot teleport into an unavailable custom map', function()
  local s = server()
  s.env.Config.Base.mapResource = 'actual_base_map'
  s.duty()
  assert(s.count('prfrp:setDuty') == 0)
end)

local function client()
  local events, handlers, states, vehicles, created, deleted = {}, {}, {}, {}, {}, {}
  local loaded, missing, released, liveries, mods, extras = {}, {}, {}, {}, {}, {}
  local now, nextVehicle = 0, 100
  local behavior = {
    failCreate = false, inVehicle = false, blocked = false,
    control = true, seatFree = true, failedDeletion = false,
  }
  local env = setmetatable({
    RegisterNetEvent = function(name, callback) events[name] = callback end,
    AddEventHandler = function(name, callback) handlers[name] = callback end,
    CreateThread = function() end, -- Call/NPC loop is covered separately.
    GetResourceState = function(name) return states[name] or 'missing' end,
    PlayerPedId = function() return 1 end,
    GetGameTimer = function() return now end,
    Wait = function() now = now + 10; coroutine.yield() end,
    GetHashKey = function(name) return name end,
    IsModelInCdimage = function(hash) return not missing[hash] end,
    RequestModel = function() end,
    HasModelLoaded = function(hash) return loaded[hash] ~= false end,
    IsModelAVehicle = function() return true end,
    SetModelAsNoLongerNeeded = function(hash) released[hash] = true end,
    IsPedInAnyVehicle = function() return behavior.inVehicle end,
    GetOffsetFromEntityInWorldCoords = function() return { x = 3, y = 5, z = 1 } end,
    GetEntityHeading = function() return 0 end,
    IsAnyVehicleNearPoint = function() return behavior.blocked end,
    DoesEntityExist = function(id) return vehicles[id] == true end,
    CreateVehicle = function(hash)
      if behavior.failCreate then return 0 end
      nextVehicle = nextVehicle + 1
      vehicles[nextVehicle] = true
      created[#created + 1] = { id = nextVehicle, model = hash }
      return nextVehicle
    end,
    DeleteVehicle = function(id)
      if id ~= behavior.failedDeletion then vehicles[id] = false end
      deleted[#deleted + 1] = id
    end,
    NetworkHasControlOfEntity = function() return behavior.control end,
    GetVehicleMaxNumberOfPassengers = function() return 3 end,
    IsVehicleSeatFree = function() return behavior.seatFree end,
    GetVehicleLiveryCount = function() return 3 end,
    GetNumVehicleMods = function(_, slot) assert(slot == 48); return 2 end,
    DoesExtraExist = function(_, id) return id == 1 or id == 2 end,
    SetVehicleLivery = function(_, id) liveries[#liveries + 1] = id end,
    SetVehicleMod = function(_, slot, id) mods[#mods + 1] = { slot, id } end,
    SetVehicleExtra = function(_, id, disabled) extras[id] = disabled end,
    print = function() end,
  }, { __index = _G })
  for _, name in ipairs({
    'BeginTextCommandThefeedPost', 'AddTextComponentSubstringPlayerName',
    'EndTextCommandThefeedPostTicker', 'RequestCollisionAtCoord',
    'SetEntityCoordsNoOffset', 'SetEntityHeading', 'SetEntityAsMissionEntity',
    'SetVehicleModKit', 'SetVehicleOnGroundProperly', 'SetVehicleNumberPlateText',
    'SetVehicleDirtLevel', 'SetVehicleEngineOn', 'SetPedIntoVehicle',
    'RemoveBlip', 'DeletePed',
  }) do env[name] = function() end end
  runFile('config.lua', env)
  runFile('client.lua', env)
  local function emit(name, ...)
    assert(events[name], 'Missing event: ' .. name)
    local args = { ... }
    local thread = coroutine.create(function() events[name](table.unpack(args)) end)
    local ok, err = coroutine.resume(thread)
    assert(ok, err)
    return thread
  end
  emit('prfrp:setDuty', true)
  return {
    env = env, states = states, created = created, deleted = deleted, vehicles = vehicles,
    loaded = loaded, missing = missing, released = released,
    behavior = behavior, liveries = liveries, mods = mods, extras = extras,
    emit = emit,
    resume = function(thread)
      local ok, err = coroutine.resume(thread)
      assert(ok, err)
    end,
  }
end

check('client rejects arbitrary models, absent assets and unavailable resources', function()
  local c = client()
  c.emit('prfrp:spawnPatrol', 'arbitrary_model')
  c.emit('prfrp:spawnPatrol', 'moto')
  c.env.Config.Fleet.viatura.resource = 'actual_suv_resource'
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(#c.created == 0)
end)

check('client uses configured model and validates liveries and existing extras', function()
  local c = client()
  local entry = c.env.Config.Fleet.viatura
  entry.model, entry.livery, entry.modLivery = 'actual_suv_model', 2, 1
  entry.extras = { [1] = true, [2] = false, [3] = true, [21] = true, bad = true }
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(c.created[1].model == 'actual_suv_model')
  assert(c.liveries[1] == 2)
  assert(c.mods[1][1] == 48 and c.mods[1][2] == 1)
  assert(c.extras[1] == false and c.extras[2] == true)
  assert(c.extras[3] == nil and c.extras[21] == nil)
  entry.livery, entry.modLivery = 3, -1
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(#c.liveries == 1 and #c.mods == 1, 'invalid livery must be ignored')
end)

check('failed model load or entity creation preserves current vehicle', function()
  local c = client()
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(#c.created == 1)
  c.env.Config.Fleet.moto.model = 'actual_bmw_model'
  c.missing.actual_bmw_model = true
  c.emit('prfrp:spawnPatrol', 'moto')
  assert(#c.deleted == 0)
  c.missing.actual_bmw_model = false
  c.behavior.failCreate = true
  c.emit('prfrp:spawnPatrol', 'moto')
  assert(#c.deleted == 0)
  c.behavior.failCreate = false
  c.emit('prfrp:spawnPatrol', 'moto')
  assert(#c.created == 2 and #c.deleted == 1)
  assert(c.deleted[1] == c.created[1].id)
end)

check('concurrent requests cannot create duplicate vehicles during model loading', function()
  local c = client()
  c.loaded.police3 = false
  local pending = c.emit('prfrp:spawnPatrol', 'viatura')
  assert(coroutine.status(pending) == 'suspended')
  c.emit('prfrp:spawnPatrol', 'viatura')
  c.loaded.police3 = true
  c.resume(pending)
  assert(#c.created == 1)
end)

check('leaving duty cancels pending spawn even if duty restarts before load completes', function()
  local c = client()
  c.loaded.police3 = false
  local pending = c.emit('prfrp:spawnPatrol', 'viatura')
  c.emit('prfrp:setDuty', false)
  c.emit('prfrp:setDuty', true)
  c.loaded.police3 = true
  c.resume(pending)
  assert(#c.created == 0)
  assert(c.released.police3, 'cancelled model must be released')
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(#c.created == 1, 'a later request remains available')
end)

check('occupied spawn location and seated player prevent vehicle creation', function()
  local c = client()
  c.behavior.blocked = true
  c.emit('prfrp:spawnPatrol', 'viatura')
  c.behavior.blocked, c.behavior.inVehicle = false, true
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(#c.created == 0)
end)

check('vehicle replacement waits for empty seats and network control', function()
  local c = client()
  c.emit('prfrp:spawnPatrol', 'viatura')
  local previous = c.created[1].id
  c.behavior.seatFree = false
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(c.vehicles[previous] and #c.created == 1)
  c.behavior.seatFree, c.behavior.control = true, false
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(c.vehicles[previous] and #c.created == 1)
end)

check('failed deletion retains old handle and removes replacement to avoid duplicate fleet', function()
  local c = client()
  c.emit('prfrp:spawnPatrol', 'viatura')
  local previous = c.created[1].id
  c.behavior.failedDeletion = previous
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(c.vehicles[previous])
  assert(#c.created == 2 and not c.vehicles[c.created[2].id])
  c.behavior.failedDeletion = false
  c.emit('prfrp:spawnPatrol', 'viatura')
  assert(not c.vehicles[previous], 'retry must still track the original vehicle')
  assert(c.vehicles[c.created[3].id])
end)

print('FiveM fleet behavior: all checks passed')
