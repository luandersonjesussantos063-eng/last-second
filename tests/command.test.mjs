import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation, stepSimulation, circleBlocked } from "../road-sim.js";
import { ROUTINE_ROUTES } from "../autonomous-crew.js";
import {
  clockReading,
  updateShiftClock,
  createShiftClock,
} from "../shift-clock.js";
import {
  agentById,
  nearestAgent,
  issueOrder,
  startCommandMission,
  missionProgress,
  receptionSupport,
} from "../command-sim.js";
const advance = (s, seconds) => {
  for (let i = 0; i < seconds * 20; i++) stepSimulation(s, 0.05);
};
function base() {
  const s = createSimulation();
  Object.assign(s.player, { x: 28.3, z: 16 });
  return s;
}
test("the shift crosses morning, afternoon, night and midnight without advancing during pause or inspection", () => {
  const clock = createShiftClock();
  assert.equal(clockReading(clock).period, "TARDE");
  clock.minute = 6 * 60;
  assert.equal(clockReading(clock).period, "MANHÃ");
  clock.minute = 12 * 60;
  assert.equal(clockReading(clock).period, "TARDE");
  clock.minute = 19 * 60;
  assert.equal(clockReading(clock).lamps, 1);
  clock.minute = 23 * 60 + 59.5;
  updateShiftClock(clock, 1);
  assert.equal(clock.day, 2);
  assert.equal(clock.minute, 0.5);
  const s = base();
  s.paused = true;
  advance(s, 10);
  assert.equal(s.clock.minute, 990);
  s.paused = false;
  s.inspection = true;
  advance(s, 10);
  assert.equal(s.clock.minute, 990);
  s.inspection = false;
  advance(s, 10);
  assert(Math.abs(s.clock.minute - 1000) < 1e-8);
});
test("named proximity orders enforce distance and role; radio reaches a distant agent and logs an acknowledgement", () => {
  const s = base();
  assert.equal(nearestAgent(s), null);
  const silva = agentById(s, 5);
  assert(!issueOrder(s, 5, "blitz", "near"));
  assert(!issueOrder(s, 5, "patrol"));
  Object.assign(s.player, { x: silva.x + 1, z: silva.z });
  assert.equal(nearestAgent(s).name, "Silva");
  assert(issueOrder(s, 5, "blitz", "near"));
  assert.match(s.command.log[0].text, /Presencial.*Silva.*recebido/);
  assert(issueOrder(s, 7, "report"));
  advance(s, 7);
  assert(agentById(s, 7).completed.report > 0);
  assert(s.command.log.some((l) => /Lima.*Informe/.test(l.text)));
  s.paused = true;
  assert(!issueOrder(s, 5, "return"));
});
test("blitz command mission waits for both orders and a newly completed real checkpoint inspection", () => {
  const s = base();
  assert(startCommandMission(s));
  assert(!startCommandMission(s));
  advance(s, 60);
  assert.equal(s.command.mission.stage, "active");
  assert(issueOrder(s, 5, "blitz"));
  assert(issueOrder(s, 6, "blitz"));
  assert.equal(missionProgress(s)[2], false);
  advance(s, 160);
  assert.equal(s.command.mission.stage, "complete");
  assert.equal(s.command.completed, 1);
  assert(s.checkpoint.completed > 0);
  assert(startCommandMission(s));
  assert.equal(s.command.mission.index, 1);
  assert(missionProgress(s).every((v) => !v));
});
test("patrol order makes Rocha walk to and board a real departing vehicle; radio report and departure finish the mission", () => {
  const s = base();
  s.command.mission.index = 1;
  startCommandMission(s);
  assert(issueOrder(s, 8, "patrol"));
  assert(issueOrder(s, 7, "report"));
  const x = agentById(s, 8).x;
  advance(s, 0.5);
  assert(Math.abs(agentById(s, 8).x - x) < 1);
  advance(s, 130);
  assert(s.life.departures > 0);
  assert.equal(s.command.mission.stage, "complete");
  assert(s.command.log.some((l) => /Rocha.*Embarcado/.test(l.text)));
});
test("reception order adds real support and waits for a citizen to finish service after the reinforcement arrives", () => {
  const s = base();
  s.command.mission.index = 2;
  startCommandMission(s);
  issueOrder(s, 1, "reception");
  assert(!receptionSupport(s));
  advance(s, 5);
  assert(receptionSupport(s));
  assert.equal(s.command.mission.stage, "active");
  advance(s, 130);
  assert(s.reception.agentCompleted > 0);
  assert.equal(s.command.mission.stage, "complete");
  assert(issueOrder(s, 1, "return"));
  advance(s, 5);
  assert(!receptionSupport(s));
  assert(Math.abs(agentById(s, 1).x - 38) < 0.12);
});
test("perimeter mission requires the full physical round and both motorcycle confirmations; state and logs remain bounded", () => {
  const s = base();
  s.command.mission.index = 3;
  startCommandMission(s);
  issueOrder(s, 8, "perimeter");
  issueOrder(s, 16, "ready");
  issueOrder(s, 17, "ready");
  advance(s, 6);
  assert.equal(s.command.mission.stage, "active");
  assert(missionProgress(s)[1]);
  advance(s, 110);
  assert.equal(s.command.mission.stage, "complete");
  assert(agentById(s, 8).completed.perimeter > 0);
  advance(s, 600);
  assert.equal(s.command.agents.length, 8);
  assert(s.command.log.length <= 12);
  for (const a of s.command.agents)
    assert(Number.isFinite(a.x) && Number.isFinite(a.z));
});

