import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const root = 'fivem/resources/[prf]/prf_core/';
const read = file => readFileSync(root + file, 'utf8');

test('a garagem busca rua trafegável e não cria veículos no teto ou em coordenada fixa', () => {
  const client = read('client.lua');
  assert.match(client, /safeRoadSpawn\(p\)/);
  assert.match(client, /GetClosestVehicleNodeWithHeading\(/);
  assert.match(client, /IsAnyVehicleNearPoint\(/);
  assert.match(client, /if not road then/);
  assert.match(client, /IsEntityInAir\(patrol\)/);
  assert.match(client, /GetEntityHeightAboveGround\(patrol\)/);
  assert.doesNotMatch(client, /spawnX, spawnY, spawnZ = Config\.Garage\.x/);
});
test('menu F6 número 4 é uniforme; não aciona o início de serviço', () => {
  const keys = read('keys_client.lua');
  const config = read('config.lua');
  const base = read('base_client.lua');
  assert.match(keys, /RegisterCommand\('prfmenuitem' \.\. i, function\(\) choose\(index\)/);
  assert.match(keys, /RegisterKeyMapping\('prfmenuitem' \.\. i/);
  assert.match(keys, /'4  Equipar\/retirar uniforme'/);
  const actions = keys.slice(keys.indexOf('local actions = {'), keys.indexOf('local function choose('));
  assert.match(actions, /function\(\) request\('call'\) end,\s*function\(\) request\('uniform'\) end/);
  assert.match(base, /prfrp:toggleUniform/);
  assert.match(base, /SetPlayerModel\(PlayerId\(\), hash\)/);
  assert.match(config, /Config\.UniformModel = 's_m_y_hwaycop_01'/);
  assert.match(base, /TriggerEvent\('prfrp:uniformApplied'\)/);
});
test('três policiais recebem pistolas e defendem somente de agressão real', () => {
  const squad = read('squad_client.lua');
  const config = read('config.lua');
  assert.match(config, /Config\.Team = \{ 's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_m_y_hwaycop_01' \}/);
  assert.match(squad, /for index = 1, 3 do/);
  assert.match(squad, /GiveWeaponToPed\(officer, GetHashKey\('WEAPON_PISTOL'\)/);
  assert.match(squad, /AddEventHandler\('entityDamaged'/);
  assert.match(squad, /if victim ~= PlayerPedId\(\) and not isOfficer\(victim\) then return end/);
  assert.match(squad, /TaskCombatPed\(officer, pendingThreat/);
  assert.match(squad, /SetPedRelationshipGroupHash\(officer, GetPedRelationshipGroupHash\(player\)\)/);
  assert.match(squad, /TaskLeaveVehicle\(/);
  assert.match(squad, /if pendingThreat ~= 0 then/);
});
test('giroflex e sirene de veículos policiais têm comandos separados', () => {
  const client = read('client.lua');
  const keys = read('keys_client.lua');
  assert.match(client, /SetVehicleHasMutedSirens\(patrol, not sirenSoundEnabled\)/);
  assert.match(client, /SetVehicleSiren\(patrol, lightbarEnabled\)/);
  assert.match(client, /prfrp:toggleEmergencyLights/);
  assert.match(client, /prfrp:toggleSirenSound/);
  assert.match(keys, /'keyboard', 'L'\)/);
  assert.match(keys, /'keyboard', 'O'\)/);
});
test('controle de procurado só ocorre no turno e restaura estado ao sair', () => {
  const base = read('base_client.lua');
  const server = read('server.lua');
  assert.match(base, /if active then\s*-- Configuração apenas do jogador em serviço/);
  assert.match(base, /ClearPlayerWantedLevel\(PlayerId\(\)\)/);
  assert.match(base, /SetPoliceIgnorePlayer\(PlayerId\(\), true\)/);
  assert.match(base, /SetDispatchCopsForPlayer\(PlayerId\(\), false\)/);
  assert.match(base, /SetPoliceIgnorePlayer\(PlayerId\(\), false\)/);
  assert.match(base, /SetDispatchCopsForPlayer\(PlayerId\(\), true\)/);
  assert.match(server, /IsPlayerAceAllowed\(src, 'prfrp\.officer'\)/);
});
