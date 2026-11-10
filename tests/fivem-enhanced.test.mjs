import test from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

const read = (path) => readFileSync(path, "utf8");
test("instalacao Enhanced usa cfx-server.exe, txData e txAdmin isolados do Legacy", () => {
  const start = read("fivem/scripts/start-prf-enhanced.cmd");
  assert.match(start, /C:\\CfxServerEnhanced/);
  assert.match(start, /cfx-server\.exe/i);
  assert.match(start, /C:\\txDataEnhanced/);
  assert.match(start, /txDataPath/);
  assert.match(start, /txAdminPort 40121/);
  assert.doesNotMatch(start, /\bFXServer\.exe\b/i);
});
test("instalador Enhanced utiliza recursos existentes e so toca server.cfg quando preciso", () => {
  const installer = read("fivem/scripts/install-prf-enhanced.ps1");
  for (const file of ["client.lua", "config.lua", "server.lua", "fxmanifest.lua"]) {
    assert(installer.includes(file));
    assert(existsSync("fivem/resources/[prf]/prf_core/" + file));
  }
  assert.match(installer, /server\.cfg/);
  assert.match(installer, /ensure prf_core/);
  assert.match(installer, /bak-/);
  assert.doesNotMatch(installer, /sv_licenseKey|builtin\.everyone prfrp\.officer allow/);
});
test("guia Enhanced orienta cliente proprio e nao importa dados do Legacy", () => {
  const guide = read("fivem/enhanced/README.md");
  assert.match(guide, /FiveM for GTAV Enhanced/);
  assert.match(guide, /cfx-server_win_x64/);
  assert.match(guide, /C:\\FXServer/);
  assert.match(guide, /C:\\CfxServerEnhanced/);
  assert.match(guide, /C:\\txDataEnhanced/);
  assert.match(guide, /Alchemist/);
  assert.match(guide, /ainda sem validação prática/);
});
