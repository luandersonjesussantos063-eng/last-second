// Authored fictional streets, service locations and a bounded commuter simulation.
export const TOWNS = [
  { id: "serra", name: "Vila da Serra", x: 165, z: -500, color: 0xd8bf98 },
  { id: "vale", name: "Santa Aurora", x: 165, z: 500, color: 0xacc9c1 },
];
export const URBAN_FACILITIES = TOWNS.flatMap((t) => [
  {
    id: t.id + "-fuel",
    type: "fuel",
    name: "Posto " + t.name,
    x: 124,
    z: t.z - 25,
    radius: 10,
  },
  {
    id: t.id + "-garage",
    type: "workshop",
    name: "Oficina " + t.name,
    x: 188,
    z: t.z + 25,
    radius: 10,
  },
  {
    id: t.id + "-centre",
    type: "town",
    name: t.name,
    x: 165,
    z: t.z,
    radius: 12,
  },
]);
export const URBAN_BUILDINGS = TOWNS.flatMap((t) => [
  {
    x: 130,
    z: t.z + 29,
    hx: 20,
    hz: 12,
    height: 7,
    title: "MERCADO · FARMÁCIA",
    color: t.color,
  },
  {
    x: 197,
    z: t.z - 28,
    hx: 20,
    hz: 13,
    height: 9,
    title: "COMÉRCIO · CAFÉ",
    color: t.color,
  },
  {
    x: 211,
    z: t.z + 29,
    hx: 12,
    hz: 13,
    height: 5,
    title: "OFICINA · AUTO CENTER",
    color: 0xc7b5a0,
  },
  {
    x: 145,
    z: t.z - 36,
    hx: 8,
    hz: 6,
    height: 3.5,
    title: "CONVENIÊNCIA",
    color: 0xd5d7cd,
  },
  {
    x: 253,
    z: t.z - 29,
    hx: 9,
    hz: 14,
    height: 6,
    title: "BAIRRO RESIDENCIAL",
    color: 0xb8c0ae,
  },
]);
export const URBAN_OBSTACLES = [
  ...URBAN_BUILDINGS.map(({ x, z, hx, hz }) => ({ x, z, hx, hz })),
  ...TOWNS.flatMap((t) =>
    [119, 129].map((x) => ({ x, z: t.z - 25, hx: 1.05, hz: 3.5 })),
  ),
];
const rect = (x, z, cx, cz, hx, hz) =>
  Math.abs(x - cx) <= hx && Math.abs(z - cz) <= hz;
export function urbanDriveableArea(x, z) {
  return TOWNS.some(
    (t) =>
      rect(x, z, 116, t.z, 122, 7.5) ||
      [100, 165, 230].some((sx) => rect(x, z, sx, t.z, 7.5, 58)) ||
      [t.z - 50, t.z + 50].some((sz) => rect(x, z, 165, sz, 73, 7.5)) ||
      rect(x, z, 130, t.z - 25, 25, 16) ||
      rect(x, z, 124, t.z - 12, 7, 16) ||
      rect(x, z, 185, t.z + 25, 21, 12) ||
      rect(x, z, 165, t.z + 13, 7, 18),
  );
}
export const driveableArea = urbanDriveableArea;
export function urbanWalkableArea(x, z) {
  return TOWNS.some(
    (t) => rect(x, z, 116, t.z, 126, 13) || rect(x, z, 177, t.z, 94, 64),
  );
}
export function highwayUrbanExit(z) {
  return TOWNS.some((t) => Math.abs(z - t.z) < 12);
}
export function nearestFacility(point, type) {
  const p = point.car ?? point;
  return (
    URBAN_FACILITIES.filter((f) => !type || f.type === type)
      .map((f) => ({ ...f, distance: Math.hypot(p.x - f.x, p.z - f.z) }))
      .sort((a, b) => a.distance - b.distance)[0] ?? null
  );
}
export function signalPhase(time, offset = 0) {
  const p = (((time + offset) % 32) + 32) % 32;
  return p < 13
    ? "eastWest"
    : p < 16
      ? "clear"
      : p < 29
        ? "northSouth"
        : "clear";
}
const nodes = [],
  edges = [];
