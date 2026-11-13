import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
const read = path => readFileSync(path, 'utf8');
const root = 'fivem/resources/[prf]/prf_core/';

test('viatura PRF e a primeira da frota e mantem as opcoes nativas', () => {
  const cfg = read(root + 'config.lua');
  assert.match(cfg, /Config\.Vehicle = 'police'/);
  assert.match(cfg, /Config\.Fleet = \{\s*\{ model = 'police'/);
  for (const name of ['police2','police3','policeb','sheriff2']) {
    assert(cfg.includes("model = '" + name + "'"));
  }
  const server = read(root + 'server.lua');
  assert.match(server, /RegisterCommand\('prfassets'/);
  assert.match(server, /GetResourceState\('prfMiniLN3d3v'\)/);
  assert.match(server, /GetResourceState\('prf_equinox_replace'\)/);
  assert.match(server, /if not authorized\(src\) then/);
});

test('instalação do mapa registra YTYP e preserva /assetpacks', () => {
  const install = read('fivem/scripts/install-prf-assets.ps1');
  assert.match(install, /prfMiniLN3d3v/);
  assert.match(install, /ZipFile\]::ExtractToDirectory/);
  assert.match(install, /-Filter '\*\.ytyp'/);
  assert.match(install, /DLC_ITYP_REQUEST/);
  assert.match(install, /Mantem dependencia \/assetpacks/);
  assert.match(install, /server\.cfg/);
  assert.match(install, /bak-/);
});

test('Equinox prioriza modelos autorizados no GitHub e aceita RAR original como alternativa', () => {
  const install = read('fivem/scripts/install-prf-assets.ps1');
  for (const name of ['police.yft','police_hi.yft','police.ytd','police+hi.ytd']) {
    assert(install.includes("'" + name + "'"));
  }
  assert.match(install, /prf_equinox_replace/);
  assert.match(install, /tar\.exe/);
  assert.match(install, /7z\.exe/);
  const cmd = read('fivem/scripts/setup-prf-assets.cmd');
  assert.match(cmd, /install-prf-assets\.ps1/);
  assert.match(cmd, /-ExecutionPolicy Bypass/);
  const guide = read('fivem/assets/README.md');
  assert.match(guide, /autorização específica/);
  const manifest = read('fivem/resources/[prf]/prf_equinox_replace/fxmanifest.lua');
  assert.match(manifest, /Martinelli \/ Alessandro da Fonseca/);
  const workflow = read('.github/workflows/import-equinox-prf.yml');
  assert.match(workflow, /638b8370e768941e714d277bb35acaf3f5c4f3a1e52f8772d4f5755c124e7cb4/);
  assert.match(workflow, /sha256sum -c -/);
  assert.match(install, /\$hasBundled/);
  assert.match(guide, /Sandy Shores/);
  assert(existsSync('fivem/scripts/setup-prf-legacy.cmd'));
});
