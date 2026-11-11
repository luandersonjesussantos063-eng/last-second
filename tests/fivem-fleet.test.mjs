import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

// Lua 5.3+ is sufficient for these standalone scripts. LuaTeX is a convenient
// local runner; CI can use Lua 5.4 without installing any Node dependencies.
const runners = [
  [process.env.LUA_BIN || "lua5.4", [], ["-v"]],
  ["lua", [], ["-v"]],
  ["luatex", ["--luaonly"], ["--version"]],
];
const runner = runners.find(([command, , versionArgs]) => {
  const probe = spawnSync(command, versionArgs, { encoding: "utf8" });
  return probe.status === 0 && (command === "luatex"
    || /Lua 5\.[345]/.test(probe.stdout + probe.stderr));
});

test("frota FiveM valida acesso, recursos e ciclo de criacao com nativos simulados", {
  skip: !runner && "Requer Lua 5.3+ (LUA_BIN, lua5.4, lua ou luatex).",
}, () => {
  const [command, args] = runner;
  const result = spawnSync(command, [...args, "tests/fivem-fleet.lua"], {
    encoding: "utf8",
    timeout: 15_000,
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /FiveM fleet behavior: all checks passed/);
});
