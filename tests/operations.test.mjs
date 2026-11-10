import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  createSimulation,
  stepSimulation,
  interactMission,
  actionLabel,
} from "../road-sim.js";
import { currentCopom, requestCopom } from "../copom-sim.js";
function advance(s, seconds) {
  for (let i = 0; i < Math.ceil(seconds / 0.05); i++) stepSimulation(s, 0.05);
}
test("três carretas reais integram o fluxo rodoviário", () => {
  const trucks = createSimulation().traffic.filter(
    (vehicle) => vehicle.kind === "truck",
  );
  assert.equal(trucks.length, 3);
  assert(trucks.every((truck) => truck.cruise > 0 && truck.cruise < 17));
});
test("balança registra peso e libera nova carreta sem duplicar histórico", () => {
  const s = createSimulation(),
    w = s.weighbridge;
  s.mode = "foot";
  s.player.x = w.x + 3.5;
  s.player.z = w.z + 6;
  assert.match(actionLabel(s), /PESAR CAMINHÃO/);
  assert.equal(interactMission(s), "weigh");
  assert.equal(w.stage, "weighing");
  assert.equal(
    interactMission(s),
    "",
    "a leitura não pode ser registrada antes de terminar",
  );
  advance(s, 7);
  assert.equal(w.stage, "weighed");
  assert.equal(w.report.grossKg, 51600);
  assert.equal(w.report.differenceKg, 3100);
  assert.equal(interactMission(s), "weigh");
  assert.equal(w.completed, 1);
  assert.equal(w.history.length, 1);
  assert.equal(interactMission(s), "");
  advance(s, 65);
  assert.equal(w.stage, "ready");
  assert.equal(w.grossKg, 40800);
  assert.equal(w.history.length, 1);
});
test("COPOM com objeto exige isolamento, apoio e retirada antes de concluir", () => {
  const s = createSimulation();
  s.copom.index = 1;
  assert(requestCopom(s));
  const site = currentCopom(s);
  s.mode = "foot";
  Object.assign(s.player, { x: site.x + 2.5, z: site.z - 8 });
  stepSimulation(s, 0.05);
  assert.equal(s.copom.stage, "on_scene");
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "secured");
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "surveyed");
  assert.equal(interactMission(s), "");
  advance(s, 32);
  assert.equal(s.incident.support.stage, "deployed");
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "clearing");
  advance(s, 10);
  assert.equal(s.incident.stage, "resolved");
  assert.equal(interactMission(s), "copom");
  assert.equal(s.copom.history.length, 1);
  assert.match(s.copom.history[0].outcome, /Objeto retirado/);
});
test("menu libera operações jogáveis e versão foi sincronizada", () => {
  const html = readFileSync("index.html", "utf8");
  const main = readFileSync("main.js", "utf8");
  const pkg = JSON.parse(readFileSync("package.json", "utf8"));
  assert(html.includes("main.js?v=" + pkg.version));
  for (const id of ["incidentDemoBtn", "weighDemoBtn"]) {
    assert(html.includes('id="' + id + '"'));
    assert(main.includes('"' + id + '"'));
  }
  assert.match(
    main,
    /for\s*\(\s*const id of \[\s*"startBtn",\s*"exploreBtn",\s*"incidentDemoBtn",\s*"weighDemoBtn",?\s*\]\s*\)/,
  );
});
