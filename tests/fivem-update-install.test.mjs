import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { createHash } from 'node:crypto';

const pwsh = process.env.PWSH_BIN || 'pwsh';
const available = spawnSync(pwsh, ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.ToString()']).status === 0;
test('test-update installer preserves ACE and unrelated resources, and backups stay outside resources', {
  skip: !available && 'Requires PowerShell',
}, () => {
  const root = mkdtempSync(join(tmpdir(), 'prf-update-test-'));
  try {
    const original = 'ensure mapmanager\r\nensure prf_core\r\nadd_ace identifier.fivem:TEST_FIXTURE prfrp.officer allow\r\n';
    writeFileSync(join(root, 'server.cfg'), original);
    const unrelated = join(root, 'resources', '[prf]', 'unrelated');
    mkdirSync(unrelated, { recursive: true });
    writeFileSync(join(unrelated, 'sentinel.txt'), 'preserved');
    const run = () => {
      const result = spawnSync(pwsh, ['-NoLogo', '-NoProfile', '-NonInteractive', '-File',
        resolve('fivem/scripts/install-prf-update.ps1'), '-ServerDataPath', root],
      { encoding: 'utf8', timeout: 60000 });
      assert.equal(result.status, 0, result.stdout + result.stderr);
    };
    run();
    const cfg = readFileSync(join(root, 'server.cfg'), 'utf8');
    assert(cfg.includes('add_ace identifier.fivem:TEST_FIXTURE prfrp.officer allow'));
    assert(!cfg.includes('builtin.everyone'));
    assert(cfg.indexOf('ensure prfMiniLN3d3v') < cfg.indexOf('ensure prf_core'));
    assert(cfg.indexOf('ensure prf_favela_realista') < cfg.indexOf('ensure prf_core'));
    assert(cfg.indexOf('ensure prf_equinox_replace') < cfg.indexOf('ensure prf_core'));
    for (const name of ['prfMiniLN3d3v', 'prf_favela_realista', 'prf_equinox_replace', 'prf_core']) {
      assert(existsSync(join(root, 'resources', '[prf]', name, 'fxmanifest.lua')));
    }
    assert(existsSync(join(root, 'resources', '[prf]', 'prf_core', 'operations_server.lua')));
    for (const name of ['people_client.lua','people_server.lua','commands_client.lua','commands_server.lua','backup_client.lua','backup_server.lua','traffic_client.lua']) {
      assert(existsSync(join(root, 'resources', '[prf]', 'prf_core', name)), name);
    }
    for (const name of ['police.yft','police_hi.yft','police.ytd','police+hi.ytd']) {
      const installed = readFileSync(join(root,'resources','[prf]','prf_equinox_replace','stream',name));
      const bundled = readFileSync(join('fivem','resources','[prf]','prf_equinox_replace','stream',name));
      assert.equal(createHash('sha256').update(installed).digest('hex'), createHash('sha256').update(bundled).digest('hex'));
    }
    assert.equal(readFileSync(join(unrelated, 'sentinel.txt'), 'utf8'), 'preserved');
    assert(readdirSync(join(root, '_prf_backups')).length >= 1);
    assert(!readdirSync(join(root, 'resources', '[prf]')).some(name => name.includes('.bak')));
    run();
    assert.equal(readFileSync(join(root, 'server.cfg'), 'utf8'), cfg);
    assert.equal((cfg.match(/^ensure prf_core\r?$/gm) || []).length, 1);
    assert.equal(readFileSync(join(unrelated, 'sentinel.txt'), 'utf8'), 'preserved');
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('update preserves an existing Trailblazer and enables only one replacement for police', {
  skip: !available && 'Requires PowerShell',
}, () => {
  const root = mkdtempSync(join(tmpdir(),'prf-existing-car-'));
  try {
    writeFileSync(join(root,'server.cfg'),'ensure [prf]\nensure prf_trailblazer\nensure prf_equinox_replace\nensure prf_core\n');
    const trail = join(root,'resources','[prf]','prf_trailblazer');
    mkdirSync(join(trail,'stream'),{recursive:true});
    writeFileSync(join(trail,'fxmanifest.lua'),"fx_version 'cerulean'\ngame 'gta5'\n");
    const fixture = Buffer.concat([Buffer.from('RSC7'),Buffer.alloc(32)]);
    for (const name of ['police.yft','police_hi.yft','police.ytd']) writeFileSync(join(trail,'stream',name),fixture);
    mkdirSync(join(root,'resources','[prf]','prf_equinox_replace'),{recursive:true});
    const run=()=>{
      const result=spawnSync(pwsh,['-NoLogo','-NoProfile','-NonInteractive','-File',
        resolve('fivem/scripts/install-prf-update.ps1'),'-ServerDataPath',root],{encoding:'utf8',timeout:60000});
      assert.equal(result.status,0,result.stdout+result.stderr);
    };
    run();
    const cfg=readFileSync(join(root,'server.cfg'),'utf8');
    assert(cfg.includes('stop prf_equinox_replace'));
    assert(!cfg.includes('ensure prf_equinox_replace'));
    assert.equal((cfg.match(/^ensure prf_trailblazer$/gm)||[]).length,1);
    assert(cfg.indexOf('stop prf_equinox_replace')<cfg.indexOf('ensure prf_trailblazer'));
    for (const name of ['police.yft','police_hi.yft','police.ytd']) assert.deepEqual(readFileSync(join(trail,'stream',name)),fixture);
    run();assert.equal(readFileSync(join(root,'server.cfg'),'utf8'),cfg);
  } finally { rmSync(root,{recursive:true,force:true}); }
});
