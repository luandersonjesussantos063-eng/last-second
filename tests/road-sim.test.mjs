import test from "node:test";
import assert from "node:assert/strict";
import {
  createSimulation,
  stepSimulation,
  walkInput,
  driveInput,
  interactVehicle,
  interactMission,
  finishInspection,
  canRequestStop,
  radarReading,
  canWalk,
  targetVehicle,
} from "../road-sim.js";
const advance = (
  s,
  seconds,
  input = { forward: 0, turn: 0, throttle: 0, steer: 0, handbrake: false },
) => {
  for (let i = 0; i < Math.ceil(seconds * 60); i++)
    stepSimulation(s, 1 / 60, input);
};
test("walking A/D rotates the agent and camera heading; W moves in that direction", () => {
  const s = createSimulation(),
    yaw = s.player.yaw,
    x = s.player.x;
  advance(s, 1, walkInput(new Set(["KeyA", "KeyW"])));
  assert(s.player.yaw > yaw + 1);
  assert.notEqual(s.player.x, x);
});
test("the patrol vehicle accelerates, brakes before reversing, steers and limits speed", () => {
  const s = createSimulation();
  s.mode = "drive";
  s.car.x = 3.4;
  s.car.z = -250;
  s.traffic = [];
  advance(s, 2, driveInput(new Set(["KeyW"])));
  assert(s.car.speed > 7);
  assert(s.car.z > -242);
  advance(s, 2, driveInput(new Set(["KeyS"])));
  assert(s.car.speed < 0);
  const h = s.car.heading;
  advance(s, 1, driveInput(new Set(["KeyS", "KeyA"])));
  assert.notEqual(s.car.heading, h);
  s.car.x = 3.4;
  s.car.z = -500;
  s.car.heading = 0;
  s.car.speed = 0;
  advance(s, 15, driveInput(new Set(["KeyW"])));
  assert(s.car.speed <= 36);
});
test("swept vehicle steps cannot pass through station walls at speed", () => {
  const s = createSimulation();
  s.mode = "drive";
  s.traffic = [];
  s.car.x = 26;
  s.car.z = 6;
  s.car.speed = 36;
  stepSimulation(s, 0.05, driveInput(new Set(["KeyW"])));
  assert(s.car.z < 8);
  assert(s.car.condition < 100);
});
test("embarkation requires proximity and disembarkation requires a stopped vehicle", () => {
  const s = createSimulation();
  assert(!interactVehicle(s));
  s.player.x = 21.9;
  s.player.z = -8;
  assert(interactVehicle(s));
  assert.equal(s.mode, "drive");
  s.car.speed = 12;
  assert(!interactVehicle(s));
  s.car.speed = 0;
  assert(interactVehicle(s));
  assert.equal(s.mode, "foot");
  assert(canWalk(s, s.player.x, s.player.z));
});
test("inspection requires a valid stop request and a nearby officer, then can only complete once", () => {
  const s = createSimulation(),
    t = targetVehicle(s);
  s.mode = "drive";
  s.mission.stage = "patrol";
  s.car.x = 3.4;
  s.car.z = 30;
  assert(!canRequestStop(s));
  s.car.lights = true;
  assert(canRequestStop(s));
  assert.equal(interactMission(s), "stop");
  advance(s, 6);
  assert.equal(s.mission.stage, "stopped");
  assert.equal(t.x, 9);
  assert(s.driver.visible);
  s.mode = "foot";
  s.player.x = 30;
  s.player.z = 0;
  assert.equal(interactMission(s), "");
  s.player.x = s.driver.x + 1;
  s.player.z = s.driver.z;
  assert.equal(interactMission(s), "inspect");
  assert.equal(s.mission.report.plate, t.plate);
  assert(finishInspection(s));
  assert(!finishInspection(s));
  advance(s, 4);
  assert.equal(s.completed, 1);
  assert.equal(s.mission.stage, "complete");
  assert(!s.driver.visible);
});
test("pause and document inspection freeze traffic, movement and the mission clock", () => {
  const s = createSimulation();
  s.paused = true;
  const snapshot = JSON.stringify(s);
  advance(s, 5);
  assert.equal(JSON.stringify(s), snapshot);
  s.paused = false;
  s.inspection = true;
  const inspection = JSON.stringify(s);
  advance(s, 5);
  assert.equal(JSON.stringify(s), inspection);
});
test("radar measures only vehicles in its forward cone", () => {
  const s = createSimulation();
  s.radar = true;
  s.player.x = 3.4;
  s.player.z = 0;
  s.player.yaw = Math.PI;
  s.traffic = [s.traffic[0]];
  s.traffic[0].speed = 20;
  const r = radarReading(s);
  assert(r);
  assert.equal(r.vehicle.speed, 20);
  s.player.yaw = 0;
  assert.equal(radarReading(s), null);
});
test("traffic brakes for a pedestrian instead of crossing the waiting agent", () => {
  const s = createSimulation();
  s.traffic = [s.traffic[0]];
  s.traffic[0].z = 0;
  s.traffic[0].speed = 15;
  s.player.x = 3.4;
  s.player.z = 30;
  advance(s, 6);
  assert(s.traffic[0].z < 28);
  assert(s.traffic[0].speed < 3);
});
