import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';
import { createHash } from 'node:crypto';

const candidates = [[process.env.LUA_BIN || 'lua5.4', []], ['lua', []], ['luatex', ['--luaonly']]];
const runner = candidates.find(([cmd]) => spawnSync(cmd, [cmd === 'luatex' ? '--version' : '-v']).status === 0);
for (const [file, resultText] of [
  ['fivem-fleet.lua', 'PRF fleet behavior passed'],
  ['fivem-people.lua', 'PRF pedestrian server behavior passed'],
  ['fivem-people-client.lua', 'PRF pedestrian client and chat behavior passed'],
  ['fivem-backup.lua', 'PRF multiple backup behavior passed'],
  ['fivem-aim.lua', 'PRF Z aim behavior passed'],
  ['fivem-traffic.lua', 'PRF traffic stop and pursuit behavior passed'],
]) {
  test(file + ' behavior', { skip: !runner && 'Requires Lua runtime' }, () => {
    const result = spawnSync(runner[0], [...runner[1], 'tests/' + file], { encoding: 'utf8', timeout: 15000 });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert(result.stdout.includes(resultText));
  });
}
test('FiveM operations validate duty, proximity, tow passengers and mission progression', {
  skip: !runner && 'Requires Lua runtime',
}, () => {
  const result = spawnSync(runner[0], [...runner[1], 'tests/fivem-ops.lua'], { encoding: 'utf8', timeout: 15000 });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /PRF operations behavior passed/);
});

test('base spawn and gang population handle streaming, respawn and cleanup', {
  skip: !runner && 'Requires Lua runtime',
}, () => {
  const result = spawnSync(runner[0], [...runner[1], 'tests/fivem-life.lua'], { encoding: 'utf8', timeout: 15000 });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /PRF spawn and population behavior passed/);
});

test('favela addon models retain original bytes and map pointers stay within their blocks', () => {
  const root = 'fivem/resources/[prf]/prf_favela_realista/';
  const metadata = JSON.parse(readFileSync(root + 'origem.json'));
  assert.equal(metadata.active_gang_limit, 12);
  assert.equal(metadata.props, 495);
  assert.equal(metadata.custom_addon_models, 15);
  for (const item of metadata.files) {
    const data = readFileSync(root + 'stream/' + item.file);
    assert.equal(createHash('sha256').update(data).digest('hex'), item.sha256, item.file);
    assert(item.file.startsWith('prffavela_'));
    assert.equal(data.subarray(0, 4).toString(), 'RSC7');
  }
  let total = 0;
  for (const name of readdirSync(root + 'stream').filter(n => n.endsWith('.ymap') || n.endsWith('.ytyp'))) {
    const data = readFileSync(root + 'stream/' + name);
    const raw = inflateRawSync(data.subarray(16));
    const address = x => Number(x) - 0x50000000;
    const table = address(raw.readBigUInt64LE(0x30));
    const count = raw.readUInt16LE(0x4c);
    const blocks = [];
    for (let i = 0; i < count; i++) {
      const at = table + i * 16, size = raw.readUInt32LE(at + 4), pos = address(raw.readBigUInt64LE(at + 8));
      assert(pos >= 0 && pos + size <= raw.length, name);
      blocks.push({ size, pos, type: raw.readUInt32LE(at) });
    }
    const rootAt = blocks[0].pos;
    const field = name.endsWith('.ymap') ? 96 : 24;
    const pointer = Number(raw.readBigUInt64LE(rootAt + field));
    const n = raw.readUInt16LE(rootAt + field + 8);
    const listBlock = blocks[(pointer & 0xfff) - 1];
    const offset = (pointer >>> 12) & 0xfffff;
    assert(offset + n * 8 <= listBlock.size);
    for (let i = 0; i < n; i++) {
      const ref = Number(raw.readBigUInt64LE(listBlock.pos + offset + i * 8));
      const target = blocks[(ref & 0xfff) - 1], itemOffset = (ref >>> 12) & 0xfffff;
      assert(itemOffset + (name.endsWith('.ymap') ? 128 : 144) <= target.size);
      if (name.endsWith('.ytyp')) assert(raw.readFloatLE(target.pos + itemOffset + 80) > 0);
    }
    if (name.endsWith('.ymap')) total += n;
    else assert.equal(n, 15);
  }
  assert.equal(total, 495);
});
