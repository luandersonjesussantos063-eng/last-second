import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
const root = "fivem/resources/[prf]/prf_core";
const source = name => readFileSync(root + "/" + name, "utf8");
test("FiveM standalone inclui manifest e todos os scripts para txAdmin", () => {
  for (const file of ["fxmanifest.lua", "server.lua", "client.lua", "config.lua"])
    assert.equal(existsSync(root + "/" + file), true, file);
  const manifest = source("fxmanifest.lua");
  assert.match(manifest, /fx_version 'cerulean'/);
  assert.match(manifest, /game 'gta5'/);
  for (const file of ["server.lua", "client.lua", "config.lua"])
    assert(manifest.includes("'" + file + "'"));
  assert.doesNotMatch(manifest, /dependency\s*['"]qb-core/);
});
test("servidor exige ACE e escala antes de liberar recursos", () => {
  const server = source("server.lua");
  assert.match(server, /IsPlayerAceAllowed\(src, 'prfrp\.officer'\)/);
  assert.match(server, /if not authorized\(src\) then/);
  assert.match(server, /if not onDuty\[src\] then/);
  assert.match(source('copom_server.lua'), /near\(src,GetEntityCoords\(e\)/);
  assert.match(source('copom_server.lua'), /GetEntityCoords\(ped\)/);
  assert.doesNotMatch(server, /add_ace builtin\.everyone/);
  for (const command of ["prfservico", "prfviatura", "prfchamado", "prfcancelar", "prfstatus"])
    assert(server.includes("RegisterCommand('" + command + "'"));
});
test("missões no FiveM têm mapa, interação, NPC e não acessam serviço real", () => {
  const client = source("copom_client.lua");
  assert.match(client, /SetBlipRoute\(blip,true\)/);
  assert.match(client, /TriggerServerEvent\('prfrp:copom:workFinish'/);
  assert.match(client, /CreatePed\(/);
  const config = source("config.lua");
  assert.match(source("copom_config.lua"), /Config\.Copom=/);
  assert.match(config, /Config\.Vehicle = 'police'/);
  assert.doesNotMatch(source("server.lua"), /https?:\/\//);
});
test("instalador local preserva servidor e nao armazena credenciais", () => {
  const script = readFileSync("fivem/scripts/install-prf.ps1", "utf8");
  assert.match(script, /server\.cfg/);
  assert.match(script, /add_ace builtin\.everyone prfrp\.officer allow/);
  assert.match(script, /\.bak-/);
  assert.match(script, /\[System\.IO\.File\]::Copy/);
  assert.doesNotMatch(script, /sv_licenseKey\s+["']cfxk_/);
});
