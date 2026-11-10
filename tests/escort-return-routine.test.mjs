import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation, stepSimulation, interactVehicle} from "../road-sim.js";

const TEAM = [18, 19, 20];
function advance(s, seconds) {
  for (let tick = 0; tick < seconds * 20; tick++) stepSimulation(s, 0.05);
}
function officers(s) {
  return TEAM.map(id => s.command.agents.find(a => a.id === id));
}

test("escort returns to independently moving indoor duty after disembarking", () => {
  const s = createSimulation();
  Object.assign(s.player, {x: 21.9, z: -8});
  assert.equal(interactVehicle(s), true);
  advance(s, 34);
  assert.equal(s.escort.stage, "aboard");
  assert.equal(interactVehicle(s), true);
  advance(s, 42);
  assert.equal(s.escort.stage, "idle");
  assert(officers(s).every(a => a.task === "routine"));

  const baseline = officers(s).map(a => [a.x, a.z]);
  const moved = [false, false, false];
  for (let tick = 0; tick < 45 * 20; tick++) {
    stepSimulation(s, 0.05);
    officers(s).forEach((a, index) => {
      moved[index] ||= Math.hypot(a.x - baseline[index][0], a.z - baseline[index][1]) > 0.75;
      assert(a.x >= 37 && a.x <= 44.2 && a.z >= 23.5 && a.z <= 29.2,
        `agent ${a.id} left headquarters without dispatch`);
      assert.equal(a.task, "routine");
    });
  }
  assert.deepEqual(moved, [true, true, true]);
  assert(s.escort.standby.every(member => member.cycles > 0));
});
