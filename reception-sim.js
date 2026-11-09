// Fictional reports, bounded queue and session-only records.
export const SERVICE_SEAT = { x: 28.3, z: 16 };
const stories = [
  [
    "Ana",
    "Perda de documentos",
    "Perdi minha carteira durante uma viagem pela rodovia.",
  ],
  [
    "Carlos",
    "Objeto na pista",
    "Há um pneu abandonado no acostamento próximo ao posto.",
  ],
  [
    "Marina",
    "Dano ao veículo",
    "Uma pedra atingiu o para-brisa durante a viagem.",
  ],
  [
    "João",
    "Pedido de orientação",
    "Preciso de orientação para seguir viagem com segurança.",
  ],
  [
    "Beatriz",
    "Animal na rodovia",
    "Vi um animal perto da pista no trecho anterior.",
  ],
  [
    "Pedro",
    "Direção perigosa",
    "Um motorista estava fazendo ultrapassagens perigosas.",
  ],
];
export function createReception() {
  return {
    seated: false,
    active: null,
    nextArrival: 0,
    sequence: 0,
    completed: 0,
    agentCompleted: 0,
    agentId: null,
    agentTime: 0,
    records: [],
    visitors: stories.map((_, id) => ({
      id,
      state: "away",
      x: 51,
      z: -10,
      heading: 0,
      moving: false,
      ticket: 0,
    })),
  };
}
export function nearComputer(s) {
  return (
    s.mode === "foot" && Math.hypot(s.player.x - 28.3, s.player.z - 16) < 2.3
  );
}
export function sitAtComputer(s) {
  if (s.paused || s.inspection || !nearComputer(s)) return false;
  const r = s.reception;
  if (r.seated) return false;
  r.seated = true;
  Object.assign(s.player, { x: 28.3, z: 16, yaw: -Math.PI / 2, moving: false });
  return true;
}
export function leaveComputer(s) {
  const r = s.reception;
  if (!r.seated) return false;
  if (r.active !== null) {
    r.visitors[r.active].state = "queue";
    r.active = null;
  }
  r.seated = false;
  Object.assign(s.player, { x: 28.3, z: 14, moving: false });
  return true;
}
export function callCitizen(s) {
  const r = s.reception;
  if (!r.seated || r.active !== null || s.paused) return false;
  const v = r.visitors
    .filter((v) => v.state === "queue")
    .sort((a, b) => a.ticket - b.ticket)[0];
  if (!v) return false;
  r.active = v.id;
  v.state = "called";
  return true;
}
export function currentReport(s) {
  const r = s.reception,
    v = r.visitors[r.active];
  if (!v || v.state !== "player") return null;
  const [name, type, description] = stories[v.id];
  return { name, type, description, ticket: v.ticket };
}
export function registerReport(s) {
  if (s.paused || !s.reception.seated) return false;
  const report = currentReport(s);
  if (!report) return false;
  const r = s.reception;
  r.records.unshift({
    ...report,
    number: ++r.completed,
    time: Math.floor(s.time),
  });
  r.records.length = Math.min(20, r.records.length);
  r.visitors[r.active].state = "exit";
  r.active = null;
  return true;
}
function move(v, x, z, dt) {
  const dx = x - v.x,
    dz = z - v.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, dt * 1.7);
  v.moving = d > 0.08;
  if (d > 0.01) {
    v.x += (dx / d) * step;
    v.z += (dz / d) * step;
    v.heading = Math.atan2(dx, dz);
  }
  return d < 0.12;
}
export function updateReception(s, dt) {
  const r = s.reception;
  r.nextArrival -= dt;
  if (r.nextArrival <= 0) {
    const v = r.visitors.find((v) => v.state === "away");
    if (v) {
      Object.assign(v, {
        state: "enter",
        x: 51,
        z: -10,
        ticket: ++r.sequence,
        waypoint: 0,
      });
      r.nextArrival = 9;
    }
  }
  const queue = r.visitors
    .filter((v) => v.state === "queue")
    .sort((a, b) => a.ticket - b.ticket);
  if (r.agentId === null && queue.length && (!r.seated || queue.length > 1)) {
    const v = queue[0];
    v.state = "agentWalk";
    r.agentId = v.id;
    r.agentTime = 0;
  }
  for (const v of r.visitors) {
    v.moving = false;
    if (v.state === "enter") {
      const route = [
          [35, 5],
          [35, 12],
          [35, 18],
        ],
        p = route[v.waypoint];
      if (move(v, ...p, dt) && ++v.waypoint === route.length) v.state = "queue";
    } else if (v.state === "queue")
      move(
        v,
        35 + (queue.indexOf(v) % 2) * 1.2,
        18 - Math.floor(queue.indexOf(v) / 2) * 1.4,
        dt,
      );
    else if (v.state === "called") {
      if (move(v, 31.7, 16, dt)) {
        v.state = "player";
        v.heading = -Math.PI / 2;
      }
    } else if (v.state === "agentWalk") {
      if (move(v, 32, 21, dt)) v.state = "agent";
    } else if (v.state === "agent") {
      r.agentTime += dt;
      if (r.agentTime > 18) {
        v.state = "exit";
        r.agentId = null;
        r.agentCompleted++;
      }
    } else if (v.state === "exit") {
      const target = v.z > 11.8 ? [35, 11.5] : v.z > 5.1 ? [35, 5] : [51, -10];
      if (move(v, ...target, dt) && target[0] === 51) v.state = "away";
    }
  }
}
