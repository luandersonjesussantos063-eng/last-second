import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';
import { createHash } from 'node:crypto';
// Python's standard ZIP reader avoids loading the archived meshes into test fixtures.
const result=spawnSync('python3',['-c',`import zipfile,json,base64
with zipfile.ZipFile('fivem/diagnostics/PRF-Base-Interior-Teste.zip') as z:
 print(json.dumps({n:base64.b64encode(z.read('prfMiniLN3d3v/stream/'+n)).decode() for n in ['prfmlo.ydr','prfmlo.model.ybn','PRFMLOMINIBASE3D3V.ytyp']}))`],{encoding:'utf8',maxBuffer:2*1024*1024});
assert.equal(result.status,0,result.stderr);
const packed=Object.fromEntries(Object.entries(JSON.parse(result.stdout)).map(([k,v])=>[k,Buffer.from(v,'base64')]));
const raw=name=>inflateRawSync(packed[name].subarray(16));
const ptr=(b,at)=>Number(b.readBigUInt64LE(at))-0x50000000;
test('base interior embeds the supplied solid collision, preserves its visual mesh and declares the correct resource pages',()=>{
 const data=raw('prfmlo.ydr'),source=raw('prfmlo.model.ybn');
 assert.equal(data.length,65536);assert.equal(packed['prfmlo.ydr'].readUInt32LE(8),0xa0000020);
 const pages=ptr(data,8);assert.equal(data[pages+8],1);assert.equal(data[pages+9],0);
 const normalized=Buffer.from(data.subarray(0,28160));normalized.fill(0,0xc8,0xd0);normalized.fill(0,pages+8,pages+10);
 assert.equal(createHash('sha256').update(normalized).digest('hex'),'a2e088a70127b884a0f53436ceb4d5aedcc6fd478a67138637133eddb27eec1e','original visual mesh bytes');
 const composite=ptr(data,0xc8);assert.equal(composite,28160);
 const embedded=Buffer.from(data.subarray(composite,composite+source.length));let relocations=0;
 for(let i=0;i+8<=source.length;i+=8){const p=Number(source.readBigUInt64LE(i));if(p>=0x50000000&&p<0x50000000+source.length){assert.equal(Number(embedded.readBigUInt64LE(i)),p+composite);embedded.writeBigUInt64LE(BigInt(p),i);relocations++;}}
 assert(relocations>=10);assert.deepEqual(embedded,source,'source collision preserved after pointer relocation');
 assert.equal(data[composite+0x10],10);assert.equal(data.readUInt16LE(composite+0xa0),1);
 const child=ptr(data,ptr(data,composite+0x70));assert.equal(data[child+0x10],8);
 const vertices=data.readUInt32LE(child+0xd0),polys=data.readUInt32LE(child+0xd4),faces=ptr(data,child+0x88);
 assert.equal(vertices,40);assert.equal(polys,74);
 for(let i=0;i<polys;i++){const p=faces+i*16;if((data[p]&7)===0)for(const off of [4,6,8])assert((data.readUInt16LE(p+off)&0x7fff)<vertices);}
 for(const off of [0x90,0x98]){const flags=ptr(data,composite+off);assert(data.readUInt32LE(flags)&2);assert(data.readUInt32LE(flags+4)&(1<<21));}
 const materials=ptr(data,child+0xf0);for(let i=0;i<data[child+0x120];i++){const at=materials+i*8;const flags=(data.readUInt32LE(at)>>>24)|((data.readUInt32LE(at+4)&255)<<8);assert.equal(flags&((1<<3)|(1<<7)),0);}
});
test('the base interior archetype registers the embedded physics dictionary',()=>{
 const b=raw('PRFMLOMINIBASE3D3V.ytyp'),table=ptr(b,0x30),n=b.readUInt16LE(0x4c);let found=false;
 for(let i=0;i<n;i++){const at=table+i*16;if(b.readUInt32LE(at)!==2195127427)continue;const start=ptr(b,at+8),size=b.readUInt32LE(at+4);for(let j=0;j<size;j+=144){const record=start+j;if(b.readUInt32LE(record+88)===0x7f7d8f28){assert.equal(b.readUInt32LE(record+104),0x7f7d8f28);found=true;}}}
 assert(found,'prfmlo archetype');
 assert(readFileSync('fivem/resources/[prf]/prf_core/base_stream_client.lua','utf8').includes('v_ilev_shrfdoor'));
});
