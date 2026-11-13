import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

const root = 'fivem/resources/[prf]/prf_core/';
const read = file => readFileSync(root + file, 'utf8');

test('farda PRF usa o modelo correto somente com o resource instalado', () => {
  const config = read('config.lua');
  const base = read('base_client.lua');
  const squad = read('squad_client.lua');
  assert.match(config, /Config\.PRFSkinResource = 'prf_skin_replace'/);
  assert.match(config, /Config\.PRFSkinModel = 's_m_y_sheriff_01'/);
  assert.match(base, /GetResourceState\(Config\.PRFSkinResource or 'prf_skin_replace'\) == 'started'/);
  assert.match(base, /local function putOnUniform\(\)/);
  assert.match(base, /if not active or dressed then return end/);
  assert.match(base, /if not hasPrfSkin\(\) then/);
  assert.match(base, /SetPlayerModel\(PlayerId\(\), hash\)/);
  assert.match(base, /putOnUniform\(\)/);
  assert.match(squad, /local preferred = skinReady\(\) and Config\.PRFSkinModel or models\[index\]/);
  assert.match(squad, /CreatePed\(4, hash/);
});

test('carabina apenas no turno autorizado; recolhimento na saída', () => {
  const config = read('config.lua'), keys = read('keys_client.lua'), squad = read('squad_client.lua'), server = read('server.lua');
  assert.match(config, /Config\.DutyWeapon = 'WEAPON_CARBINERIFLE'/);
  assert.match(keys, /local function grantDutyRifle\(\)/);
  assert.match(keys, /if not duty then return end/);
  assert.match(keys, /GiveWeaponToPed\(ped, rifle, 180/);
  assert.match(keys, /RemoveWeaponFromPed\(ped, dutyWeapon\(\)\)/);
  assert.match(keys, /if duty then[^\n]*grantDutyRifle\(\)/);
  assert.match(keys, /clearDutyRifle\(\)/);
  assert.match(keys, /RegisterNetEvent\('prfrp:toggleWeapon'/);
  assert.match(squad, /GiveWeaponToPed\(officer, GetHashKey\(Config\.DutyWeapon or 'WEAPON_CARBINERIFLE'\)/);
  assert.match(squad, /SetCurrentPedWeapon\(officer, GetHashKey\(Config\.DutyWeapon or 'WEAPON_CARBINERIFLE'\)/);
  assert.match(squad, /if enabled then scheduleTeam\(false\)/);
  assert.match(server, /IsPlayerAceAllowed\(src, 'prfrp\.officer'\)/);
  assert.match(server, /if not requireDuty\(src\) or throttle\(src, action, 1\) then return end/);
});

test('instalador valida 3 hashes de skin e registra ensure no servidor existente', () => {
  const script = readFileSync('fivem/scripts/install-prf-skin.ps1', 'utf8');
  const cmd = readFileSync('fivem/scripts/setup-prf-skin.cmd', 'utf8');
  for (const file of ['s_m_y_sheriff_01.ydd','s_m_y_sheriff_01.ymt','s_m_y_sheriff_01.ytd']) {
    assert(script.includes("'" + file + "'"));
  }
  assert.match(script, /Get-FileHash -LiteralPath \$path -Algorithm SHA256/);
  assert.match(script, /if \(\$actual -ne \$expected\[\$name\]\)/);
  assert.match(script, /Backup do server\.cfg/);
  assert.match(script, /ensure prf_skin_replace/);
  assert.match(script, /prf_skin_replace/);
  assert.match(cmd, /install-prf-skin\.ps1/);
  assert(!existsSync('fivem/resources/[prf]/prf_skin_replace/stream/s_m_y_sheriff_01.ydd'),
    'não publicar roupa de terceiros sem licença específica');
});

test('documentação e status são coerentes com instalação opcional', () => {
  const docs = readFileSync('fivem/README.md', 'utf8');
  const status = read('server.lua');
  const assets = readFileSync('fivem/scripts/setup-prf-assets.cmd', 'utf8');
  assert.match(docs, /PRF_Farda_FiveM_Legacy\.zip/);
  assert.match(docs, /setup-prf-skin\.cmd/);
  assert.match(status, /GetResourceState\('prf_skin_replace'\)/);
  assert.match(assets, /install-prf-skin\.ps1/);
});
