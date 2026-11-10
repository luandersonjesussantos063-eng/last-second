// Three bounded administrative tow jobs; original traffic cars remain authoritative.
const state = (s) =>
  (s.operations.impound ??= { jobs: [], completed: 0, sequence: 0 });
const carFor = (s, id) => s.traffic.find((c) => c.id === id);
export function beginImpound(s, t) {
  if (!s.operations || !t || s.paused) return false;
  const c = state(s);
  const old = c.jobs.find((j) => j.vehicleId === t.id);
  if (old) return old;
  if (c.jobs.length === 3) {
    const index = c.jobs.findIndex((j) => j.stage === "stored");
    if (index < 0) return false;
    const previous = carFor(s, c.jobs[index].vehicleId);
    if (previous)
      Object.assign(previous, {
        impounded: false,
        impoundCarried: false,
        impoundStored: false,
        stopped: false,
        x: previous.direction > 0 ? -3.4 : 3.4,
        z: -1450 * (previous.direction || 1),
        speed: 0,
      });
    c.jobs.splice(index, 1);
  }
  const used = new Set(c.jobs.map((j) => j.slot));
  let slot = 0;
  while (used.has(slot)) slot++;
  const dir = t.direction || 1,
    stopZ = t.z + dir * 6.5;
  const j = {
    id: ++c.sequence,
    vehicleId: t.id,
    plate: t.plate,
    targetColor: t.color ?? 0x687e8d,
    slot,
    stage: "enroute",
    x: t.x,
    z: t.z - dir * 70,
    heading: dir > 0 ? 0 : Math.PI,
    speed: 0,
    visible: true,
    elapsed: 0,
    waypoint: 0,
    length: 6.6,
    width: 2.4,
    load: false,
    loadX: -28 - slot * 5,
    loadZ: -520,
    route: [[t.x, stopZ]],
    transportRoute: [
      [t.x, stopZ + dir * 20],
      [t.x, -450],
      [-9, -450],
      [-9, -460],
      [-19, -480],
      [-28 - slot * 5, -490],
      [-28 - slot * 5, -520],
    ],
  };
  Object.assign(t, {
    impounded: true,
    impoundCarried: false,
    impoundStored: false,
    stopped: true,
    speed: 0,
  });
  c.jobs.push(j);
  return j;
}
function move(s, j, p, dt, speed) {
  const dx = p[0] - j.x,
    dz = p[1] - j.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, dt * speed);
  if (d < 0.12) {
    j.speed = 0;
    return true;
  }
  const x = j.x + (dx / d) * step,
    z = j.z + (dz / d) * step;
  const near = (o, r) => Math.hypot(o.x - x, o.z - z) < r;
  if (
    (s.mode === "foot" && near(s.player, 2.2)) ||
    [
      s.car,
      ...s.traffic.filter((c) => c.id !== j.vehicleId && !c.impounded),
    ].some((o) => near(o, 3))
  ) {
    j.speed = 0;
    j.blocked = true;
    return false;
  }
  j.blocked = false;
  j.x = x;
  j.z = z;
  j.heading = Math.atan2(dx, dz);
  j.speed = speed;
  return false;
}
export function updateImpound(s, dt) {
  if (!s.operations || s.paused || s.inspection) return;
  dt = Math.max(0, Math.min(0.05, dt));
  const c = state(s);
  for (const j of c.jobs) {
    const t = carFor(s, j.vehicleId);
    if (!t) continue;
    if (
      j.stage === "enroute" &&
      move(s, j, j.route[j.waypoint], dt, 10) &&
      ++j.waypoint === j.route.length
    ) {
      j.stage = "loading";
      j.elapsed = 0;
      j.speed = 0;
    } else if (j.stage === "loading") {
      j.elapsed += dt;
      if (j.elapsed >= 3) {
        j.load = true;
        t.impoundCarried = true;
      }
      if (j.elapsed >= 7) {
        j.stage = "transport";
        j.waypoint = 0;
      }
    } else if (
      j.stage === "transport" &&
      move(s, j, j.transportRoute[j.waypoint], dt, 14) &&
      ++j.waypoint === j.transportRoute.length
    ) {
      j.stage = "stored";
      j.visible = false;
      j.load = false;
      t.impoundStored = true;
      c.completed++;
      s.notice = t.plate + " recolhido ao pátio";
      s.noticeUntil = s.time + 7;
    }
    if (j.stage === "stored")
      Object.assign(t, {
        x: j.loadX,
        z: j.loadZ,
        heading: 0,
        speed: 0,
        stopped: true,
      });
    else if (j.load)
      Object.assign(t, {
        x: j.x - Math.sin(j.heading) * 1.3,
        z: j.z - Math.cos(j.heading) * 1.3,
        heading: j.heading,
        speed: 0,
        stopped: true,
      });
  }
}
export function impoundVehicles(s) {
  return s.operations?.impound?.jobs.filter((j) => j.visible) ?? [];
}
