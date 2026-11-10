import { BASE_COLUMNS } from "./base-layout.js?v=2.23.0";
import { floorHeight } from "./base-life.js?v=2.23.0";
const R = 0.3;
const FURNITURE = [
  ...BASE_COLUMNS,
  { x: 33, z: 12.2, hx: 0.13, hz: 2.2 },
  { x: 33, z: 20.3, hx: 0.13, hz: 2.3 },
  { x: 29.5, z: 20.8, hx: 3.5, hz: 0.13 },
  { x: 29.9, z: 16, hx: 0.55, hz: 1.5 },
  { x: 26, z: 20, hx: 0.35, hz: 10 },
  { x: 44, z: 20, hx: 0.35, hz: 10 },
  { x: 35, z: 30, hx: 9.3, hz: 0.35 },
  { x: 29.7, z: 10, hx: 3.7, hz: 0.35 },
  { x: 40.3, z: 10, hx: 3.7, hz: 0.35 },
  { x: 35, z: 24, hx: 3.5, hz: 1.1 },
  { x: 41, z: 17, hx: 1, hz: 2 },
  { x: 49, z: -23, hx: 1.2, hz: 2 },
];
export function crewObstacles(s) {
  const o = FURNITURE.slice();
  if (s.door < 0.82) o.push({ x: 35, z: 10, hx: 1.6, hz: 0.18 });
  if (s.roomDoor < 0.82) o.push({ x: 33, z: 16, hx: 0.13, hz: 1.8 });
  return o;
}
function blocked(x, z, obstacles) {
  return obstacles.some((o) => {
    if (o.radius !== undefined) return Math.hypot(x - o.x, z - o.z) < o.radius;
    const dx = Math.max(Math.abs(x - o.x) - o.hx, 0),
      dz = Math.max(Math.abs(z - o.z) - o.hz, 0);
    return dx * dx + dz * dz < R * R;
  });
}
const cars = (s) => [
  s.car,
  ...s.traffic,
  ...s.support,
  ...s.life.bikes,
  ...(s.heavy?.vehicles ?? []),
  ...(s.urban?.cars ?? []),
  ...s.reception.visitors.filter((v) => v.car.visible).map((v) => v.car),
];
function nearCar(c, x, z) {
  if (c.visible === false) return false;
  const dx = x - c.x,
    dz = z - c.z,
    si = Math.sin(c.heading ?? 0),
    co = Math.cos(c.heading ?? 0),
    w = (c.width ?? 2.5) / 2,
    l = (c.length ?? (c.kind === "truck" ? 15 : 4.8)) / 2;
  return (
    Math.abs(dx * co - dz * si) < w + R && Math.abs(dx * si + dz * co) < l + R
  );
}
export function crewPositionClear(
  s,
  a,
  x,
  z,
  obstacles = crewObstacles(s),
  dynamic = true,
) {
  if (!Number.isFinite(x) || !Number.isFinite(z) || blocked(x, z, obstacles))
    return false;
  if (Math.abs(floorHeight(x, z) - floorHeight(a.x, a.z)) > 0.24) return false;
  if (!dynamic) return true;
  if (s.mode === "foot" && Math.hypot(x - s.player.x, z - s.player.z) < 0.73)
    return false;
  if (
    s.command.agents.some(
      (p) =>
        p !== a &&
        p.visible &&
        !p.embarked &&
        p.action !== "seated" &&
        Math.hypot(p.x - x, p.z - z) < 0.57,
    )
  )
    return false;
  if (
    s.reception.visitors.some(
      (v) =>
        !["away", "arriving", "drivingOut"].includes(v.state) &&
        Math.hypot(v.x - x, v.z - z) < 0.6,
    )
  )
    return false;
  return !cars(s).some((c) => nearCar(c, x, z));
}
function swept(s, a, x, z, obstacles, dynamic = true) {
  const d = Math.hypot(x - a.x, z - a.z),
    n = Math.max(1, Math.ceil(d / 0.1));
  for (let i = 1; i <= n; i++) {
    if (
      !crewPositionClear(
        s,
        a,
        a.x + ((x - a.x) * i) / n,
        a.z + ((z - a.z) * i) / n,
        obstacles,
        dynamic,
      )
    )
      return false;
  }
  return true;
}
function planningObstacles(s, a, obstacles, goal) {
  const all = obstacles.slice();
  if (s.mode === "foot")
    all.push({ x: s.player.x, z: s.player.z, radius: 0.74 });
  for (const c of cars(s)) {
    if (c.visible === false || Math.abs(c.speed ?? 0) > 0.1) continue;
    const h = c.heading ?? 0,
      w = (c.width ?? 2.5) / 2,
      l = (c.length ?? (c.kind === "truck" ? 15 : 4.8)) / 2;
    all.push({
      x: c.x,
      z: c.z,
      hx: Math.abs(Math.cos(h)) * w + Math.abs(Math.sin(h)) * l,
      hz: Math.abs(Math.sin(h)) * w + Math.abs(Math.cos(h)) * l,
    });
  }
  for (const p of s.command.agents) {
    if (
      p === a ||
      !p.visible ||
      p.embarked ||
      p.moving ||
      p.action === "seated" ||
      Math.hypot(p.x - goal[0], p.z - goal[1]) < 0.7
    )
      continue;
    all.push({ x: p.x, z: p.z, hx: 0.28, hz: 0.28 });
  }
  return all;
}
function routeAround(s, a, goal, obstacles) {
  const all = planningObstacles(s, a, obstacles, goal),
    step = 0.5,
    ox = a.x,
    oz = a.z;
  const maxX = Math.min(80, Math.ceil(Math.abs(goal[0] - ox) / step) + 16),
    maxZ = Math.min(100, Math.ceil(Math.abs(goal[1] - oz) / step) + 16);
  const key = (x, z) => x + "," + z,
    heuristic = (x, z) =>
      Math.hypot(ox + x * step - goal[0], oz + z * step - goal[1]);
  const first = { x: 0, z: 0, g: 0, f: heuristic(0, 0), parent: null },
    open = [first],
    best = new Map([[key(0, 0), 0]]);
  let found = null,
    count = 0;
  while (open.length && count++ < 1800) {
    let at = 0;
    for (let i = 1; i < open.length; i++) if (open[i].f < open[at].f) at = i;
    const n = open.splice(at, 1)[0],
      wx = ox + n.x * step,
      wz = oz + n.z * step;
    if (heuristic(n.x, n.z) < 0.7 && !blocked(goal[0], goal[1], all)) {
      const tmp = { ...a, x: wx, z: wz };
      if (swept(s, tmp, goal[0], goal[1], all, false)) {
        found = n;
        break;
      }
    }
    for (const [dx, dz] of [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ]) {
      const x = n.x + dx,
        z = n.z + dz;
      if (Math.abs(x) > maxX || Math.abs(z) > maxZ) continue;
      const g = n.g + Math.hypot(dx, dz),
        k = key(x, z);
      if ((best.get(k) ?? Infinity) <= g) continue;
      const tmp = { ...a, x: wx, z: wz };
      if (!swept(s, tmp, ox + x * step, oz + z * step, all, false)) continue;
      best.set(k, g);
      open.push({ x, z, g, f: g + heuristic(x, z) / step, parent: n });
    }
  }
  if (!found) return [];
  const points = [goal.slice()];
  for (let n = found; n?.parent; n = n.parent)
    points.push([ox + n.x * step, oz + n.z * step]);
  points.reverse();
  if (points.length > 96) return []; // bounded navigation memory
  // Keep a turn-aware route but remove redundant grid points.
  const smooth = [];
  let previous = { ...a };
  for (let i = 0; i < points.length; ) {
    let end = i;
    while (
      end + 1 < points.length &&
      swept(s, previous, points[end + 1][0], points[end + 1][1], all, false)
    )
      end++;
    smooth.push(points[end]);
    previous = { ...a, x: points[end][0], z: points[end][1] };
    i = end + 1;
  }
  return smooth.slice(0, 32);
}
export function moveCrewAgent(
  s,
  a,
  dt,
  obstacles = crewObstacles(s),
  speed = 1.55,
) {
  const goal = a.path[a.waypoint];
  a.moving = false;
  if (!goal) return true;
  if (
    a.waypoint < a.path.length - 1 &&
    s.mode === "foot" &&
    Math.hypot(goal[0] - s.player.x, goal[1] - s.player.z) < 0.76 &&
    Math.hypot(a.x - goal[0], a.z - goal[1]) < 1.1
  ) {
    a.waypoint++;
    a.navigation = null;
    return false;
  }
  if (Math.hypot(goal[0] - a.x, goal[1] - a.z) < 0.12) {
    a.waypoint++;
    a.navigation = null;
    return a.waypoint >= a.path.length;
  }
  if (a.navigation?.goal !== goal)
    a.navigation = { goal, points: [], index: 0, nextPlan: 0 };
  const nav = a.navigation;
  if (
    nav.points.length &&
    Math.hypot(nav.points[nav.index][0] - a.x, nav.points[nav.index][1] - a.z) <
      0.12
  ) {
    nav.index++;
    if (nav.index >= nav.points.length) {
      nav.points = [];
      nav.index = 0;
    }
  }
  let to = nav.points[nav.index] ?? goal,
    dx = to[0] - a.x,
    dz = to[1] - a.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, Math.max(0, dt) * speed),
    x = a.x + (dx / (d || 1)) * step,
    z = a.z + (dz / (d || 1)) * step;
  if (!swept(s, a, x, z, obstacles)) {
    a.action = "watch";
    a.status = "Aguardando passagem livre";
    if (s.time >= nav.nextPlan) {
      nav.nextPlan = s.time + 1;
      const planned = routeAround(s, a, goal, obstacles);
      if (planned.length) {
        nav.points = planned;
        nav.index = 0;
      }
    }
    return false;
  }
  a.x = x;
  a.z = z;
  a.heading = Math.atan2(dx, dz);
  a.moving = true;
  a.action = "walk";
  return false;
}
