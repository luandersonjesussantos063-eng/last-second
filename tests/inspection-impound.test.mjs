import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import {
  beginImpound,
  updateImpound,
  impoundVehicles,
} from "../inspection-impound.js";
const advance = (s, n) => {
  for (let i = 0; i < n * 20; i++) {
    s.time += 0.05;
    updateImpound(s, 0.05);
  }
};
function base() {
  const s = createSimulation();
  s.operations ??= {};
  const t = s.traffic[0];
  Object.assign(t, { x: -9, z: -100, speed: 0, stopped: true });
  s.traffic = [t];
  return { s, t };
}
test("inspection retention physically loads and transports the original car to the yard", () => {
  const { s, t } = base(),
    j = beginImpound(s, t);
  assert(t.impounded);
  assert(!t.impoundCarried);
  advance(s, 1);
  assert.equal(t.z, -100);
  advance(s, 15);
  assert(t.impoundCarried);
  assert(j.load);
  advance(s, 130);
  assert.equal(j.stage, "stored");
  assert(t.impoundStored);
  assert.equal(t.x, -28);
  assert.equal(t.z, -520);
  assert.equal(impoundVehicles(s).length, 0);
});
test("pause and an obstructing commander stop the tow without teleporting", () => {
  const { s, t } = base(),
    j = beginImpound(s, t),
    before = JSON.stringify(j);
  s.paused = true;
  advance(s, 10);
  assert.equal(JSON.stringify(j), before);
  s.paused = false;
  Object.assign(s.player, { x: j.x, z: j.z + 1 });
  advance(s, 0.2);
  assert(j.blocked);
  Object.assign(s.player, { x: 27, z: 0 });
  advance(s, 1);
  assert(!j.blocked);
});
test("a fourth impound recycles a stored old car and keeps a bounded three-job pool", () => {
  const { s, t } = base();
  s.traffic = Array.from({ length: 4 }, (_, id) => ({
    ...t,
    id,
    x: 3.4,
    z: -1000 - id * 10,
  }));
  for (let n = 0; n < 3; n++) {
    Object.assign(s.traffic[n], { x: -9, z: -100 - n * 10 });
    beginImpound(s, s.traffic[n]);
    advance(s, 150);
    assert(s.traffic[n].impoundStored);
  }
  beginImpound(s, s.traffic[3]);
  assert.equal(s.operations.impound.jobs.length, 3);
  assert.equal(s.traffic[0].impounded, false);
  assert(Math.abs(s.traffic[0].z) > 1000);
  assert.equal(s.traffic.length, 4);
});
