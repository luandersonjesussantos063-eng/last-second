import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, statSync } from 'node:fs';

const root = 'fivem/resources/[prf]/prf_equinox_replace/stream/';
const expected = {
  'police.yft': { bytes: 14706626, sha256: 'd85a7aa4d481a34dbe89d3324081257c413c7c6c290a353f9b37044dfdc52d7e' },
  'police_hi.yft': { bytes: 14028025, sha256: '9c635a7dbf5f04c31fefe01718a29e78da31c101edbebed5c84204231ab3f857' },
  'police.ytd': { bytes: 15314197, sha256: 'e76742124ad52f0300781ed17fd1417273e281ec65a2b6481bdfafdfb70c01a1' },
  'police+hi.ytd': { bytes: 15314197, sha256: 'e76742124ad52f0300781ed17fd1417273e281ec65a2b6481bdfafdfb70c01a1' },
};

test('Equinox PRF de Martinelli está publicada integralmente e sem adulteração', () => {
  for (const [name, info] of Object.entries(expected)) {
    const path = root + name;
    assert.equal(statSync(path).size, info.bytes, 'tamanho de ' + name);
    assert.equal(createHash('sha256').update(readFileSync(path)).digest('hex'),
      info.sha256, 'SHA256 de ' + name);
  }
  const manifest = readFileSync('fivem/resources/[prf]/prf_equinox_replace/fxmanifest.lua', 'utf8');
  assert.match(manifest, /game 'gta5'/);
  assert.match(manifest, /Martinelli \/ Alessandro da Fonseca/);
});
