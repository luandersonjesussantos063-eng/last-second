import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";

const read = (path) => readFileSync(path, "utf8");

test("FiveM Legacy e a instalacao principal do PRF RP no GitHub", () => {
  const guide = read("fivem/README.md");
  const index = read("README.md");
  assert.match(guide.slice(0, 800), /PADRÃO ATUAL: GTA V LEGACY/);
  assert.match(guide, /C:\\txData\\FiveMBasicServerCFXDefault_F3288B\.base/);
  assert.match(index.slice(0, 500), /FiveM GTA V Legacy — instalação principal/);
  assert.match(guide, /refresh.*ensure prf_core/);
  assert(existsSync("fivem/enhanced/README.md"), "a alternativa Enhanced permanece separada");
});

test("inicializador Legacy utiliza FXServer e nao altera a plataforma Enhanced", () => {
  const cmd = read("fivem/scripts/start-prf-legacy.cmd");
  assert.match(cmd, /set "SERVER_BIN=C:\\FXServer"/);
  assert.match(cmd, /FXServer\.exe/);
  assert.match(cmd, /localhost:40120/);
  assert.doesNotMatch(cmd, /cfx-server\.exe/i);
  assert.doesNotMatch(cmd, /txDataEnhanced/i);
});

test("instalador de um clique usa o perfil existente e nao libera acesso global", () => {
  const cmd = read("fivem/scripts/setup-prf-legacy.cmd");
  const ps = read("fivem/scripts/install-prf.ps1");
  assert.match(cmd, /C:\\txData\\FiveMBasicServerCFXDefault_F3288B\.base/);
  assert.match(cmd, /install-prf\.ps1/);
  assert.match(cmd, /server\.cfg/);
  assert.match(cmd, /-ServerDataPath/);
  assert.doesNotMatch(cmd, /-LocalTestEveryone/);
  assert.match(ps, /Copy\(/);
  assert.match(ps, /bak-/);
  assert.match(ps, /ensure prf_core/);
  assert.doesNotMatch(cmd, /sv_licenseKey|cfxk_/i);
});
