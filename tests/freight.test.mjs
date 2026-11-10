import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import {
  decorateTraffic,
  FREIGHT_SPECS,
  updateFreightTraffic,
  trafficVehicleSpeed,
  freightCollision,
} from "../traffic-operations.js";
test("freight variants preserve mission identities while adding distinct lengths, masses and axles", () => {
  const s = createSimulation();
  const ids = s.traffic.map((t) => t.id);
  decorateTraffic(s.traffic);
  assert.deepEqual(
    s.traffic.map((t) => t.id),
    ids,
  );
  assert.equal(s.traffic.filter((t) => t.kind === "truck").length, 3);
  assert.deepEqual(
    new Set(s.traffic.filter((t) => t.freightType).map((t) => t.freightType)),
    new Set(["semi", "boxTruck", "bitrem", "bus"]),
  );
  for (const t of s.traffic.filter((t) => t.freightType)) {
    assert.equal(t.length, FREIGHT_SPECS[t.freightType].length);
    assert(t.axles >= 3);
    assert(t.massKg > 10000);
  }
});
test("night traffic slows and freight yields to a nearby siren while staying on its own side", () => {
  const s = createSimulation();
  decorateTraffic(s.traffic);
  const t = s.traffic.find((t) => t.freightType === "semi");
  Object.assign(t, { x: -3.4, z: 700, stopped: false, evading: false });
  s.car = { x: -3.4, z: 680, siren: true };
  s.checkpoint.vehicleId = null;
  s.mission.targetId = 0;
  for (let i = 0; i < 100; i++) updateFreightTraffic(s, 0.05);
  assert(t.x < -6);
  assert(t.x < 0);
  assert(trafficVehicleSpeed(s, t, 20) <= 6);
  s.car.siren = false;
  s.clock.minute = 23 * 60;
  assert(trafficVehicleSpeed(s, t, 20) < t.baseCruise);
});
test("collision checks use the complete length of bitrem rather than a small car footprint", () => {
  const c = { x: 10, z: 100, heading: 0, ...FREIGHT_SPECS.bitrem };
  assert(freightCollision(10, 113, 0.3, c));
  assert(!freightCollision(10, 115, 0.3, c));
  assert(!freightCollision(12, 100, 0.3, c));
});
