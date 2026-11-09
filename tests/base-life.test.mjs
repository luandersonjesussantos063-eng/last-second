import test from "node:test";
import assert from "node:assert/strict";
import {
  createSimulation,
  stepSimulation,
  canWalk,
  vehicleBlocked,
  interactMission,
} from "../road-sim.js";
import { floorHeight } from "../base-life.js";
function advance(s, t) {
  for (let i = 0; i < t * 20; i++) stepSimulation(s, 0.05);
}
test("automatic command door opens for the player and closes when the room is empty", () => {
  const s = createSimulation();
  assert(!canWalk(s, 33, 16));
  Object.assign(s.player, { x: 34, z: 16 });
  advance(s, 1);
  assert(s.roomDoor > 0.82);
  assert(canWalk(s, 33, 16));
  Object.assign(s.player, { x: 40, z: 20 });
  advance(s, 2);
  assert(s.roomDoor < 0.1);
  assert(!canWalk(s, 33, 16));
});
test("raised floor is reachable on steps and a continuous ramp; cars cannot enter the platform", () => {
  assert.equal(floorHeight(35, 12), 0.6);
  assert.equal(floorHeight(35, 0), 0);
  let last = 0;
  for (let z = 6; z <= 10; z += 0.1) {
    const height = floorHeight(35, z);
    assert(height - last < 0.21);
    last = height;
  }
  assert(Math.abs(floorHeight(38, 6) - 0.3) < 1e-6);
  assert(vehicleBlocked(35, 9, 0));
  const s = createSimulation();
  Object.assign(s.player, { x: 35, z: 5, yaw: Math.PI });
  advance(s, 1);
  for (let i = 0; i < 120; i++)
    stepSimulation(s, 0.05, { forward: 1, turn: 0 });
  assert(s.player.z > 10);
  assert.equal(floorHeight(s.player.x, s.player.z), 0.6);
});
test("parking arrivals, reception, patrol returns and motorcycle response keep cycling in a live shift", () => {
  const s = createSimulation();
  Object.assign(s.player, { x: 28.3, z: 16 });
  advance(s, 900);
  assert(s.reception.sequence > 12);
  assert(s.reception.agentCompleted > 12);
  assert.equal(s.reception.visitors.length, 6);
  assert(s.life.departures >= 2);
  assert(s.life.evasion.completed >= 2, JSON.stringify({
    evasion: s.life.evasion,
    positions: s.traffic.map(t => ({ id: t.id, x: t.x, z: Math.round(t.z), dir: t.direction, evading: t.evading })),
    motorcycles: s.life.bikes.map(b => ({ stage: b.stage, x: b.x, z: b.z })),
    checkpoint: { phase: s.checkpoint.phase, completed: s.checkpoint.completed },
  }));
  assert.equal(s.life.bikes.length, 2);
  assert.deepEqual(
    new Set(s.traffic.map((t) => t.kind)),
    new Set(["sedan", "hatchback", "van", "motorcycle", "pickup"]),
  );
  assert(s.traffic.every((t) => Number.isFinite(t.x) && Number.isFinite(t.z)));
  const before = JSON.stringify(s.life);
  s.paused = true;
  advance(s, 40);
  assert.equal(JSON.stringify(s.life), before);
});

test("a new player assignment excludes both the checkpoint and motorcycle pursuit", () => {
  const s = createSimulation();
  s.mission.stage = "complete";
  s.checkpoint.vehicleId = 2;
  s.life.evasion.vehicleId = 4;
  s.player.x = 35;
  s.player.z = 20;
  assert.equal(interactMission(s), "new");
  assert.equal(s.mission.targetId, 6);
});
