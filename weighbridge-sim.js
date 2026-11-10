import { FREIGHT_SPECS } from "./traffic-operations.js?v=2.22.0";
// Loads and references are fictional game values, not a legal enforcement database.
export const SCALE_SITE = { x: 65, z: -60 };
export const WEIGHBRIDGE_OBSTACLES = [{ x: 67.7, z: -55, hx: 0.95, hz: 0.75 }];
export function createWeighbridge() {
  return {
    x: SCALE_SITE.x,
    z: SCALE_SITE.z,
    kiosk: { x: 68.5, z: -52.5 },
    stage: "ready",
    grossKg: 51600,
    referenceKg: 48500,
    sequence: 0,
    completed: 0,
    report: null,
    history: [],
    elapsed: 0,
    readingKg: 0,
    waypoint: 0,
    signal: "red",
    retained: [],
    truck: {
      ...FREIGHT_SPECS.semi,
      freightType: "semi",
      kind: "truck",
      x: SCALE_SITE.x,
      z: SCALE_SITE.z,
      heading: Math.PI,
      speed: 0,
      visible: true,
      color: 0x2e7382,
      plate: "SIM-CARGA-2000",
    },
    nextAt: 0,
  };
}
const near = (s) =>
  s.mode === "foot" &&
  Math.hypot(s.player.x - s.weighbridge.x, s.player.z - s.weighbridge.z) < 9;
