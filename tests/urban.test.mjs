import test from "node:test";
import assert from "node:assert/strict";
import {
  TOWNS,
  URBAN_OBSTACLES,
  URBAN_FACILITIES,
  urbanDriveableArea,
  urbanWalkableArea,
  highwayUrbanExit,
  navigationRoute,
  routeDistance,
  createUrbanState,
  updateUrbanState,
  signalPhase,
} from "../urban-layout.js";
const inside = (p, o) =>
  Math.abs(p.x - o.x) < o.hx - 0.1 && Math.abs(p.z - o.z) < o.hz - 0.1;
const base = () => ({
  urban: createUrbanState(),
  time: 0,
  clock: { minute: 720 },
  mode: "foot",
  player: { x: 27, z: 0 },
  car: { x: 20, z: -8 },
});
test("two towns have road exits, solid blocks and accessible fuel and workshops", () => {
  assert.equal(TOWNS.length, 2);
  for (const t of TOWNS) {
    assert(highwayUrbanExit(t.z));
    for (let x = 0; x < 230; x++) assert(urbanDriveableArea(x, t.z));
    assert(urbanWalkableArea(t.x, t.z + 61));
  }
  for (const f of URBAN_FACILITIES) {
    assert(urbanDriveableArea(f.x, f.z));
    assert(!URBAN_OBSTACLES.some((o) => inside(f, o)));
  }
  assert(!highwayUrbanExit(0));
  assert(!urbanDriveableArea(165, 0));
});
test("GPS follows connected streets to all services and the scale without cutting through buildings", () => {
  for (const destination of [...URBAN_FACILITIES, { x: -4.8, z: -514 }]) {
    const route = navigationRoute({ x: 20, z: -8 }, destination);
    assert(route.length > 2);
    assert.deepEqual(route.at(-1), { x: destination.x, z: destination.z });
    assert(routeDistance(route) > 100);
    for (let i = 1; i < route.length; i++) {
      const a = route[i - 1],
        b = route[i],
        n = Math.ceil(Math.hypot(a.x - b.x, a.z - b.z));
      for (let j = 0; j <= n; j++) {
        const f = j / Math.max(1, n),
          p = { x: a.x + (b.x - a.x) * f, z: a.z + (b.z - a.z) * f };
        assert(
          !URBAN_OBSTACLES.some((o) => inside(p, o)),
          JSON.stringify({ destination, p }),
        );
      }
    }
  }
});
test("commuters are bounded, react to the commander and remain outside buildings through repeated circuits", () => {
  const s = base();
  for (let i = 0; i < 8000; i++) {
    s.time += 0.05;
    updateUrbanState(s, 0.05);
    for (const p of [...s.urban.cars, ...s.urban.pedestrians])
      assert(!URBAN_OBSTACLES.some((o) => inside(p, o)));
  }
  assert.equal(s.urban.cars.length, 4);
  assert.equal(s.urban.pedestrians.length, 8);
  const c = s.urban.cars[0];
  Object.assign(s.player, { x: c.x + 1, z: c.z });
  updateUrbanState(s, 0.05);
  assert.equal(c.speed, 0);
  const before = JSON.stringify(s.urban);
  s.paused = true;
  updateUrbanState(s, 0.05);
  assert.equal(JSON.stringify(s.urban), before);
});
test("urban signals include a clearance interval; red light stops cars before intersection and entered cars clear", () => {
  assert.equal(signalPhase(0), "eastWest");
  assert.equal(signalPhase(14), "clear");
  assert.equal(signalPhase(20), "northSouth");
  const s = base(),
    c = s.urban.cars[0];
  Object.assign(c, { x: 152, z: -553, waypoint: 1 });
  s.time = 20;
  updateUrbanState(s, 0.05);
  assert.equal(c.speed, 0);
  c.x = 163;
  updateUrbanState(s, 0.05);
  assert(c.speed > 0);
});
