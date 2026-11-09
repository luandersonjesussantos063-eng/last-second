import test from "node:test";
import assert from "node:assert/strict";
import {
  createSimulation,
  stepSimulation,
  interactMission,
  canWalk,
  vehicleBlocked,
} from "../road-sim.js";
import { BASE_COLUMNS, CANOPY, BLITZ_UNITS } from "../base-layout.js";
function advance(s, t) {
  for (let i = 0; i < Math.ceil(t * 60); i++) stepSimulation(s, 1 / 60);
}
test("checkpoint selects a civilian, checks documents and releases it without taking the player's target", () => {
  const s = createSimulation(),
    seen = new Set();
  for (let i = 0; i < 60 * 150; i++) {
    stepSimulation(s, 1 / 60);
    seen.add(s.checkpoint.stage);
    assert.notEqual(s.checkpoint.vehicleId, s.mission.targetId);
    if (s.checkpoint.stage === "checking") {
      const car = s.traffic.find((c) => c.id === s.checkpoint.vehicleId);
      assert.equal(car.x, -9);
      assert.equal(car.z, 18);
      assert(s.checkpoint.driverVisible);
      assert.equal(car.speed, 0);
    }
  }
  for (const stage of [
    "approach",
    "signal",
    "directing",
    "checking",
    "release",
    "merging",
  ])
    assert(seen.has(stage), stage);
  assert(s.checkpoint.completed >= 1);
});
test("checkpoint waits when a pedestrian obstructs a controlled manoeuvre", () => {
  const s = createSimulation();
  for (let i = 0; i < 6000 && s.checkpoint.stage !== "directing"; i++)
    stepSimulation(s, 1 / 60);
  assert.equal(s.checkpoint.stage, "directing");
  const t = s.traffic.find((c) => c.id === s.checkpoint.vehicleId);
  s.player.x = t.x + 2.7;
  s.player.z = t.z;
  const before = { x: t.x, z: t.z, time: s.checkpoint.elapsed };
  advance(s, 1);
  assert(s.checkpoint.blocked);
  assert.equal(t.x, before.x);
  assert.equal(t.z, before.z);
  assert(Math.abs(s.checkpoint.elapsed - before.time) < 0.001);
  s.player.x = 30;
  s.player.z = -20;
  advance(s, 30);
  assert(s.checkpoint.completed > 0);
});
test("new player assignments skip the civilian currently being checked by the team", () => {
  const s = createSimulation();
  s.checkpoint.vehicleId = 2;
  s.checkpoint.stage = "checking";
  s.mission.stage = "complete";
  s.player.x = 35;
  s.player.z = 20;
  assert.equal(interactMission(s), "new");
  assert.equal(s.mission.targetId, 4);
  assert.equal(s.checkpoint.vehicleId, 2);
});
test("the road remains clear below the canopy while support vehicles and pillars are solid", () => {
  const s = createSimulation();
  assert(CANOPY.minX < -7 && CANOPY.maxX > 7 && CANOPY.roofY > 7);
  for (const column of BASE_COLUMNS) {
    assert(Math.abs(column.x) > 12);
    assert(vehicleBlocked(column.x, column.z, 0));
  }
  assert.equal(s.support.length, 3);
  for (const car of BLITZ_UNITS) assert(!canWalk(s, car.x, car.z));
});
test("traffic slows at the marked inspection approach", () => {
  const s = createSimulation();
  s.traffic = [s.traffic[0]];
  s.traffic[0].z = -65;
  s.traffic[0].speed = 18;
  advance(s, 2);
  assert(s.traffic[0].speed <= 8.01);
});
