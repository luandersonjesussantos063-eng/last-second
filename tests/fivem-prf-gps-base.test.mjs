import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = 'fivem/resources/[prf]/prf_core/';
const config = readFileSync(root + 'config.lua', 'utf8');
const client = readFileSync(root + 'client.lua', 'utf8');
const guide = readFileSync('fivem/README.md', 'utf8');

test('coordenadas vêm da base Chumash e não alteram o posto antigo', () => {
  assert.match(config, /Config\.CustomBase = \{ x = -3026\.0, y = 367\.0, z = 14\.0 \}/);
  assert.match(config, /Config\.CustomBaseResource = 'prfMiniLN3d3v'/);
  assert.match(config, /Config\.Base = \{ x = 1853\.5, y = 3687\.6, z = 34\.27/);
  assert.match(guide, /Chumash/);
  assert.match(guide, /Sandy Shores/);
});
test('GPS F10 ou /prfbase só marca base quando mapa está iniciado', () => {
  assert.match(client, /GetResourceState\(Config\.CustomBaseResource\) == 'started'/);
  assert.match(client, /RegisterCommand\('prfbase'/);
  assert.match(client, /RegisterKeyMapping\('prfbase'.*'F10'\)/);
  assert.match(client, /SetNewWaypoint\(base\.x, base\.y\)/);
  assert.match(client, /AddBlipForCoord\(base\.x, base\.y, base\.z\)/);
  assert.match(client, /RemoveBlip\(customBaseBlip\)/);
  assert.match(client, /if not refreshCustomBaseBlip\(\) then/);
});
