import { CHECKPOINT as P } from "./base-layout.js?v=2.2.0";
const smooth = (v) => {
  v = Math.max(0, Math.min(1, v));
  return v * v * (3 - 2 * v);
};
export function createCheckpoint() {
  return {
    stage: "waiting",
    vehicleId: null,
    elapsed: 0,
    completed: 0,
    status: "FISCALIZAÇÃO EM OPERAÇÃO",
    blocked: false,
    driverVisible: false,
    driverX: -11,
    driverZ: 18,
  };
}
export function checkpointControlled(s, t) {
  return (
    s.checkpoint?.vehicleId === t.id &&
    ["signal", "directing", "checking", "release", "merging"].includes(
      s.checkpoint.stage,
    )
  );
}
export function checkpointSpeed(s, t, desired) {
  if (t.direction === 1 && t.z > -75 && t.z < 40)
    desired = Math.min(desired, 8);
  if (s.checkpoint?.vehicleId === t.id && s.checkpoint.stage === "approach")
    desired = Math.min(desired, Math.max(0, (P.stopZ - t.z) * 0.7));
  return desired;
}
function pathClear(s, x, z) {
  if (s.mode === "foot" && Math.hypot(s.player.x - x, s.player.z - z) < 3.2)
    return false;
  if (Math.hypot(s.car.x - x, s.car.z - z) < 4.5) return false;
  return !s.traffic.some(
    (t) =>
      t.id !== s.checkpoint.vehicleId &&
      Math.abs(t.x - x) < 2.2 &&
      Math.abs(t.z - z) < 5,
  );
}
function transition(c, stage) {
  c.stage = stage;
  c.elapsed = 0;
  c.blocked = false;
}
export function updateCheckpoint(s, dt) {
  const c = s.checkpoint;
  if (!c) return;
  c.elapsed += dt;
  c.blocked = false;
  if (c.stage === "waiting") {
    c.status = "EQUIPE A POSTOS • TRÂNSITO LENTO";
    const next = s.traffic
      .filter(
        (t) =>
          t.direction === 1 &&
          t.id !== s.mission.targetId &&
          t.z > -80 &&
          t.z < -10 &&
          !t.stopped,
      )
      .sort((a, b) => b.z - a.z)[0];
    if (next) {
      c.vehicleId = next.id;
      transition(c, "approach");
    }
    return;
  }
  if (c.stage === "cooldown") {
    c.status = "VEÍCULO LIBERADO • PRÓXIMA FISCALIZAÇÃO";
    if (c.elapsed > 4) transition(c, "waiting");
    return;
  }
  const t = s.traffic.find((v) => v.id === c.vehicleId);
  if (!t || t.id === s.mission.targetId) {
    if (t) t.stopped = false;
    c.vehicleId = null;
    c.driverVisible = false;
    transition(c, "waiting");
    return;
  }
  if (c.stage === "approach") {
    c.status = `${t.plate} • AGENTE SINALIZANDO`;
    if (t.z > P.stopZ - 1.3) {
      t.speed = 0;
      c.from = { x: t.x, z: t.z };
      transition(c, "signal");
    }
  } else if (c.stage === "signal") {
    t.speed = 0;
    c.status = "ORIENTANDO PARA O ACOSTAMENTO";
    if (c.elapsed > 1.2) transition(c, "directing");
  } else if (c.stage === "directing" || c.stage === "merging") {
    const entering = c.stage === "directing",
      duration = entering ? 4.5 : 5.5,
      p = smooth(c.elapsed / duration);
    const from = entering ? c.from : { x: P.bayX, z: P.bayZ };
    const x = from.x + ((entering ? P.bayX : -3.4) - from.x) * p,
      z = from.z + ((entering ? P.bayZ : P.releaseZ) - from.z) * p;
    if (!pathClear(s, x, z)) {
      c.elapsed = Math.max(0, c.elapsed - dt);
      c.blocked = true;
      t.speed = 0;
      c.status = "AGUARDANDO ÁREA LIVRE";
      return;
    }
    t.x = x;
    t.z = z;
    t.speed = entering ? 4 : 6;
    c.status = entering
      ? "CONDUTOR ENCAMINHADO À BAIA"
      : "RETORNO SEGURO À FAIXA";
    if (p === 1) {
      if (entering) {
        t.speed = 0;
        t.stopped = true;
        c.driverVisible = true;
        c.driverX = -11;
        c.driverZ = P.bayZ;
        transition(c, "checking");
      } else {
        t.stopped = false;
        t.speed = 8;
        c.completed++;
        c.vehicleId = null;
        transition(c, "cooldown");
      }
    }
  } else if (c.stage === "checking") {
    t.speed = 0;
    c.status = `CONFERINDO DOCUMENTOS • ${t.plate}`;
    if (c.elapsed > 10) transition(c, "release");
  } else if (c.stage === "release") {
    t.speed = 0;
    c.status = "DOCUMENTOS REGULARES • LIBERAÇÃO";
    const p = smooth(c.elapsed / 3);
    c.driverX = -11 + 1.3 * p;
    if (p === 1) {
      c.driverVisible = false;
      const gap = s.traffic.every(
        (v) =>
          v.id === t.id || Math.abs(v.x + 3.4) > 2.2 || Math.abs(v.z - 32) > 20,
      );
      if (gap) transition(c, "merging");
      else c.status = "AGUARDANDO INTERVALO NO TRÂNSITO";
    }
  } else if (c.stage === "cooldown") {
    c.status = "VEÍCULO LIBERADO • PRÓXIMA FISCALIZAÇÃO";
    if (c.elapsed > 4) transition(c, "waiting");
  }
}
