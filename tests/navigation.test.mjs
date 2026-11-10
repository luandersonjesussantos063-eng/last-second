import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import { moveCrewAgent, crewPositionClear } from "../crew-navigation.js";
function fixture(goal = [10, 0]) {
  const s = createSimulation();
  s.mode = "foot";
  s.player.x = 50;
  s.player.z = 40;
  const a = s.command.agents.find((a) => a.id === 8);
  Object.assign(a, { x: 0, z: 0, path: [goal], waypoint: 0, navigation: null });
  return { s, a };
}
function walk(s, a, seconds, obstacles = []) {
  let done = false;
  for (let i = 0; i < seconds * 20 && !done; i++) {
    s.time += 0.05;
    const x = a.x,
      z = a.z;
    done = moveCrewAgent(s, a, 0.05, obstacles);
    assert(Math.hypot(a.x - x, a.z - z) < 0.09);
    assert(crewPositionClear(s, a, a.x, a.z, obstacles, false));
  }
  return done;
}
test("bounded navigation detours around furniture without crossing geometry or teleporting", () => {
  const { s, a } = fixture();
  const furniture = [{ x: 5, z: 0, hx: 1, hz: 2 }];
  assert(walk(s, a, 15, furniture));
  assert(Math.hypot(a.x - 10, a.z) < 0.2);
  assert((a.navigation?.points.length ?? 0) <= 32);
});
test("parked vehicles are considered during path planning", () => {
  const { s, a } = fixture();
  Object.assign(s.car, { x: 5, z: 0, heading: 0, speed: 0 });
  assert(walk(s, a, 16));
  assert(a.x > 9.8);
});
test("an occupied destination waits for a person and resumes after the person moves", () => {
  const { s, a } = fixture([2, 0]);
  Object.assign(s.player, { x: 2, z: 0 });
  assert(!walk(s, a, 2));
  assert(Math.hypot(a.x - 2, a.z) > 0.7);
  Object.assign(s.player, { x: 50, z: 40 });
  assert(walk(s, a, 5));
});
test("an enclosed target has bounded planning state and remains finite", () => {
  const { s, a } = fixture([2, 0]);
  const walls = [
    { x: 0.7, z: 0, hx: 0.1, hz: 5 },
    { x: -0.7, z: 0, hx: 0.1, hz: 5 },
    { x: 0, z: 4.8, hx: 0.8, hz: 0.1 },
    { x: 0, z: -4.8, hx: 0.8, hz: 0.1 },
  ];
  assert(!walk(s, a, 4, walls));
  assert(Number.isFinite(a.x) && Number.isFinite(a.z));
  assert((a.navigation?.points.length ?? 0) <= 32);
});
