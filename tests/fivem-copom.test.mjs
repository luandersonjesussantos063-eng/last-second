import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
const runner=[['lua5.4',[]],['lua',[]],['luatex',['--luaonly']]].find(([c])=>spawnSync(c,[c==='luatex'?'--version':'-v']).status===0);
test('COPOM scenes, twenty variants, saved rotation, real objectives, medical/tow integration and replay protection',{skip:!runner&&'Requires Lua'},()=>{
 const r=spawnSync(runner[0],[...runner[1],'tests/fivem-copom.lua'],{encoding:'utf8',timeout:15000});
 assert.equal(r.status,0,r.stdout+r.stderr);assert.match(r.stdout,/PRF COPOM scene behavior passed/);
});

test('COPOM client spawns twenty scene variants, rejects missing ground, times work and preserves custody',{skip:!runner&&'Requires Lua'},()=>{
 const r=spawnSync(runner[0],[...runner[1],'tests/fivem-copom-client.lua'],{encoding:'utf8',timeout:15000});
 assert.equal(r.status,0,r.stdout+r.stderr);assert.match(r.stdout,/PRF COPOM client behavior passed/);
});
