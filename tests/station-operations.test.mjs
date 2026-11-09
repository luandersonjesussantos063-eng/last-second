import test from "node:test";
import assert from "node:assert/strict";
import {
  StationTraffic,
  createStationWorkers,
  updateStationWorkers,
} from "../station-operations.js";

test("each ship completes boarding, departure, return and disembarkation with one runway owner", () => {
  const t = new StationTraffic(),
    seen = t.ships.map(() => new Set());
  for (let frame = 0; frame < 60 * 600; frame++) {
    t.update(1 / 60);
    t.ships.forEach((s, i) => seen[i].add(s.state));
    const onRunway = t.ships.filter((s) =>
      [
        "clearance",
        "taxiOut",
        "depart",
        "approach",
        "returning",
        "taxiIn",
      ].includes(s.state),
    );
    assert(onRunway.length <= 1);
    assert.equal(onRunway[0]?.id ?? null, t.owner);
    for (const s of t.ships)
      if (
        ["depart", "patrol", "approach", "returning", "taxiIn"].includes(
          s.state,
        )
      )
        assert(!s.pilot.visible);
  }
  for (let i = 0; i < 3; i++) {
    for (const state of [
      "boarding",
      "embarking",
      "depart",
      "patrol",
      "approach",
      "returning",
      "disembarking",
      "debrief",
    ])
      assert(seen[i].has(state), `${t.ships[i].id} missing ${state}`);
    assert(t.ships[i].cycles >= 1);
  }
  assert(t.completedFlights >= 3);
});
test("player priority stops new clearances but permits the current ship to release the runway", () => {
  const t = new StationTraffic();
  for (let i = 0; i < 2400; i++) t.update(1 / 60, { playerPriority: true });
  assert(!t.busy);
  assert(t.ships.every((s) => s.state === "ready"));
  t.update(1 / 60);
  assert(t.busy);
  for (let i = 0; i < 1200; i++) t.update(1 / 60, { playerPriority: true });
  assert(!t.busy);
});
test("pedestrians inhibit clearance and moving ships stop before entering an occupied lane", () => {
  const t = new StationTraffic(),
    walker = { x: -20, y: -3.55, z: 32 };
  for (let i = 0; i < 900; i++) t.update(1 / 60, { walker });
  assert.equal(t.ships[0].state, "ready");
  assert(t.ships[0].blocked);
  for (let i = 0; i < 180; i++) t.update(1 / 60);
  const s = t.ships[0];
  assert.equal(s.state, "taxiOut");
  walker.x = -10.5;
  walker.z = 50;
  const x = s.x;
  for (let i = 0; i < 180; i++) t.update(1 / 60, { walker });
  assert.equal(s.x, x);
  assert(s.blocked);
  for (let i = 0; i < 1800; i++) t.update(1 / 60);
  assert.notEqual(s.state, "taxiOut");
});
test("workers perform duties at real stations and command operators stay at their consoles", () => {
  const workers = createStationWorkers();
  for (let i = 0; i < 600; i++) updateStationWorkers(workers, 1 / 60);
  assert(workers.every((w) => w.role && w.action && w.stations.length));
  const ops = workers.filter((w) => w.floor > 0 && w.stations[0][1] > 85);
  assert.equal(ops.length, 3);
  assert(ops.every((w) => !w.moving && w.action === "typing"));
  assert(workers.some((w) => w.moving));
  const away = [{ state: "patrol" }, { state: "patrol" }, { state: "patrol" }];
  for (let i = 0; i < 1800; i++) updateStationWorkers(workers, 1 / 60, away);
  assert(
    workers
      .slice(0, 3)
      .every((w) => !w.moving && w.action === "typing" && w.station === 0),
  );
});
