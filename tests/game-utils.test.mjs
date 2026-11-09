import test from "node:test";
import assert from "node:assert/strict";
import { frameStep, AdaptiveResolution } from "../game-utils.js";
test("long or invalid frame gaps never move the simulation by more than 50 ms", () => {
  assert.equal(frameStep(16), 0.016);
  assert.equal(frameStep(5000), 0.05);
  assert.equal(frameStep(-20), 0);
  assert.equal(frameStep(NaN), 0);
});
test("adaptive resolution falls under sustained pressure, has a floor and ignores background gaps", () => {
  const q = new AdaptiveResolution(1.25);
  for (let i = 0; i < 600; i++) q.sample(0.04);
  assert.equal(q.level, 3);
  assert(q.ratio >= 0.55 * 1.25);
  const old = q.level;
  q.sample(10);
  assert.equal(q.level, old);
  for (let i = 0; i < 900; i++) q.sample(0.012);
  assert(q.level < 3);
  assert(q.ratio <= 1.25);
});

test("very slow visible frames still trigger lower resolution", () => {
  const q = new AdaptiveResolution(1.25);
  for (let i = 0; i < 30; i++) q.sample(0.4);
  assert(q.level > 0);
});
