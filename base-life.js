// Shared platform heights and moving support units; bounded state, metres/seconds.
export const BASE_HEIGHT = 0.6;
export function floorHeight(x, z) {
  if (x >= 26 && x <= 44 && z >= 9 && z <= 30) return BASE_HEIGHT;
  if (x >= 33 && x <= 36.7 && z >= 6 && z < 9)
    return Math.min(0.6, (Math.floor((z - 6) / 1) + 1) * 0.2);
  if (x > 36.7 && x <= 39 && z >= 3 && z < 9) return (0.6 * (z - 3)) / 6;
  return 0;
}
export const PARKING = Array.from({ length: 6 }, (_, i) => ({
  x: 29 + i * 4.1,
  z: -13,
  heading: 0,
}));
export function createBaseLife() {
  return {
    patrol: {
      x: 19,
      z: 32,
      heading: Math.PI,
      speed: 0,
      lights: false,
      stage: "parked",
      elapsed: 0,
      waypoint: 0,
    },
    bikes: [0, 1].map((i) => ({
      x: 17 + i * 2.1,
      z: -23,
      heading: Math.PI,
      speed: 0,
      lights: false,
      stage: "ready",
      homeX: 17 + i * 2.1,
    })),
    evasion: {
      stage: "idle",
      vehicleId: null,
      nextAt: 95,
      elapsed: 0,
      completed: 0,
    },
    departures: 0,
  };
}
export function moveVehicle(s, c, x, z, dt, speed = 6) {
  const dx = x - c.x,
    dz = z - c.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, speed * dt);
  if (d < 0.12) {
    c.speed = 0;
    return true;
  }
  const nx = c.x + (dx / d) * step,
    nz = c.z + (dz / d) * step;
  const near = (p, r) => Math.hypot(p.x - nx, p.z - nz) < r;
  const traffic = s.traffic.filter(
    (t) => t !== c && t.id !== s.life?.evasion.vehicleId,
  );
  const other = [
    s.car,
    ...s.support.filter((p) => p !== c),
    ...traffic,
    ...s.reception.visitors
      .filter((v) => v.car !== c && v.car.visible)
      .map((v) => v.car),
  ];
  if (
    (s.mode === "foot" && near(s.player, 2.6)) ||
    other.some((p) => near(p, 3.5))
  ) {
    c.speed = 0;
    return false;
  }
  c.heading = Math.atan2(dx, dz);
  c.x = nx;
  c.z = nz;
  c.speed = speed;
  return false;
}
export function updateBaseLife(s, dt) {
  const l = s.life,
    p = l.patrol;
  s.support[2] = p;
  p.elapsed += dt;
  const routes = {
    depart: [
      [19, 42],
      [8.8, 43],
      [3.4, 40],
      [3.4, -520],
    ],
    returning: [
      [-3.4, -65],
      [8.8, -42],
      [15, -38],
      [24, -35],
      [25, -25],
      [21, -16],
      [16, -14],
      [16, 32],
      [19, 32],
    ],
  };
  if (
    p.stage === "parked" &&
    p.elapsed > 48 &&
    !s.command?.agents.some((a) => a.task === "patrol")
  ) {
    p.stage = "depart";
    p.waypoint = 0;
    p.elapsed = 0;
    l.departures++;
  } else if (routes[p.stage]) {
    const route = routes[p.stage],
      point = route[p.waypoint];
    if (
      moveVehicle(
        s,
        p,
        ...point,
        dt,
        p.stage === "depart" && p.waypoint === 3 ? 19 : 5,
      ) &&
      ++p.waypoint === route.length
    ) {
      p.stage = p.stage === "depart" ? "away" : "parked";
      p.elapsed = 0;
      p.speed = 0;
      p.lights = false;
      if (p.stage === "parked") p.heading = Math.PI;
    }
  } else if (p.stage === "away" && p.elapsed > 90) {
    p.stage = "returning";
    p.waypoint = 0;
    p.x = -3.4;
    p.z = -520;
    p.elapsed = 0;
  }
  const e = l.evasion;
  e.nextAt -= dt;
  if (e.stage === "idle" && e.nextAt <= 0) {
    const c = s.traffic.find(
      (t) =>
        t.direction === 1 &&
        t.kind !== "motorcycle" && t.kind !== "truck" &&
        t.id !== s.mission.targetId &&
        t.id !== s.checkpoint.vehicleId &&
        t.z > -150 &&
        t.z < -45,
    );
    if (c) {
      e.stage = "pursuit";
      e.vehicleId = c.id;
      e.elapsed = 0;
      c.evading = true;
      c.stopped = false;
      for (const b of l.bikes) {
        b.stage = "pursuit";
        b.lights = true;
        b.launch = 0;
      }
    }
  }
  if (e.stage === "pursuit") {
    e.elapsed += dt;
    const target = s.traffic.find((t) => t.id === e.vehicleId);
    if (!target) {
      e.stage = "return";
    } else {
      s.checkpoint.status = `EVASÃO • MOTOPATRULHA EM ACOMPANHAMENTO • ${target.plate}`;
      target.speed = target.z > 390 ? 5 : 18;
      target.z += target.speed * dt;
      l.bikes.forEach((b, i) => {
        const launch = [
          [15, -40],
          [-3.4, -40],
          [-3.4, 50],
        ];
        if (b.launch < launch.length) {
          if (moveVehicle(s, b, ...launch[b.launch], dt, 25)) b.launch++;
        } else moveVehicle(s, b, -7.7 - i * 1.6, target.z - 6 - i * 4, dt, 29);
      });
      if (
        e.elapsed > 18 &&
        l.bikes.some((b) => Math.hypot(b.x - target.x, b.z - target.z) < 22)
      ) {
        e.stopFrom = { x: target.x, z: target.z };
        target.speed = 6;
        e.stage = "detained";
        e.elapsed = 0;
      }
    }
  } else if (e.stage === "detained") {
    e.elapsed += dt;
    const stopped = s.traffic.find((t) => t.id === e.vehicleId);
    if (stopped) {
      const f = Math.min(1, e.elapsed / 4);
      stopped.x = e.stopFrom.x + (-9 - e.stopFrom.x) * f;
      stopped.z = e.stopFrom.z + 15 * f;
      stopped.speed = 6 * (1 - f);
      stopped.stopped = f === 1;
    }
    l.bikes.forEach((b, i) => {
      if (stopped)
        moveVehicle(s, b, -7.5 - i * 2, stopped.z - 6 - i * 3, dt, 8);
    });
    s.checkpoint.status = "MOTOPATRULHA • VEÍCULO INTERCEPTADO NO ACOSTAMENTO";
    if (e.elapsed > 12) {
      const t = s.traffic.find((t) => t.id === e.vehicleId);
      if (t) {
        t.evading = false;
        t.stopped = false;
        t.x = -3.4;
        t.speed = 8;
      }
      e.stage = "return";
      l.bikes.forEach((b) => {
        b.waypoint = 0;
        b.turnZ = b.z + 30;
      });
      e.completed++;
    }
  } else if (e.stage === "return") {
    let home = true;
    for (const b of l.bikes) {
      if (b.stage === "ready") continue;
      b.stage = "return";
      b.waypoint ??= 0;
      b.turnZ ??= b.z + 30;
      const route = [
        [3.4, b.turnZ],
        [3.4, -40],
        [b.homeX, -40],
        [b.homeX, -23],
      ];
      const point = route[b.waypoint];
      if (
        moveVehicle(s, b, ...point, dt, 15) &&
        ++b.waypoint === route.length
      ) {
        b.stage = "ready";
        b.heading = Math.PI;
        b.lights = false;
      } else home = false;
    }
    if (home) {
      e.stage = "idle";
      e.vehicleId = null;
      e.nextAt = 150;
    }
  }
}
