import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import {
  interactWeighbridge,
  updateWeighbridge,
  weighbridgeActionLabel,
} from "../weighbridge-sim.js";
const advance = (s, n) => {
  for (let i = 0; i < n * 20; i++) {
    s.time += 0.05;
    updateWeighbridge(s, 0.05);
  }
};
function ready() {
  const s = createSimulation();
  s.mode = "foot";
  s.player.x = s.weighbridge.x + 3.5;
  s.player.z = s.weighbridge.z + 6;
  return s;
}
test("weight stabilizes after six seconds; axle sum and tonne conversion match simulated gross load", () => {
  const s = ready(),
    w = s.weighbridge;
  assert(interactWeighbridge(s));
  assert.equal(w.stage, "weighing");
  assert(!interactWeighbridge(s));
  advance(s, 2);
  assert(w.readingKg > 0 && w.readingKg < w.grossKg);
  advance(s, 5);
  assert.equal(w.stage, "weighed");
  assert.equal(
    w.report.axleKg.reduce((a, b) => a + b, 0),
    w.grossKg,
  );
  assert.equal(w.report.tonnes, 51.6);
  assert.equal(w.report.differenceKg, 3100);
});
test("excess load physically leaves platform, remains in the yard, then a different truck arrives", () => {
  const s = ready(),
    w = s.weighbridge;
  interactWeighbridge(s);
  advance(s, 7);
  assert.match(weighbridgeActionLabel(s), /PÁTIO/);
  interactWeighbridge(s);
  assert.equal(w.history.length, 1);
  assert.equal(w.retained.length, 0);
  advance(s, 35);
  assert.equal(w.retained.length, 1);
  assert(w.retained[0].x < -20);
  assert(Math.abs(w.retained[0].z - w.z) > 20);
  advance(s, 30);
  assert.equal(w.stage, "ready");
  assert.equal(w.sequence, 1);
  assert.equal(w.grossKg, 40800);
  assert.equal(w.truck.freightType, "boxTruck");
});
test("scale rejects movement, remote interaction and paused progress", () => {
  const s = ready(),
    w = s.weighbridge;
  w.truck.speed = 1;
  assert(!interactWeighbridge(s));
  w.truck.speed = 0;
  s.player.z += 30;
  assert(!interactWeighbridge(s));
  s.player.z = w.z + 6;
  assert(interactWeighbridge(s));
  s.paused = true;
  advance(s, 9);
  assert.equal(w.stage, "weighing");
  assert.equal(w.readingKg, 0);
  s.paused = false;
  w.truck.x += 2;
  advance(s, 0.1);
  assert.equal(w.stage, "ready");
  assert.equal(w.report, null);
});
