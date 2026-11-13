import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
const runner=[['lua5.4',[]],['lua',[]],['luatex',['--luaonly']]].find(([cmd])=>spawnSync(cmd,[cmd==='luatex'?'--version':'-v']).status===0);
test('persistent inventory, real NPC weapons, support services, cone authorization and faction incidents', {skip:!runner&&'Requires Lua'},()=>{
  const result=spawnSync(runner[0],[...runner[1],'tests/fivem-gameplay.lua'],{encoding:'utf8',timeout:15000});
  assert.equal(result.status,0,result.stdout+result.stderr);assert.match(result.stdout,/PRF persistent gameplay behavior passed/);
});
test('cone aiming, squad blitz roles, service effects and tablet lifecycle', {skip:!runner&&'Requires Lua'},()=>{
  const result=spawnSync(runner[0],[...runner[1],'tests/fivem-gameplay-client.lua'],{encoding:'utf8',timeout:15000});
  assert.equal(result.status,0,result.stdout+result.stderr);assert.match(result.stdout,/PRF gameplay client behavior passed/);
});
test('all FiveM Lua files compile', {skip:!runner&&'Requires Lua'},()=>{
  const result=spawnSync(runner[0],[...runner[1],'tests/fivem-syntax.lua'],{encoding:'utf8',timeout:15000});
  assert.equal(result.status,0,result.stdout+result.stderr);
});