function node(x, z) {
  let n = nodes.find((n) => n.x === x && n.z === z);
  if (!n) {
    n = { x, z, id: nodes.length };
    nodes.push(n);
    edges.push([]);
  }
  return n.id;
}
function link(a, b) {
  if (!edges[a].includes(b)) {
    edges[a].push(b);
    edges[b].push(a);
  }
}
function chain(points) {
  const ids = points.map(([x, z]) => node(x, z));
  for (let i = 1; i < ids.length; i++) link(ids[i - 1], ids[i]);
}
chain(
  [-1490, -565, -550, -520, -500, -490, -450, 0, 450, 500, 550, 1490].map(
    (z) => [0, z],
  ),
);
chain([
  [20, -8],
  [20, 0],
  [0, 0],
]);
for (const t of TOWNS) {
  for (const z of [t.z - 50, t.z, t.z + 50])
    chain([[0, z], ...[100, 124, 165, 188, 230].map((x) => [x, z])]);
  for (const x of [100, 165, 230])
    chain([t.z - 50, t.z, t.z + 50].map((z) => [x, z]));
  chain([
    [124, t.z],
    [124, t.z - 25],
  ]);
  chain([
    [165, t.z],
    [165, t.z + 25],
    [188, t.z + 25],
  ]);
}
chain([
  [0, -490],
  [-7, -490],
  [-7, -514],
  [-4.8, -514],
]);
chain([
  [0, -490],
  [-26, -490],
  [-26, -560],
  [-26, -565],
  [0, -565],
]);
function clearSegment(a, b) {
  return !URBAN_OBSTACLES.some((o) => {
    let lo = 0,
      hi = 1;
    for (const [v, d, min, max] of [
      [a.x, b.x - a.x, o.x - o.hx - 0.35, o.x + o.hx + 0.35],
      [a.z, b.z - a.z, o.z - o.hz - 0.35, o.z + o.hz + 0.35],
    ]) {
      if (Math.abs(d) < 1e-9) {
        if (v < min || v > max) return false;
      } else {
        const t1 = (min - v) / d,
          t2 = (max - v) / d;
        lo = Math.max(lo, Math.min(t1, t2));
        hi = Math.min(hi, Math.max(t1, t2));
        if (lo > hi) return false;
      }
    }
    return true;
  });
}
function nearestNode(p) {
  return (
    nodes
      .filter((n) => clearSegment(p, n))
      .sort(
        (a, b) =>
          Math.hypot(a.x - p.x, a.z - p.z) - Math.hypot(b.x - p.x, b.z - p.z),
      )[0] ?? nodes[0]
  );
}
export function navigationRoute(origin, destination) {
  const from = nearestNode(origin),
    to = nearestNode(destination),
    dist = nodes.map(() => Infinity),
    prev = nodes.map(() => -1),
    open = new Set(nodes.map((n) => n.id));
  dist[from.id] = 0;
  while (open.size) {
    let u = -1;
    for (const i of open) if (u < 0 || dist[i] < dist[u]) u = i;
    if (u === to.id || dist[u] === Infinity) break;
    open.delete(u);
    for (const v of edges[u]) {
      const d =
        dist[u] + Math.hypot(nodes[u].x - nodes[v].x, nodes[u].z - nodes[v].z);
      if (d < dist[v]) {
        dist[v] = d;
        prev[v] = u;
      }
    }
  }
  const route = [];
  for (let i = to.id; i >= 0; i = prev[i]) {
    route.unshift({ x: nodes[i].x, z: nodes[i].z });
    if (i === from.id) break;
  }
  return [
    { x: origin.x, z: origin.z },
    ...route,
    { x: destination.x, z: destination.z },
  ].filter(
    (p, i, a) => !i || Math.hypot(p.x - a[i - 1].x, p.z - a[i - 1].z) > 0.01,
  );
}
export function routeDistance(route) {
  return route
    .slice(1)
    .reduce((n, p, i) => n + Math.hypot(p.x - route[i].x, p.z - route[i].z), 0);
}
const loop = (t) => [
  [103, t.z - 53],
  [227, t.z - 53],
  [227, t.z + 53],
  [103, t.z + 53],
];
export function createUrbanState() {
  return {
    cars: TOWNS.flatMap((t, ti) =>
      [0, 1].map((i) => ({
        id: 300 + ti * 2 + i,
        town: ti,
        waypoint: i * 2,
        x: loop(t)[i * 2][0],
        z: loop(t)[i * 2][1],
        heading: i ? Math.PI : 0,
        speed: 0,
        wheelSpin: 0,
        color: [0x846c58, 0x718da0][i],
        kind: i ? "hatchback" : "sedan",
        visible: true,
      })),
    ),
    pedestrians: TOWNS.flatMap((t, ti) =>
      Array.from({ length: 4 }, (_, i) => ({
        id: ti * 4 + i,
        town: ti,
        waypoint: i,
        x: [94, 236, 236, 94][i],
        z: t.z + [-61, -61, 61, 61][i],
        heading: 0,
        moving: false,
        phase: 0,
      })),
    ),
  };
}
function move(o, p, speed, dt) {
  const dx = p[0] - o.x,
    dz = p[1] - o.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, speed * dt);
  if (d < 0.1) return true;
  o.x += (dx / d) * step;
  o.z += (dz / d) * step;
  o.heading = Math.atan2(dx, dz);
  return d <= step + 0.1;
}
export function updateUrbanState(s, dt) {
  if (!s.urban || s.paused || s.inspection) return;
  dt = Math.max(0, Math.min(0.05, dt));
  for (const c of s.urban.cars) {
    const t = TOWNS[c.town],
      path = loop(t),
      target = path[c.waypoint];
    let speed = 7;
    const horizontal = Math.abs(target[0] - c.x) > Math.abs(target[1] - c.z),
      signal = signalPhase(s.time, c.town * 4);
    // Stop before a crossing, but allow an already-entered intersection to clear.
    const crossing = horizontal ? [165, target[1]] : [target[0], t.z],
      distance = Math.hypot(c.x - crossing[0], c.z - crossing[1]);
    if (
      distance > 6 &&
      distance < 17 &&
      signal !== (horizontal ? "eastWest" : "northSouth")
    )
      speed = 0;
    if (
      (s.mode === "foot" &&
        Math.hypot(c.x - s.player.x, c.z - s.player.z) < 8) ||
      Math.hypot(c.x - s.car.x, c.z - s.car.z) < 9
    )
      speed = 0;
    if (
      s.urban.cars.some(
        (other) => other !== c && Math.hypot(other.x - c.x, other.z - c.z) < 7,
      )
    )
      speed = 0;
    c.speed = speed;
    c.wheelSpin += (speed * dt) / 0.4;
    if (move(c, target, speed, dt)) c.waypoint = (c.waypoint + 1) % path.length;
  }
  for (const p of s.urban.pedestrians) {
    const t = TOWNS[p.town],
      path = [
        [94, t.z - 61],
        [236, t.z - 61],
        [236, t.z + 61],
        [94, t.z + 61],
      ],
      target = path[p.waypoint];
    const observer = s.mode === "drive" ? s.car : s.player;
    const speed = Math.hypot(p.x - observer.x, p.z - observer.z) < 2 ? 0 : 1.25;
    p.moving = speed > 0;
    p.phase += dt * speed * 7;
    if (move(p, target, speed, dt)) p.waypoint = (p.waypoint + 1) % path.length;
  }
}
