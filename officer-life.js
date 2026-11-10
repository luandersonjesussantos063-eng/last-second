// Vida de plantão: tarefas humanas curtas, previsíveis e interrompíveis.
// Pontos ficam em áreas transitáveis da base. Simulação local, sem API.
import { rememberPoliceEvent } from "./police-ai.js?v=2.21.0";
export const REST_POINTS = {
  indoorWater: [37.8, 13.5],
  indoorRestroom: [42.0, 13.2],
  roadsideWater: [-9.0, -17.0],
  roadsideRestroom: [-9.0, -24.0],
};
export const LIFE_IDS = [0, 1, 5, 6, 7, 8, 16, 17];
const INSIDE = {
  0: [
    [30.8, 22],
    [30.8, 26.5],
    [39, 26.5],
    [39.5, 21.5],
    [38, 16],
  ],
  1: [
    [39.5, 21.5],
    [38, 16],
  ],
  7: [
    [15, -6],
    [18, 2],
    [26, 4],
    [32, 6],
    [35, 9],
    [35, 11.8],
    [37.5, 11.8],
  ],
  8: [
    [26, 4],
    [32, 6],
    [35, 9],
    [35, 11.8],
    [37.5, 11.8],
  ],
  16: [
    [25, -19],
    [28, -9],
    [32, 5],
    [35, 9],
    [35, 11.8],
    [37.5, 11.8],
  ],
  17: [
    [26, -21],
    [29, -9],
    [32, 5],
    [35, 9],
    [35, 11.8],
    [37.5, 11.8],
  ],
};
const OUTSIDE = {
  5: [
    [-8, -5],
    [-9.0, -10],
  ],
  6: [
    [-10.2, 16],
    [-10, 8],
    [-9.0, 0],
    [-9.0, -10],
  ],
};
const POST_ROUTES = {
  0: [
    [30.8, 22],
    [30.8, 26.5],
    [39, 26.5],
    [39.5, 21.5],
    [36, 21.2],
  ],
  1: [
    [39.3, 21.5],
    [36, 20.4],
    [34, 21.8],
  ],
  5: [
    [-9.1, -3],
    [-9.8, 3],
    [-9.3, 6],
  ],
  6: [
    [-10.5, 16],
    [-10, 9],
    [-9, 2],
    [-7.8, -2],
  ],
  7: [
    [12, -10],
    [15, -6],
    [18, 2],
  ],
  8: [
    [24, 4],
    [26, 4],
    [28, 0],
  ],
  16: [
    [23.5, -20],
    [27, -17],
    [27.3, -14],
  ],
  17: [
    [24, -21],
    [28, -17],
    [28.5, -13],
  ],
};
export const SWAP_PATHS = {
  7: [
    [15, -6],
    [16, -2],
    [18, 2],
    [21.5, 9],
  ],
  8: [
    [26, 4],
    [28, -5],
    [29, -12],
    [17, -16],
    [10.4, -12],
  ],
};
const PURPOSES = {
  0: ["water", "desk", "post", "restroom"],
  1: ["restroom", "desk", "water", "post"],
  5: ["post", "water", "restroom"],
  6: ["water", "post", "restroom"],
  7: ["water", "restroom", "post"],
  8: ["restroom", "water", "post"],
  16: ["water", "post", "restroom"],
  17: ["restroom", "water", "post"],
};
const LABELS = {
  desk: [
    "Revisando registros no computador",
    "Sentado revisando registros",
    "Levantando para retomar o posto",
  ],
  water: ["Indo ao bebedouro", "Bebendo água", "Voltando do bebedouro"],
  restroom: ["Indo ao banheiro", "No banheiro", "Voltando do banheiro"],
  post: [
    "Indo cobrir outro posto",
    "Cobrindo posto de serviço",
    "Retornando ao próprio posto",
  ],
  swap: [
    "Indo assumir o posto do colega",
    "No posto do colega",
    "Retornando após troca de posto",
  ],
};
const initial = {
  0: 55,
  1: 80,
  5: 72,
  6: 92,
  7: 136,
  8: 148,
  16: 155,
  17: 170,
};
const current = (a) => a.human?.phase !== "idle" && !!a.human;
const isDuty = (a) => a.task === "routine" && !a.embarked && a.visible;
const busyEvent = (s) =>
  ["pursuit", "detained"].includes(s.life.evasion.stage) ||
  ["enroute", "onScene"].includes(s.escort.backup.stage);
