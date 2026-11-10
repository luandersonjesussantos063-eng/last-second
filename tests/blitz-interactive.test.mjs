import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation, stepSimulation } from "../road-sim.js";
import {
  beginSearch,
  inspectPart,
  finishSearch,
  returnSearch,
} from "../blitz-search.js";
import { issueOrder, orderAvailable } from "../command-sim.js";
import { scalePaved } from "../scale-access.js";
import { interactWeighbridge, updateWeighbridge } from "../weighbridge-sim.js";
function setup() {
  const s = createSimulation(),
    t = s.traffic[2];
  Object.assign(t, { x: -9, z: 20, speed: 0, stopped: true });
  Object.assign(s.player, { x: -11, z: 20 });
  s.checkpoint.phase = "active";
  s.checkpoint.operationUntil = 1000;
  s.checkpoint.stage = "checking";
  s.checkpoint.vehicleId = t.id;
  return s;
}
test("commander takes over a blitz inspection; documents precede searches and all three checks precede release", () => {
  const s = setup();
  assert(beginSearch(s));
  assert(!inspectPart(s, "cargo"));
  assert(!finishSearch(s, "release"));
  for (let i = 0; i < 250; i++) stepSimulation(s, 0.05);
  assert.equal(s.checkpoint.stage, "checking");
  assert(inspectPart(s, "documents"));
  assert.match(s.blitzSearch.result, /CNH/);
  assert(inspectPart(s, "cabin"));
  assert(inspectPart(s, "cargo"));
  assert(finishSearch(s, "fine"));
  assert.equal(s.checkpoint.stage, "release");
  assert(s.operations.records[0].text.includes("autuação"));
});
test("retention starts a real tow instead of releasing a searched vehicle", () => {
  const s = setup();
  beginSearch(s);
  for (const p of ["documents", "cabin", "cargo"]) inspectPart(s, p);
  assert(finishSearch(s, "retain"));
  assert(s.traffic[2].impounded);
  assert.equal(s.checkpoint.stage, "cooldown");
});
test("returning control allows the team to resume; pause/distance prevent new searches", () => {
  const s = setup();
  beginSearch(s);
  returnSearch(s);
  assert(!s.checkpoint.manualHold);
  s.paused = true;
  assert(!beginSearch(s));
  s.paused = false;
  s.player.z = 200;
  assert(!beginSearch(s));
});
test("all visible on-foot agents can be redeployed, and assignments survive routines", () => {
  const s = createSimulation();
  for (const a of s.command.agents) {
    if (a.id >= 21) {
      a.visible = true;
      a.task = "backup";
      s.escort.backup.stage = "onScene";
    }
    assert(orderAvailable(s, a, "dutyAdmin"));
    assert(issueOrder(s, a.id, "dutyAdmin"));
    assert.equal(a.task, "assigned");
  }
  for (let i = 0; i < 100; i++) stepSimulation(s, 0.05);
  for (const a of s.command.agents) assert.equal(a.task, "assigned");
  assert(issueOrder(s, 5, "dutyRound"));
  assert(issueOrder(s, 0, "dutyBlitz"));
});
test("scale arrival, departure and all retained freight centres remain on paved ground over repeated cycles", () => {
  const s = createSimulation();
  Object.assign(s.player, {
    x: s.weighbridge.kiosk.x,
    z: s.weighbridge.kiosk.z,
  });
  for (let i = 0; i < 12000; i++) {
    if (["ready", "weighed"].includes(s.weighbridge.stage))
      interactWeighbridge(s);
    s.time += 0.05;
    updateWeighbridge(s, 0.05);
    const t = s.weighbridge.truck;
    if (t.visible)
      assert(scalePaved(t.x, t.z), `truck off pavement ${t.x},${t.z}`);
  }
  assert(s.weighbridge.completed >= 4);
});
