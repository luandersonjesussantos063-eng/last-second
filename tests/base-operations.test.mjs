import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation, stepSimulation, canWalk } from "../road-sim.js";
import { navigationRoute } from "../urban-layout.js";
import { updateMissionRadio } from "../mission-radio.js";
test("scale is inside the operational base annex and its terminal is accessible", () => {
  const s = createSimulation();
  assert(Math.hypot(s.weighbridge.x - 35, s.weighbridge.z - 20) < 90);
  assert(canWalk(s, s.weighbridge.kiosk.x, s.weighbridge.kiosk.z));
  s.mode = "drive";
  Object.assign(s.car, { x: 50, z: -40, heading: Math.PI / 2, speed: 4 });
  for (let i = 0; i < 50; i++)
    stepSimulation(s, 0.05, { throttle: 1, steer: 0 });
  assert(s.car.x > 60);
  const route = navigationRoute({ x: 20, z: 0 }, s.weighbridge.kiosk);
  assert(route.length > 1);
});
test("dispatch guidance follows physical mission phases once and keeps a bounded history", () => {
  const s = createSimulation();
  s.incident.stage = "arrival";
  updateMissionRadio(s);
  assert.match(s.radioFeed.messages[0].text, /isolamento/);
  const serial = s.radioFeed.serial;
  updateMissionRadio(s);
  assert.equal(s.radioFeed.serial, serial);
  s.incident.stage = "towReady";
  updateMissionRadio(s);
  assert.match(s.radioFeed.messages[0].text, /Guincho posicionado/);
  for (let i = 0; i < 30; i++) {
    s.weighbridge.stage = i % 2 ? "weighed" : "weighing";
    updateMissionRadio(s);
  }
  assert(s.radioFeed.messages.length <= 8);
});