export function createHumanShift(agent) {
  return LIFE_IDS.includes(agent.id)
    ? {
        phase: "idle",
        purpose: null,
        started: 0,
        until: 0,
        nextAt: initial[agent.id],
        sequence: 0,
        counts: { water: 0, restroom: 0, post: 0, swap: 0, desk: 0 },
        blockedSince: 0,
        returnPath: [],
      }
    : null;
}
export function humanInProgress(agent) {
  return current(agent);
}
function unobstructedDuty(s, a) {
  if (
    !a.human ||
    current(a) ||
    !isDuty(a) ||
    a.path.length ||
    a.teamwork ||
    a.autonomy?.phase === "walk" ||
    a.autonomy?.phase === "meet" ||
    a.autonomy?.phase === "talk" ||
    s.command.conversation?.ids.includes(a.id) ||
    busyEvent(s)
  )
    return false;
  if ([0, 1].includes(a.id)) {
    const other = s.command.agents.find((p) => p.id === (a.id === 0 ? 1 : 0));
    if (!other || other.task !== "routine" || current(other)) return false;
    if (
      s.reception.visitors.some((v) =>
        ["queue", "called", "player", "serving"].includes(v.state),
      )
    )
      return false;
  }
  if ([5, 6].includes(a.id)) {
    if (s.checkpoint.phase !== "closed") return false;
    const other = s.command.agents.find((p) => p.id === (a.id === 5 ? 6 : 5));
    if (!other || other.task !== "routine" || current(other)) return false;
  }
  if ([7, 8].includes(a.id)) {
    const other = s.command.agents.find((p) => p.id === (a.id === 7 ? 8 : 7));
    if (current(other) && other.human.purpose !== "swap") return false;
    if (a.id === 8 && s.life.patrol.stage !== "parked") return false;
  }
  if ([16, 17].includes(a.id)) {
    if (s.life.bikes[a.id - 16].stage !== "ready") return false;
    const other = s.command.agents.find(
      (p) => p.id === (a.id === 16 ? 17 : 16),
    );
    if (current(other)) return false;
  }
  return true;
}
export function pathFor(a, purpose) {
  if (purpose === "desk") return [[a.home.x, a.home.z]];
  if (purpose === "post") return POST_ROUTES[a.id] ?? [[a.home.x, a.home.z]];
  const exterior = a.id === 5 || a.id === 6;
  const approach = (exterior ? OUTSIDE : INSIDE)[a.id] || [];
  if (purpose === "water")
    return [
      ...approach,
      exterior ? REST_POINTS.roadsideWater : REST_POINTS.indoorWater,
    ];
  if (exterior)
    return [
      ...approach,
      REST_POINTS.roadsideWater,
      REST_POINTS.roadsideRestroom,
    ];
  return [...approach, [37.8, 11.8], [40.5, 11.8], REST_POINTS.indoorRestroom];
}
function begin(s, a, purpose, path) {
  const h = a.human;
  h.phase = "going";
  h.purpose = purpose;
  h.started = s.time;
  h.blockedSince = 0;
  h.returnPath = [...path.slice(0, -1)].reverse().map((p) => [...p]);
  h.returnPath.push([a.home.x, a.home.z]);
  a.path = path.map((p) => [...p]);
  a.waypoint = 0;
  a.moving = false;
  a.status = LABELS[purpose][0];
  a.action = "walk";
  a.autonomy ??= { timer: 20, phase: "work" };
  a.autonomy.phase = "human";
  a.ai.decision = a.status;
}
export function maybeStartHumanShift(s, a) {
  if (!a.human || s.time < a.human.nextAt || !unobstructedDuty(s, a))
    return false;
  const choices = PURPOSES[a.id];
  const purpose = choices[a.human.sequence % choices.length];
  begin(s, a, purpose, pathFor(a, purpose));
  a.human.sequence++;
  return true;
}
export function maybeStartPostRotation(s) {
  const c = s.command;
  if (s.time < (c.nextPostSwapAt ?? 65) || c.conversation || busyEvent(s))
    return false;
  const pair = [7, 8].map((id) => c.agents.find((a) => a.id === id));
  if (
    pair.some(
      (a) =>
        !unobstructedDuty(s, a) ||
        Math.hypot(a.x - a.home.x, a.z - a.home.z) > 0.5,
    ) ||
    s.life.patrol.stage !== "parked"
  ) {
    c.nextPostSwapAt = s.time + 6;
    return false;
  }
  for (const a of pair) {
    begin(s, a, "swap", SWAP_PATHS[a.id]);
    a.human.sequence++;
  }
  c.nextPostSwapAt = s.time + 255;
  c.nextPatrolAt = Math.max(c.nextPatrolAt ?? 0, s.time + 90);
  return true;
}
export function cancelHumanShift(s, a) {
  if (!current(a)) return false;
  a.visible = true;
  a.human.phase = "idle";
  a.human.purpose = null;
  a.human.nextAt = s.time + 90 + (a.id % 7) * 6;
  a.human.returnPath = [];
  a.path = [];
  a.waypoint = 0;
  if (a.autonomy?.phase === "human") {
    a.autonomy.phase = "work";
    a.autonomy.timer = 22;
  }
  return true;
}
export function updateHumanShift(s, a, dt, arrived) {
  const h = a.human;
  if (!current(a)) return false;
  const phaseAtStep = h.phase;
  if (a.task !== "routine") {
    cancelHumanShift(s, a);
    return false;
  }
  if (
    busyEvent(s) ||
    ([5, 6].includes(a.id) && s.checkpoint.phase !== "closed")
  ) {
    if (h.phase !== "returning") {
      // Deslocar de volta sem teleportar, mesmo quando o plantão é interrompido.
      h.phase = "returning";
      a.path = h.returnPath.map((p) => [...p]);
      a.waypoint = 0;
    }
  }
  if (h.phase === "going" && arrived) {
    h.phase = "break";
    h.until =
      s.time +
      ({ water: 5, restroom: 8, post: 12, swap: 14, desk: 9 }[h.purpose] || 8);
    a.path = [];
    a.waypoint = 0;
  }
  if (h.phase === "break" && s.time >= h.until) {
    h.phase = "returning";
    a.visible = true;
    a.path = h.returnPath.map((p) => [...p]);
    a.waypoint = 0;
  }
  // A conclusão vale apenas para o caminho de retorno percorrido nesta atualização.
  // Sem isso, o "arrived" da pausa conclui o retorno antes de o agente andar.
  if (phaseAtStep === "returning" && h.phase === "returning" && arrived) {
    const done = h.purpose;
    h.counts[done]++;
    h.phase = "idle";
    h.purpose = null;
    h.returnPath = [];
    h.nextAt = s.time + 85 + ((a.id * 11 + h.sequence * 19) % 65);
    a.path = [];
    a.waypoint = 0;
    a.visible = true;
    a.action = "watch";
    a.status = "Retomando o posto de serviço";
    if (a.autonomy?.phase === "human") {
      a.autonomy.phase = "work";
      a.autonomy.timer = 18 + (a.id % 7);
    }
    rememberPoliceEvent(
      a,
      "activity",
      done + ":" + h.counts[done],
      {
        desk: "Revisou os registros do plantão",
        water: "Fez pausa para beber água",
        restroom: "Fez pausa no banheiro",
        post: "Cobriu outro setor",
        swap: "Trocou temporariamente de posto",
      }[done],
      s.time,
    );
    return true;
  }
  const state = h.phase;
  a.status =
    LABELS[h.purpose][state === "going" ? 0 : state === "break" ? 1 : 2];
  a.ai.decision = a.status;
  if (state === "break") {
    a.moving = false;
    a.action =
      h.purpose === "desk"
        ? "seated"
        : h.purpose === "water"
          ? "drink"
          : h.purpose === "restroom"
            ? "idle"
            : a.id === 7
              ? "radio"
              : "watch";
    a.visible = h.purpose !== "restroom"; // Banheiro privativo: NPC reaparece na mesma posição ao sair.
  } else {
    a.visible = true;
    if (a.moving) a.action = "walk";
  }
  // Evita ficar eternamente preso atrás de carro estacionado.
  if ((state === "going" || state === "returning") && !a.moving) {
    if (!h.blockedSince) h.blockedSince = s.time;
    if (s.time - h.blockedSince > 24) {
      // Retornar por etapas; nunca teletransportar nem ignorar ordem.
      if (state === "going") {
        h.phase = "returning";
        a.path = h.returnPath.map((p) => [...p]);
        a.waypoint = 0;
      } else {
        a.status = "Aguardando passagem livre para voltar ao posto";
      }
      h.blockedSince = s.time;
    }
  } else h.blockedSince = 0;
  return true;
}
