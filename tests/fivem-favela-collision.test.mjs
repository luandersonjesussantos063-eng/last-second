import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';

const root = 'fivem/resources/[prf]/prf_favela_realista/stream/';
const unpack = name => inflateRawSync(readFileSync(root + name).subarray(16));
const addr = (data, offset) => Number(data.readBigUInt64LE(offset)) - 0x50000000;
function joaat(name) {
  let hash = 0;
  for (const ch of Buffer.from(name.toLowerCase())) {
    hash = (hash + ch) >>> 0;
    hash = (hash + (hash << 10)) >>> 0;
    hash ^= hash >>> 6;
  }
  hash = (hash + (hash << 3)) >>> 0;
  hash ^= hash >>> 11;
  return (hash + (hash << 15)) >>> 0;
}
function blocks(data) {
  const table = addr(data, 0x30);
  return Array.from({ length: data.readUInt16LE(0x4c) }, (_, i) => ({
    type: data.readUInt32LE(table + i * 16),
    pos: addr(data, table + i * 16 + 8),
  }));
}

test('all favela houses register their solid embedded collision with the renamed archetype', () => {
  const typ = unpack('prf_favela_assets.ytyp');
  const archetypes = blocks(typ).find(b => b.type === 2195127427).pos;
  const names = readdirSync(root).filter(n => n.endsWith('.ydr'));
  assert.equal(names.length, 15);
  for (let i = 0; i < names.length; i++) {
    const name = names[i], hash = joaat(name.slice(0, -4));
    let record;
    for (let j = 0; j < names.length; j++) {
      const at = archetypes + j * 144;
      if (typ.readUInt32LE(at + 88) === hash) record = at;
    }
    assert.notEqual(record, undefined, name);
    assert.equal(typ.readUInt32LE(record + 104), hash, name + ': physics dictionary must reference its YDR');
    assert.equal(typ.readUInt32LE(record + 112), hash, name + ': drawable reference');
    const data = unpack(name), composite = addr(data, 0xc8);
    assert.equal(data[composite + 0x10], 10, name);
    const children = addr(data, composite + 0x70);
    const n = data.readUInt16LE(composite + 0xa0);
    assert(n > 0, name);
    for (let j = 0; j < n; j++) {
      for (const offset of [0x90, 0x98]) {
        const flags = addr(data, composite + offset) + j * 8;
        assert(data.readUInt32LE(flags) & 2, name + ': MAP_WEAPON');
        assert(data.readUInt32LE(flags + 4) & (1 << 21), name + ': TEST_WEAPON');
      }
      const geom = addr(data, children + j * 8);
      assert.equal(data[geom + 0x10], 8, name + ': mesh collision');
      const materials = addr(data, geom + 0xf0), count = data[geom + 0x120];
      assert(count > 0, name);
      for (let k = 0; k < count; k++) {
        const at = materials + k * 8;
        const flags = (data.readUInt32LE(at) >>> 24) | ((data.readUInt32LE(at + 4) & 255) << 8);
        assert.equal(flags & ((1 << 3) | (1 << 7)), 0, name + ': material cannot allow shots through');
      }
      const vertices = data.readUInt32LE(geom + 0xd0), polygons = data.readUInt32LE(geom + 0xd4);
      const points = addr(data, geom + 0xb0), faces = addr(data, geom + 0x88);
      assert(vertices > 0 && polygons > 0 && points + vertices * 6 <= data.length, name);
      assert(faces + polygons * 16 <= data.length, name);
      let triangles = 0;
      for (let k = 0; k < polygons; k++) {
        const at = faces + k * 16;
        if ((data[at] & 7) !== 0) continue;
        triangles++;
        for (const offset of [4, 6, 8]) assert((data.readUInt16LE(at + offset) & 0x7fff) < vertices, name);
      }
      assert(triangles > 0, name + ': actual collision faces');
    }
  }
  for (const name of readdirSync(root).filter(n => n.endsWith('.ymap'))) {
    const data = unpack(name), entities = blocks(data).find(b => b.type === 3461354627).pos;
    const rootAt = blocks(data)[0].pos, count = data.readUInt16LE(rootAt + 104);
    for (let i = 0; i < count; i++) {
      assert.equal(data.readUInt32LE(entities + i * 128 + 12) & 4, 0, name + ': embedded collisions enabled');
    }
  }
});
