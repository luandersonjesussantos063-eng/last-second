import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';

const root = 'fivem/resources/[prf]/prf_tablet';
const read = (name) => readFileSync(path.join(root, name), 'utf8');

test('FiveM pilot has required manifest, local NUI and QBCore dependency', () => {
  const manifest = read('fxmanifest.lua');
  assert.match(manifest, /fx_version 'cerulean'/);
  assert.match(manifest, /game 'gta5'/);
  assert.match(manifest, /dependency 'qb-core'/);
  assert.match(manifest, /nui_callback_strict_mode 'true'/);
  for (const name of ['client.lua', 'server.lua', 'html/index.html', 'html/app.js', 'html/style.css']) {
    assert(manifest.includes(name), name);
    assert(read(name).length > 10, name);
  }
});

test('Tablet pilot validates police duty on server and never claims actual government integration', () => {
  const server = read('server.lua');
  assert.match(server, /job\.name == 'prf'/);
  assert.match(server, /job\.onduty == true/);
  assert.match(server, /if not authorized\(src\) then/);
  assert.match(server, /TriggerClientEvent\('prf_tablet:denied'/);
  assert.match(server, /TESTE-101/);
  assert(!/HttpRequest|PerformHttpRequest|password|access_token|cpf\s*=/.test(server));
});

test('NUI only renders caller-supplied text through textContent and always acknowledges close callback', () => {
  const ui = read('html/app.js');
  const client = read('client.lua');
  assert.match(ui, /title\.textContent/);
  assert.match(ui, /status\.textContent/);
  assert(!/innerHTML|eval\s*\(/.test(ui));
  assert.match(client, /RegisterNUICallback\('close'/);
  assert.match(client, /cb\(\{ ok = true \}\)/);
  assert.match(client, /SetNuiFocus\(false, false\)/);
});

test('FiveM pilot is isolated from existing browser main entrypoint', () => {
  const main = readFileSync('main.js', 'utf8');
  assert(!main.includes('prf_tablet'));
});
