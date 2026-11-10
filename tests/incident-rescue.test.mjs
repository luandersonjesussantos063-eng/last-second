import test from "node:test";
import assert from "node:assert/strict";
import {
  createSimulation,
  stepSimulation,
  interactMission,
  actionLabel,
} from "../road-sim.js";
import { requestCopom, currentCopom, completeCopom } from "../copom-sim.js";
const advance = (s, n) => {
  for (let i = 0; i < n * 20; i++) stepSimulation(s, 0.05);
};
function arrive(index) {
  const s = createSimulation();
  s.copom.index = index;
  requestCopom(s);
  const t = currentCopom(s);
  s.mode = "foot";
  Object.assign(s.player, { x: t.x + 2, z: t.z + 2 });
  advance(s, 0.1);
  interactMission(s);
  interactMission(s);
  return s;
}
for (const [index, kind, expected] of [
  [2, "collision", ["ambulance"]],
  [3, "truck", ["mechanic"]],
  [4, "fire", ["fire", "ambulance"]],
]) {
  test(`physical ${kind} scene waits for arriving workers and completed aid before towing`, () => {
    const s = arrive(index);
    assert.equal(s.incident.kind, kind);
    assert(s.incident.vehicle.visible);
    assert.deepEqual(
      s.incident.services.map((u) => u.kind),
      expected,
    );
    assert.equal(completeCopom(s), false);
    assert.equal(actionLabel(s), "");
    const before = s.incident.services.map((u) => u.z);
    advance(s, 1);
    s.incident.services.forEach((u, n) =>
      assert(u.z > before[n] && u.z - before[n] < 16),
    );
    advance(s, 55);
    assert(
      s.incident.services.every((u) =>
        ["returning", "complete"].includes(u.stage),
      ),
    );
    if (kind === "collision" || kind === "fire")
      assert.equal(s.incident.victim.state, "transported");
    if (kind === "fire") assert.equal(s.incident.fire, false);
    assert.match(actionLabel(s), /GUINCHO/);
    interactMission(s);
    advance(s, 14);
    assert.equal(s.incident.stage, "towReady");
    interactMission(s);
    advance(s, 19);
    assert.equal(s.incident.stage, "resolved");
    assert.equal(completeCopom(s), true);
    assert.equal(s.copom.completed, 1);
  });
}
test("pause freezes all rescue teams and closure cannot skip assistance", () => {
  const s = arrive(4);
  advance(s, 2);
  const before = JSON.stringify(s.incident.services);
  s.paused = true;
  advance(s, 20);
  assert.equal(JSON.stringify(s.incident.services), before);
  assert.equal(completeCopom(s), false);
});
