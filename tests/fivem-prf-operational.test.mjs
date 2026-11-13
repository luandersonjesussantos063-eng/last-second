import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

const base = 'fivem/resources/[prf]/prf_core/';
const read = name => readFileSync(base + name, 'utf8');
const files = ['fxmanifest.lua','config.lua','client.lua','base_client.lua','keys_client.lua','squad_client.lua','operations_client.lua','operations_config.lua','server.lua','operations_server.lua','people_client.lua','people_server.lua','commands_client.lua','commands_server.lua','backup_client.lua','backup_server.lua','traffic_client.lua','gameplay_config.lua','base_stream_client.lua','progress_server.lua','inventory_client.lua','inventory_server.lua','tablet_client.lua','services_client.lua','services_server.lua','blitz_client.lua','blitz_server.lua','html/index.html','html/style.css','html/app.js'];

test('release FiveM Legacy v0.7.0 registra todos os scripts e instaladores completos', () => {
  const manifest = read('fxmanifest.lua');
  for (const file of files) {
    assert(existsSync(base + file), file);
    if (file.endsWith('.lua') && file !== 'fxmanifest.lua') assert(manifest.includes("'" + file + "'"), file);
  }
  assert.match(manifest, /version '0\.7\.0'/);
  for (const installer of ['fivem/scripts/install-prf.ps1','fivem/scripts/install-prf-enhanced.ps1']) {
    const content = readFileSync(installer, 'utf8');
    for (const file of files) assert(content.includes("'" + file + "'"), installer + ': ' + file);
  }
});
test('posto PRF provisório e frota nativa sem integração financeira ou SQL', () => {
  const config = read('config.lua');
  const baseClient = read('base_client.lua');
  assert.match(config, /Config\.Garage =/);
  assert.match(config, /Config\.Wardrobe =/);
  assert.match(config, /Config\.Dispatch =/);
  assert.match(config, /Config\.Armory =/);
  for (const model of ['police3','police2','sheriff2','policeb']) assert(config.includes(model));
  assert.match(baseClient, /CreateObject\(/);
  assert.match(baseClient, /DeleteObject\(/);
  assert.match(baseClient, /Config\.PRFSkinModel/);
  assert.doesNotMatch(read('server.lua'), /MySQL|INSERT INTO|sv_licenseKey/);
});
test('exatamente três policiais NPC entram na viatura e acompanham a pé, com limpeza', () => {
  const config = read('config.lua');
  const squad = read('squad_client.lua');
  assert.match(config, /Config\.Team = \{ 's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_m_y_hwaycop_01' \}/);
  assert.match(squad, /for index = 1, 3 do/);
  assert.match(squad, /CreatePed\(/);
  assert.match(squad, /TaskFollowToOffsetOfEntity\(/);
  assert.match(squad, /SetPedIntoVehicle\(/);
  assert.match(squad, /GetVehicleMaxNumberOfPassengers\(/);
  assert.match(squad, /prfrp:squadRally/);
  assert.match(squad, /DeletePed\(/);
  assert.match(squad, /Wait\(1700\)/);
});
test('atalhos diretos permanecem disponiveis sem paineis ou captura dos numeros', () => {
  const keys = read('keys_client.lua');
  const server = read('server.lua');
  for (const key of ['F5','F7','F9','J','K']) {
    assert.match(keys, new RegExp("RegisterKeyMapping\\([^\\n]*'keyboard', '" + key + "'\\)"));
  }
  for (const action of ['duty','vehicle','call','cancel','status','uniform','weapon']) assert(server.includes("'" + action + "'"));
  assert.match(server, /IsPlayerAceAllowed\(src, 'prfrp\.officer'\)/);
  assert.match(server, /if not requireDuty\(src\) or throttle\(src, action, 1\) then return end/);
  assert.doesNotMatch(keys, /DrawRect|RegisterKeyMapping\('prfmenuitem'/);
});
test('ocorrências com etapas são validadas em servidor antes da conclusão', () => {
  const config = read('config.lua'), server = read('server.lua'), client = read('client.lua');
  assert.equal((config.match(/id = 'PRF-/g) || []).length, 6);
  assert.equal((config.match(/steps = \{/g) || []).length, 6);
  assert.match(server, /RegisterNetEvent\('prfrp:advanceCall'/);
  assert.match(server, /stage ~= current\.stage/);
  assert.match(server, /if current\.stage < #c\.steps then/);
  assert.match(server, /GetEntityCoords\(ped\)/);
  assert.match(client, /TriggerServerEvent\('prfrp:advanceCall', call\.id, stage\)/);
  assert.match(client, /TriggerServerEvent\('prfrp:completeCall', call\.id\)/);
});