test("radio reports preserve an ongoing motorcycle response and the commander can recall an external patrol", () => {
  const s = base(),
    rocha = agentById(s, 8),
    santos = agentById(s, 16);
  s.life.bikes[0].stage = "pursuit";
  assert(issueOrder(s, 16, "report"));
  assert.equal(s.life.bikes[0].stage, "pursuit");
  assert.equal(santos.task, "routine");
  assert(!issueOrder(s, 16, "ready"));
  rocha.task = "patrol";
  rocha.embarked = true;
  rocha.visible = false;
  s.life.patrol.stage = "away";
  assert(issueOrder(s, 8, "report"));
  assert.equal(rocha.task, "patrol");
  assert(rocha.embarked);
  assert(issueOrder(s, 8, "return"));
  assert.equal(s.life.patrol.stage, "returning");
  assert.equal(rocha.task, "patrol");
});

test("the entrance sensor still admits citizens when the commander is in the vehicle", () => {
  const s = base();
  s.mode = "drive";
  const v = s.reception.visitors[0];
  Object.assign(v, { state: "enter", x: 35, z: 10, waypoint: 1 });
  s.reception.nextArrival = 30;
  advance(s, 1);
  assert(s.door > 0.82);
});


test("officers autonomously perform routine walks and return without teleporting", () => {
  const s = base();
  const lima = agentById(s, 7);
  const first = { x: lima.x, z: lima.z };
  let traveled = false;
  for (let i = 0; i < 1200; i++) {
    const prev = { x: lima.x, z: lima.z };
    stepSimulation(s, 0.05);
    const distance = Math.hypot(lima.x - prev.x, lima.z - prev.z);
    assert(distance < 0.2, "routine agent must not teleport");
    if (Math.hypot(lima.x - first.x, lima.z - first.z) > 0.3) traveled = true;
  }
  assert(traveled, "radio officer must walk during routine");
  assert(Math.hypot(lima.x - first.x, lima.z - first.z) < 0.2, "officer returns to post");
});
test("command orders interrupt autonomous routes without preventing reports", () => {
  const s = base();
  advance(s, 25);
  const lima = agentById(s, 7);
  assert(issueOrder(s, 7, "report"));
  advance(s, 7);
  assert((lima.completed.report ?? 0) > 0);
  assert.equal(lima.task, "routine");
});

test("all autonomous walking loops are longer than a few steps and clear of solid scenery", () => {
  const s = base();
  for (const [idText, route] of Object.entries(ROUTINE_ROUTES)) {
    const agent = agentById(s, Number(idText));
    let previous = [agent.home.x, agent.home.z];
    let total = 0;
    for (const target of route) {
      const segment = Math.hypot(target[0] - previous[0], target[1] - previous[1]);
      total += segment;
      const steps = Math.max(1, Math.ceil(segment / 0.2));
      for (let i = 0; i <= steps; i++) {
        const f = i / steps;
        const x = previous[0] + (target[0] - previous[0]) * f;
        const z = previous[1] + (target[1] - previous[1]) * f;
        assert.equal(circleBlocked(x, z, 0.32), false, `${agent.name} collides with scenery at ${x}, ${z}`);
      }
      previous = target;
    }
    assert(total > 14, `${agent.name} should walk more than 14 metres, not just a few steps`);
    assert(Math.hypot(previous[0] - agent.home.x, previous[1] - agent.home.z) < 0.1);
  }
});

test("Lima and Rocha meet physically, face one another and take turns in visible scripted conversation", () => {
  const s = base();
  let sawApproach = false;
  let sawConversation = false;
  const speakers = new Set();
  let biggestDistance = 0;
  for (let i = 0; i < 850; i++) {
    stepSimulation(s, 0.05);
    const a = agentById(s, 7);
    biggestDistance = Math.max(biggestDistance, Math.hypot(a.x - a.home.x, a.z - a.home.z));
    const chat = s.command.conversation;
    if (chat?.ids.includes(7)) {
      if (chat.phase === "approach") sawApproach = true;
      if (chat.phase === "talk") {
        sawConversation = true;
        speakers.add(chat.speaker);
        assert.equal(typeof chat.text, "string");
        assert(chat.text.length > 15);
        const b = agentById(s, 8);
        assert(Math.hypot(a.x - b.x, a.z - b.z) < 3.5);
        assert.equal(a.status, "Conversando com " + b.name);
      }
    }
  }
  assert(sawApproach, "they should walk towards their meeting point");
  assert(sawConversation, "they should pause to talk");
  assert.deepEqual([...speakers].sort(), [7, 8]);
  assert(biggestDistance > 10, "Lima should move at least 10 metres from his post");
});

test("a new order interrupts a dialogue, returns the colleague, and preserves radio reporting", () => {
  const s = base();
  for (let i = 0; i < 850 && s.command.conversation?.phase !== "talk"; i++) {
    stepSimulation(s, 0.05);
  }
  assert.equal(s.command.conversation?.phase, "talk");
  assert(issueOrder(s, 7, "report"));
  assert.equal(s.command.conversation, null);
  advance(s, 7);
  assert((agentById(s, 7).completed.report ?? 0) > 0);
  const rocha = agentById(s, 8);
  advance(s, 14);
  assert(Math.hypot(rocha.x - rocha.home.x, rocha.z - rocha.home.z) < 0.3);
});

test("motopatrulha colleagues converse only while both motorcycles are ready", () => {
  const s = base();
  let motorcycleTalk = false;
  for (let i = 0; i < 1900; i++) {
    stepSimulation(s, 0.05);
    const chat = s.command.conversation;
    if (chat?.phase === "talk" && chat.ids[0] === 16) {
      motorcycleTalk = true;
      assert.equal(s.life.bikes[0].stage, "ready");
      assert.equal(s.life.bikes[1].stage, "ready");
      assert(chat.text.length > 8);
      break;
    }
  }
  assert(motorcycleTalk);
});