export function weighbridgeActionLabel(s) {
  if (s.paused || s.inspection || !near(s)) return "";
  return (
    {
      ready: "PESAR CAMINHÃO NA BALANÇA [F]",
      weighed: s.weighbridge.report?.differenceKg
        ? "REGISTRAR EXCESSO E RECOLHER AO PÁTIO [F]"
        : "REGISTRAR RESULTADO E LIBERAR [F]",
    }[s.weighbridge.stage] ?? ""
  );
}
export function interactWeighbridge(s) {
  const w = s.weighbridge;
  if (!weighbridgeActionLabel(s)) return false;
  if (w.stage === "ready") {
    if (
      Math.hypot(w.truck.x - w.x, w.truck.z - w.z) > 0.3 ||
      Math.abs(w.truck.speed) > 0.1
    )
      return false;
    w.stage = "weighing";
    w.elapsed = 0;
    w.readingKg = 0;
    w.signal = "red";
    s.notice = "BALANÇA: pesando veículo imóvel. Aguarde leitura por eixo.";
  } else if (w.stage === "weighed") {
    w.stage = "released";
    w.completed++;
    w.waypoint = 0;
    w.elapsed = 0;
    w.signal = "green";
    w.nextAt = s.time + 10;
    w.history.unshift({
      ...w.report,
      time: Math.round(s.time),
      disposition: w.report.differenceKg
        ? "Recolhido ao pátio"
        : "Liberado para circulação",
    });
    w.history.length = Math.min(12, w.history.length);
    s.notice =
      "PESAGEM REGISTRADA: " +
      w.report.plate +
      " · " +
      (w.report.differenceKg
        ? "excesso simulado: encaminhando ao pátio"
        : "liberado para circulação");
  } else return false;
  s.noticeUntil = s.time + 8;
  return true;
}
function move(s, c, point, dt) {
  const dx = point[0] - c.x,
    dz = point[1] - c.z,
    d = Math.hypot(dx, dz);
  if (d < 0.12) {
    c.speed = 0;
    return true;
  }
  const step = Math.min(d, 5.5 * dt),
    x = c.x + (dx / d) * step,
    z = c.z + (dz / d) * step;
  if (
    (s.mode === "foot" && Math.hypot(s.player.x - x, s.player.z - z) < 3) ||
    Math.hypot(s.car.x - x, s.car.z - z) < 4
  ) {
    c.speed = 0;
    return false;
  }
  c.x = x;
  c.z = z;
  c.heading = Math.atan2(dx, dz);
  c.speed = 5.5;
  c.wheelSpin = (c.wheelSpin ?? 0) + step / 0.52;
  return false;
}
export function updateWeighbridge(s, seconds) {
  if (s.paused || s.inspection) return;
  const w = s.weighbridge,
    dt = Math.max(0, Math.min(0.05, seconds));
  w.elapsed += dt;
  if (w.stage === "weighing") {
    if (
      Math.hypot(w.truck.x - w.x, w.truck.z - w.z) > 0.3 ||
      Math.abs(w.truck.speed) > 0.1
    ) {
      w.stage = "ready";
      w.readingKg = 0;
      return;
    }
    w.readingKg =
      Math.round((w.grossKg * Math.min(1, w.elapsed / 6)) / 10) * 10;
    if (w.elapsed >= 6) {
      const count = w.truck.axles,
        axleKg = Array.from(
          { length: count },
          () => Math.round(w.grossKg / count / 10) * 10,
        );
      axleKg[count - 1] += w.grossKg - axleKg.reduce((a, b) => a + b, 0);
      w.report = {
        grossKg: w.grossKg,
        tonnes: w.grossKg / 1000,
        referenceKg: w.referenceKg,
        differenceKg: Math.max(0, w.grossKg - w.referenceKg),
        plate: w.truck.plate,
        sequence: w.sequence + 1,
        axleKg,
        simulation: true,
        description:
          w.grossKg > w.referenceKg
            ? "Excesso comparado à referência fictícia desta balança"
            : "Massa dentro da referência fictícia do simulador",
      };
      w.stage = "weighed";
      w.readingKg = w.grossKg;
    }
  } else if (w.stage === "released") {
    const excessive = w.report.differenceKg > 0,
      route = excessive
        ? [
            [65, -108],
            [76, -120],
            [82, -105],
          ]
        : [
            [65, -130],
            [3.4, -140],
          ];
    if (
      move(s, w.truck, route[w.waypoint], dt) &&
      ++w.waypoint === route.length
    ) {
      if (excessive) {
        w.retained.unshift({
          ...w.truck,
          speed: 0,
          visible: true,
          heading: Math.PI,
        });
        w.retained.length = Math.min(3, w.retained.length);
        w.retained.forEach((c, i) => {
          c.x = 82 + i * 4;
          c.z = -95;
        });
      }
      w.truck.visible = false;
      w.stage = "waiting";
      w.elapsed = 0;
      w.signal = "red";
    }
  } else if (w.stage === "waiting" && w.elapsed > 5) {
    w.sequence++;
    const variant = ["semi", "boxTruck", "bitrem", "bus"][w.sequence % 4];
    Object.assign(w.truck, FREIGHT_SPECS[variant], {
      x: 65,
      z: 10,
      freightType: variant,
      speed: 0,
      heading: Math.PI,
      visible: true,
      plate: "SIM-CARGA-" + (2000 + w.sequence),
    });
    w.grossKg = w.sequence === 1 ? 40800 : FREIGHT_SPECS[variant].massKg;
    w.referenceKg = w.sequence === 1 ? 45000 : FREIGHT_SPECS[variant].limitKg;
    w.report = null;
    w.stage = "approach";
    w.waypoint = 0;
    w.elapsed = 0;
    w.signal = "green";
  } else if (w.stage === "approach") {
    if (move(s, w.truck, [[w.x, w.z]][0], dt)) {
      w.stage = "ready";
      w.elapsed = 0;
      w.signal = "red";
      w.readingKg = 0;
    }
  }
}
export function weighbridgeSummary(s) {
  const w = s.weighbridge,
    p = s.mode === "drive" ? s.car : s.player,
    dist = Math.round(Math.hypot(w.x - p.x, w.z - p.z));
  return {
    distance: dist,
    visible: dist < 240,
    stage: w.stage,
    weight: w.stage === "weighing" ? w.readingKg : w.grossKg,
    count: w.completed,
    report: w.report,
    signal: w.signal,
  };
}
