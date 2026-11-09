import {
  scheduleCrewRoutine,
  updateCrewRoutineClock,
  crewRoutineStatus,
  beginCrewConversation,
  advanceCrewConversation,
  cancelCrewConversation,
  isCrewTalking,
} from "./autonomous-crew.js?v=2.8.0";
import {createPoliceMind, observePoliceWorld, applyPoliceDecision} from "./police-ai.js?v=2.8.0";
// Authoritative, bounded crew state; the same positions drive rendering and orders.
export const AGENT_DEFINITIONS = [
  { id: 0, name: "Almeida", role: "Recepção", x: 32, z: 22, heading: 0 },
  { id: 1, name: "Costa", role: "Operações", x: 38, z: 22, heading: 0 },
  {
    id: 5,
    name: "Silva",
    role: "Sinalização da blitz",
    x: -5.7,
    z: -4,
    heading: Math.PI,
  },
  {
    id: 6,
    name: "Souza",
    role: "Documentação da blitz",
    x: -10.7,
    z: 19.8,
    heading: Math.PI,
  },
  {
    id: 7,
    name: "Lima",
    role: "Comunicações",
    x: 10.4,
    z: -12,
    heading: -Math.PI / 2,
  },
  {
    id: 8,
    name: "Rocha",
    role: "Patrulhamento e segurança",
    x: 21.5,
    z: 9,
    heading: Math.PI / 2,
  },
  {
    id: 16,
    name: "Santos",
    role: "Motopatrulha 1",
    x: 18,
    z: -21.5,
    heading: Math.PI,
  },
  {
    id: 17,
    name: "Oliveira",
    role: "Motopatrulha 2",
    x: 20.1,
    z: -21.5,
    heading: Math.PI,
  },
  { id: 18, name: "Ferreira", role: "Equipe da viatura", x: 16.5, z: -5, heading: Math.PI },
  { id: 19, name: "Mendes", role: "Equipe da viatura", x: 16.3, z: -11.5, heading: Math.PI },
  { id: 20, name: "Nogueira", role: "Equipe da viatura", x: 23.4, z: -12, heading: Math.PI },
  { id: 21, name: "Barros", role: "Reforço", x: 0, z: -500, heading: 0 },
  { id: 22, name: "Teixeira", role: "Reforço", x: 0, z: -500, heading: 0 },
];
export const ORDERS = {
  blitz: { label: "Intensificar fiscalização", ids: [5, 6] },
  report: {
    label: "Informar situação pelo rádio",
    ids: AGENT_DEFINITIONS.filter((a) => a.id < 18).map((a) => a.id),
  },
  reception: { label: "Reforçar atendimento ao público", ids: [0, 1] },
  patrol: { label: "Sair em patrulha com a viatura", ids: [8] },
  perimeter: { label: "Inspecionar perímetro da base", ids: [8] },
  ready: { label: "Manter prontidão para evasões", ids: [16, 17] },
  return: {
    label: "Retomar função de origem",
    ids: AGENT_DEFINITIONS.filter((a) => a.id < 18).map((a) => a.id),
  },
};
export const COMMAND_MISSIONS = [
  {
    title: "Coordenar a operação de blitz",
    brief:
      "Ordene a Silva e Souza que intensifiquem a fiscalização. Acompanhe uma liberação segura.",
    objectives: [
      "Silva: intensificar fiscalização",
      "Souza: intensificar fiscalização",
      "Uma fiscalização concluída pela equipe",
    ],
  },
  {
    title: "Despachar patrulha rodoviária",
    brief:
      "Envie Rocha com a viatura e peça a Lima um informe. A missão termina quando a patrulha sai para o trecho.",
    objectives: [
      "Rocha: sair em patrulha",
      "Lima: informar situação",
      "Viatura em patrulhamento externo",
    ],
  },
  {
    title: "Organizar atendimento da unidade",
    brief:
      "Envie Costa para apoiar Almeida na recepção e acompanhe a resolução de uma ocorrência.",
    objectives: [
      "Costa: reforçar atendimento",
      "Uma ocorrência atendida pela recepção",
    ],
  },
  {
    title: "Garantir segurança da base",
    brief:
      "Ordene uma inspeção do perímetro a Rocha e confirme a prontidão de Santos e Oliveira.",
    objectives: [
      "Rocha: concluir inspeção do perímetro",
      "Santos: confirmar prontidão",
      "Oliveira: confirmar prontidão",
    ],
  },
];
export function createCommand() {
  return {
    agents: AGENT_DEFINITIONS.map((a) => ({
      ...a,
      home: { x: a.x, z: a.z },
      action: "idle",
      visible: true,
      moving: false,
      task: "routine",
      status: "Em serviço",
      path: [],
      waypoint: 0,
      elapsed: 0,
      cycles: 0,
      completed: {},
      assignment: 0,
      ai: createPoliceMind(a),
    })),
    log: [],
    serial: 0,
    completed: 0,
    view: "command",
    mission: { index: 0, stage: "briefing", checks: [] },
  };
}
export function agentById(s, id) {
  return s.command.agents.find((a) => a.id === Number(id));
}
function log(s, text) {
  const c = s.command;
  c.log.unshift({
    id: ++c.serial,
    day: s.clock.day,
    minute: Math.floor(s.clock.minute),
    text,
  });
  c.log.length = Math.min(c.log.length, 12);
}
export function nearestAgent(s, radius = 3) {
  if (s.mode !== "foot" || s.reception.seated) return null;
  return (
    s.command.agents
      .filter(
        (a) =>
          a.visible && Math.hypot(a.x - s.player.x, a.z - s.player.z) < radius,
      )
      .sort(
        (a, b) =>
          Math.hypot(a.x - s.player.x, a.z - s.player.z) -
          Math.hypot(b.x - s.player.x, b.z - s.player.z),
      )[0] ?? null
  );
}
export function agentBusy(s, a) {
  return (
    ([16, 17].includes(a.id) && s.life.bikes[a.id - 16].stage !== "ready") ||
    (a.id >= 18 && (a.task === "escort" || a.task === "backup")) ||
    (a.task === "patrol" && a.embarked)
  );
}
export function orderAvailable(s, a, type) {
  if (!a || !ORDERS[type]?.ids.includes(a.id)) return false;
  if (agentBusy(s, a))
    return (
      type === "report" ||
      (type === "return" && a.id === 8 && s.life.patrol.stage === "away")
    );
  if (type === "patrol" && s.life.patrol.stage !== "parked") return false;
  return true;
}
export function issueOrder(s, id, type, channel = "radio") {
  const a = agentById(s, id);
  if (s.paused || s.inspection || !orderAvailable(s, a, type)) return false;
  if (
    channel === "near" &&
    (s.mode !== "foot" ||
      !a.visible ||
      Math.hypot(a.x - s.player.x, a.z - s.player.z) > 3.2)
  )
    return false;
  cancelCrewConversation(s, a.id);
  if (channel === "radio") s.player.radioUntil = s.time + 6;
  if (agentBusy(s, a)) {
    if (type === "report") log(s, `${a.name} · ${a.status}. Mantendo serviço.`);
    else {
      Object.assign(s.life.patrol, {
        stage: "returning",
        waypoint: 0,
        elapsed: 0,
        x: -3.4,
        z: -520,
      });
      log(
        s,
        `${a.name} · Recebido, comando. Retornando à unidade com a viatura.`,
      );
    }
    return true;
  }
  a.task = type;
  a.elapsed = 0;
  a.waypoint = 0;
  a.path =
    type === "reception" && a.id === 1
      ? [
          [36, 22],
          [34, 22],
        ]
      : type === "patrol"
        ? [...homeRoute(a), [22, 17], [19, 24], [19, 29]]
        : type === "perimeter"
          ? perimeterRoute()
          : type === "return"
            ? homeRoute(a)
            : [];
  a.assignment++;
  a.embarked = false;
  a.status = a.path.length
    ? "Deslocando-se: " + ORDERS[type].label.toLowerCase()
    : ORDERS[type].label;
  log(
    s,
    `${channel === "near" ? "Presencial" : "Rádio"} · ${a.name}: recebido, comando. ${ORDERS[type].label}.`,
  );
  const m = s.command.mission;
  if (m.stage === "active") {
    m.orders[`${a.id}:${type}`] = true;
    if (type === "blitz" && m.orders["5:blitz"] && m.orders["6:blitz"])
      m.checkpointAfter = s.checkpoint.completed;
  }
  return true;
}
function perimeterRoute() {
  // Inspection route outside walls and parked cars.
  return [
    [24, 4],
    [35, 2],
    [47, 2],
    [47, 32],
    [24, 34],
    [22, 17],
    [21.5, 9],
  ];
}
function homeRoute(a) {
  if (a.id === 1)
    return [
      [36, 22],
      [38, 22],
    ];
  if (a.id === 8)
    return a.x > 44
      ? [
          [47, 32],
          [24, 34],
          [22, 17],
          [21.5, 9],
        ]
      : a.z > 30
        ? [
            [24, 34],
            [22, 17],
            [21.5, 9],
          ]
        : a.z < 5
          ? [
              [24, 4],
              [21.5, 9],
            ]
          : [[21.5, 9]];
  return [[a.home.x, a.home.z]];
}
function moveAgent(s, a, dt) {
  const p = a.path[a.waypoint];
  if (!p) return true;
  const dx = p[0] - a.x,
    dz = p[1] - a.z,
    distance = Math.hypot(dx, dz);
  if (distance < 0.12) {
    a.waypoint++;
    return a.waypoint === a.path.length;
  }
  // Agents yield to the commander and live cars; no wandering or teleporting.
  const step = Math.min(distance, dt * 1.55),
    x = a.x + (dx / distance) * step,
    z = a.z + (dz / distance) * step;
  if (
    (s.mode === "foot" && Math.hypot(s.player.x - x, s.player.z - z) < 0.8) ||
    [
      s.car,
      ...s.traffic,
      ...s.reception.visitors.filter((v) => v.car.visible).map((v) => v.car),
    ].some((c) => Math.hypot(c.x - x, c.z - z) < 2.1)
  ) {
    a.status = "Aguardando passagem livre";
    return false;
  }
  a.x = x;
  a.z = z;
  a.heading = Math.atan2(dx, dz);
  a.moving = true;
  a.action = "walk";
  return false;
}
function finishTask(s, a, type, text) {
  a.completed[type] = (a.completed[type] ?? 0) + 1;
  log(s, `${a.name} · ${text}`);
}
export function startCommandMission(s) {
  const c = s.command,
    m = c.mission;
  if (s.paused || s.inspection || m.stage === "active") return false;
  if (m.stage === "complete") m.index = (m.index + 1) % COMMAND_MISSIONS.length;
  Object.assign(m, {
    patrolAway: false,
    checkpointAfter: undefined,
    receptionAfter: undefined,
    stage: "active",
    orders: {},
    baseline: {
      checkpoint: s.checkpoint.completed,
      reception: s.reception.agentCompleted,
      perimeter: agentById(s, 8).completed.perimeter ?? 0,
      ready16: agentById(s, 16).completed.ready ?? 0,
      ready17: agentById(s, 17).completed.ready ?? 0,
      report: agentById(s, 7).completed.report ?? 0,
    },
    checks: [],
  });
  log(s, "Comando · Missão iniciada: " + COMMAND_MISSIONS[m.index].title);
  return true;
}
export function missionProgress(s) {
  const m = s.command.mission;
  if (m.stage === "briefing")
    return COMMAND_MISSIONS[m.index].objectives.map(() => false);
  const o = m.orders,
    b = m.baseline,
    a = (id) => agentById(s, id);
  return [
    [
      !!o["5:blitz"],
      !!o["6:blitz"],
      m.checkpointAfter !== undefined &&
        s.checkpoint.completed > m.checkpointAfter,
    ],
    [
      !!o["8:patrol"],
      !!o["7:report"] && (a(7).completed.report ?? 0) > b.report,
      !!o["8:patrol"] && !!m.patrolAway,
    ],
    [
      !!o["1:reception"],
      m.receptionAfter !== undefined &&
        s.reception.agentCompleted > m.receptionAfter,
    ],
    [
      !!o["8:perimeter"] && (a(8).completed.perimeter ?? 0) > b.perimeter,
      !!o["16:ready"] && (a(16).completed.ready ?? 0) > b.ready16,
      !!o["17:ready"] && (a(17).completed.ready ?? 0) > b.ready17,
    ],
  ][m.index];
}
export function updateCommand(s, dt) {
  const c = s.command;
  observePoliceWorld(s);
  if (["pursuit", "detained"].includes(s.life.evasion.stage))
    cancelCrewConversation(s);
  if (beginCrewConversation(s)) {
    const pair = c.conversation.ids.map(id => agentById(s, id).name);
    log(s, pair.join(" e ") + " · Iniciando conversa de rotina.");
  }
  for (const a of c.agents) {
    a.moving = false;
    a.visible = true;
    a.elapsed += dt;
    if (a.id >= 18) continue; // The escort and backup run in escort-sim.
    updateCrewRoutineClock(a, dt);
    if (a.id === 16 || a.id === 17) {
      const bike = s.life.bikes[a.id - 16];
      if (bike.stage !== "ready") {
        a.x = bike.x;
        a.z = bike.z;
        a.heading = bike.heading;
        a.action = "riding";
        a.status =
          "Motopatrulha: " +
          (bike.stage === "pursuit"
            ? "interceptando evasão"
            : "retornando à base");
        continue;
      }
      a.x = a.home.x;
      a.z = a.home.z;
    }
    if (a.task === "patrol" && a.embarked) {
      const p = s.life.patrol;
      a.x = p.x;
      a.z = p.z;
      a.visible = false;
      a.status =
        "Patrulha: " +
        {
          depart: "saindo da base",
          away: "no trecho",
          returning: "retornando",
          parked: "na base",
        }[p.stage];
      if (
        p.stage === "away" &&
        c.mission.stage === "active" &&
        c.mission.orders["8:patrol"]
      )
        c.mission.patrolAway = true;
      if (p.stage === "parked") {
        a.visible = true;
        a.x = 21;
        a.z = 29;
        a.embarked = false;
        a.task = "return";
        a.path = homeRoute(a);
        a.waypoint = 0;
        finishTask(s, a, "patrol", "Patrulha concluída. Retornando ao posto.");
      }
      continue;
    }
    const workingBlitz = (a.id === 5 || a.id === 6) &&
      a.task === "routine" && ["setup", "teardown"].includes(s.checkpoint.phase);
    if (workingBlitz) {
      const phaseKey = s.clock.day + ":" + s.checkpoint.phase;
      if (a.equipmentPhase !== phaseKey) {
        a.equipmentPhase = phaseKey;
        a.path = a.id === 5
          ? [[-5.4, -7.2], [-5.2, -9.4], [-5.7, -4]]
          : [[-10.7, 16], [-10.7, 13], [-10.7, 19.8]];
        a.waypoint = 0;
      }
      a.status = s.checkpoint.phase === "setup"
        ? "Montando cones e sinalização" : "Recolhendo equipamento da blitz";
    } else {
      scheduleCrewRoutine(s, a);
    }
    const arrived = moveAgent(s, a, dt);
    if (!arrived) continue;
    if (workingBlitz) {
      a.path = [];
      a.waypoint = 0;
      a.action = a.id === 5 ? "signal" : "documents";
      a.status = s.checkpoint.phase === "setup"
        ? "Conferindo montagem da blitz" : "Finalizando retirada dos cones";
      continue;
    }
    if (isCrewTalking(s, a.id)) {
      // Uma conversa agenda deslocamento; ao chegar, o agente aguarda o colega.
      if (c.conversation.phase === "approach") {
        a.path = [];
        a.waypoint = 0;
        a.action = "watch";
        a.status = "Aguardando colega para conversar";
      }
      continue;
    }
    if (a.autonomy?.phase === "walk" && a.task === "routine") {
      a.path = [];
      a.waypoint = 0;
      a.autonomy.phase = "work";
      a.autonomy.timer = 19 + ((a.id * 13 + a.cycles * 7) % 19);
      a.cycles++;
    }
    if (a.task === "patrol") {
      Object.assign(s.life.patrol, {
        stage: "depart",
        waypoint: 0,
        elapsed: 0,
        lights: true,
      });
      s.life.departures++;
      a.embarked = true;
      a.visible = false;
      log(s, a.name + " · Embarcado, iniciando patrulha rodoviária.");
      continue;
    }
    if (a.task === "perimeter") {
      finishTask(
        s,
        a,
        "perimeter",
        "Perímetro inspecionado. Acessos e estacionamento seguros.",
      );
      a.task = "routine";
      a.elapsed = 0;
      a.path = [];
    }
    if (a.task === "return") {
      a.task = "routine";
      a.path = [];
      a.elapsed = 0;
      log(s, a.name + " · De volta à função de origem.");
    }
    if (a.task === "report") {
      a.action = "radio";
      a.status = "Transmitindo informe";
      if (a.elapsed > 6) {
        finishTask(
          s,
          a,
          "report",
          `Informe: ${s.checkpoint.completed} veículos liberados; ${s.reception.visitors.filter((v) => v.state === "queue").length} pessoa(s) na fila; motopatrulha ${s.life.evasion.stage === "idle" ? "a postos" : "em atendimento"}.`,
        );
        a.task = "routine";
        a.elapsed = 0;
      }
      continue;
    }
    if (a.task === "ready") {
      a.action = "radio";
      a.status = "Confirmando equipamento e prontidão";
      if (a.elapsed > 4) {
        finishTask(
          s,
          a,
          "ready",
          "Equipamento conferido. Pronto para responder a evasões.",
        );
        a.task = "routine";
        a.elapsed = 0;
      }
      continue;
    }
    if (a.id === 0 || a.id === 1) {
      a.action = "typing";
      a.status =
        a.task === "reception"
          ? "Atendendo ocorrências com a recepção"
          : a.id === 0
            ? "Atendendo cidadãos"
            : "Atualizando registros operacionais";
    } else if (a.id === 5) {
      a.action = ["approach", "signal"].includes(s.checkpoint.stage)
        ? "signal"
        : "watch";
      a.status = "Sinalizando e orientando trânsito";
    } else if (a.id === 6) {
      a.action = s.checkpoint.stage === "checking" ? "documents" : "watch";
      a.status = "Conferindo documentos na baia";
    } else if (a.id === 7) {
      a.action = a.elapsed % 18 < 6 ? "radio" : "watch";
      a.status =
        a.action === "radio"
          ? "Comunicando situação da rodovia"
          : "Monitorando canal de serviço";
    } else if (a.id === 8) {
      // Purposeful autonomous inspection, then a real return to the watch post.
      a.action = "watch";
      a.status = "Vigiando acessos da unidade";
      if (
        a.task === "routine" &&
        !isCrewTalking(s, a.id) &&
        a.autonomy?.phase !== "walk" &&
        s.time >= (c.nextPatrolAt ?? 0) &&
        s.life.patrol.stage === "parked" &&
        s.life.patrol.elapsed > 40
      ) {
        a.task = "patrol";
        a.path = [
          [22, 17],
          [19, 24],
          [19, 29],
        ];
        a.waypoint = 0;
        a.elapsed = 0;
        a.cycles++;
        log(s, a.name + " · Iniciando patrulhamento de rotina.");
      }
    } else {
      a.action = a.elapsed % 35 < 5 ? "radio" : "watch";
      a.status = "Conferindo equipamento / pronto para evasão";
    }
    if (a.task === "routine" && !a.moving) {
      const status = crewRoutineStatus(s, a);
      if (status) {
        a.status = status;
        if (a.id === 7 || a.id >= 16) a.action = "radio";
      }
      applyPoliceDecision(s, a);
    }
  }
  advanceCrewConversation(s);
  const m = c.mission;
  if (m.stage === "active") {
    if (
      m.orders["1:reception"] &&
      receptionSupport(s) &&
      m.receptionAfter === undefined
    )
      m.receptionAfter = s.reception.agentCompleted;
    m.checks = missionProgress(s);
    if (m.checks.every(Boolean)) {
      m.stage = "complete";
      c.completed++;
      log(s, "Comando · Missão concluída: " + COMMAND_MISSIONS[m.index].title);
    }
  }
}
export function receptionSupport(s) {
  const a = agentById(s, 1);
  return (
    a.task === "reception" && !a.moving && Math.hypot(a.x - 34, a.z - 22) < 0.5
  );
}
