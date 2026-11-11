import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';

const command = process.env.PWSH_BIN || 'pwsh';
const available = spawnSync(command, ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', '$PSVersionTable.PSVersion.ToString()'], {
  encoding: 'utf8',
}).status === 0;

test('instalador de assets preserva bytes, configuracao e ordem dos resources', {
  skip: !available && 'Requer PowerShell (PWSH_BIN ou pwsh).',
}, () => {
  const result = spawnSync(command, ['-NoLogo', '-NoProfile', '-NonInteractive', '-File', 'tests/fivem-assets-install.ps1'], {
    encoding: 'utf8', timeout: 30_000,
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /FiveM assets installer: all checks passed/);
});
