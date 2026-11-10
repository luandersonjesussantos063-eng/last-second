import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  createSimulation,
  stepSimulation,
  interactMission,
  actionLabel,
} from "../road-sim.js";
import { requestCopom, currentCopom, completeCopom } from "../copom-sim.js";
import { incidentSummary, incidentTrafficMultiplier } from "../incident-sim.js";
import { weighbridgeSummary } from "../weighbridge-sim.js";
const advance = (s, t) => {
  for (let n = 0; n < Math.ceil(t * 20); n++) stepSimulation(s, 0.05);
};
function arrive(s) {
  assert(requestCopom(s));
  const site = currentCopom(s);
  s.mode = "drive";
  Object.assign(s.car, { x: site.x, z: site.z + 3, speed: 0 });
  advance(s, 0.1);
  assert.equal(s.copom.stage, "on_scene");
  s.mode = "foot";
  Object.assign(s.player, { x: site.x, z: site.z + 1 });
  assert.equal(s.incident.stage, "arrival");
  return site;
}
test("COPOM: a cena exige isolamento, informação, apoio, guincho e só então encerramento", () => {
  const s = createSimulation(),
    site = arrive(s);
  assert(s.incident.vehicle.visible);
  assert.match(actionLabel(s), /ISOLAR/);
  assert.equal(
    completeCopom(s),
    false,
    "a ocorrência não fecha com uma interação",
  );
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "secured");
  assert.equal(s.incident.support.stage, "enroute");
  assert.match(actionLabel(s), /CONDUTOR/);
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "surveyed");
  assert.equal(completeCopom(s), false);
  assert.equal(actionLabel(s), "", "aguardar apoio antes de chamar o guincho");
  const zBefore = s.incident.support.z;
  advance(s, 30);
  assert(s.incident.support.z > zBefore + 50);
  assert.equal(s.incident.support.stage, "deployed");
  assert(s.incident.agents.every((a) => a.visible && !a.moving));
  assert.match(actionLabel(s), /GUINCHO/);
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "towCalled");
  advance(s, 14);
  assert.equal(s.incident.stage, "towReady");
  assert(s.incident.tow.visible);
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "recovering");
  advance(s, 19);
  assert.equal(s.incident.stage, "resolved");
  assert(!s.incident.vehicle.visible);
  assert.equal(s.incident.tow.visible, false);
  assert.match(actionLabel(s), /RELATÓRIO/);
  assert.equal(interactMission(s), "copom");
  assert.equal(s.copom.completed, 1);
  assert.equal(s.copom.stage, "complete");
  assert.match(s.copom.history[0].outcome, /guincho/);
  advance(s, 0.05);
  assert.equal(s.incident.active, false);
  assert.equal(s.incident.stage, "closed");
});
test("COPOM: equipes se deslocam continuamente e mantêm objetos até o recolhimento", () => {
  const s = createSimulation();
  arrive(s);
  interactMission(s);
  let previous = s.incident.support.z,
    largeStep = 0;
  for (let j = 0; j < 200; j++) {
    stepSimulation(s, 0.05);
    largeStep = Math.max(largeStep, Math.abs(previous - s.incident.support.z));
    previous = s.incident.support.z;
  }
  assert(largeStep < 0.7, "viatura de apoio não deve teleportar");
  assert.equal(s.incident.vehicle.visible, true);
  assert.equal(s.incident.cleared, false);
  assert(incidentSummary(s).support !== "idle");
});
test("COPOM: objeto da pista requer apoio e remoção física diferente do guincho", () => {
  const s = createSimulation();
  s.copom.stage = "complete";
  s.copom.availableAt = 0;
  s.copom.index = 0;
  s.time = 15;
  assert(requestCopom(s));
  assert.equal(s.incident.kind, "debris");
  const site = currentCopom(s);
  Object.assign(s.car, { x: site.x, z: site.z + 2, speed: 0 });
  s.mode = "drive";
  advance(s, 0.1);
  s.mode = "foot";
  Object.assign(s.player, { x: site.x, z: site.z });
  assert.equal(interactMission(s), "incident");
  assert.equal(interactMission(s), "incident");
  advance(s, 31);
  assert.equal(s.incident.support.stage, "deployed");
  assert.match(actionLabel(s), /OBSTÁCULO/);
  assert.equal(interactMission(s), "incident");
  assert.equal(s.incident.stage, "clearing");
  advance(s, 9);
  assert.equal(s.incident.stage, "resolved");
  assert.equal(s.incident.debris.visible, false);
  assert.equal(interactMission(s), "copom");
  assert.match(s.copom.history[0].outcome, /Objeto retirado/);
});
test("trânsito observa ocorrência antes de chegar e reduz gradualmente a velocidade", () => {
  const s = createSimulation(),
    site = arrive(s);
  let t = s.traffic.find((x) => x.direction > 0);
  t.z = site.z - 48;
  t.x = -3.4;
  assert.equal(incidentTrafficMultiplier(s, t), 1);
  assert.equal(interactMission(s), "incident");
  assert(incidentTrafficMultiplier(s, t) < 1);
  assert(incidentTrafficMultiplier(s, { ...t, z: site.z - 500 }) === 1);
  assert.equal(s.traffic.filter((c) => c.kind === "truck").length, 3);
  assert(
    s.traffic.filter((c) => c.kind === "truck").every((c) => c.cruise < 15),
  );
});
test("balança: 51,6 toneladas registradas e novo caminhão depois da saída", () => {
  const s = createSimulation(),
    w = s.weighbridge;
  s.mode = "foot";
  s.player.x = w.x + 3.2;
  s.player.z = w.z + 7;
  assert.match(actionLabel(s), /PESAR/);
  assert.equal(interactMission(s), "weigh");
  assert.equal(w.stage, "weighing");
  assert.equal(interactMission(s), "", "não registra antes de estabilizar");
  advance(s, 7);
  assert.equal(w.stage, "weighed");
  assert.equal(w.report.grossKg, 51600);
  assert.equal(w.report.differenceKg, 3100);
  assert.equal(weighbridgeSummary(s).report.plate, "SIM-CARGA-2000");
  assert.match(actionLabel(s), /REGISTRAR/);
  assert.equal(interactMission(s), "weigh");
  assert.equal(w.completed, 1);
  assert.equal(w.stage, "released");
  assert.equal(interactMission(s), "");
  advance(s, 100);
  assert.equal(w.stage, "ready");
  assert.equal(w.grossKg, 40800);
  assert(Math.abs(w.truck.z - w.z) < 0.15);
  assert.equal(w.history[0].differenceKg, 3100);
});
test("cenas e HUD incluem veículos, policiais 3D, guincho, cones e painel de massa", () => {
  const world = readFileSync("incident-world.js", "utf8");
  const weigh = readFileSync("weighbridge-world.js", "utf8");
  const road = readFileSync("road-world.js", "utf8");
  const html = readFileSync("index.html", "utf8");
  for (const id of ["incidentHud", "weighHud"])
    assert(html.includes('id="' + id + '"'));
  assert(world.includes("createActor"));
  assert(world.includes("makeCone"));
  assert(world.includes("PRF-COPOM"));
  assert(world.includes("SIM-GUINCHO"));
  assert(weigh.includes("BALANÇA RODOVIÁRIA"));
  assert(weigh.includes("createFreightTruck"));
  assert(/incidentWorld\.update\(\s*s,\s*dt\s*\)/.test(road));
  assert(/weighbridgeWorld\.update\(\s*s,\s*dt\s*\)/.test(road));
});
