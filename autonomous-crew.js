import { contextualPoliceDialogue } from "./police-ai.js?v=2.23.1";
// Rotinas propositais: percursos extensos, interação entre colegas e ordens prioritárias.
// Distâncias em metros, posições limitadas às calçadas/corredores do posto.
export const ROUTINE_ROUTES = {
  0: [
    [30.5, 22],
    [30.5, 26],
    [30.5, 28],
    [30.5, 26],
    [30.5, 22],
    [32, 22],
  ],
  1: [
    [40, 21.5],
    [42, 21.5],
    [42, 27.5],
    [40, 28],
    [40, 21.5],
    [38, 22],
  ],
  5: [
    [-5.7, -1.4],
    [-8.5, -1.4],
    [-9.5, 3],
    [-10.3, 9],
    [-9.5, 3],
    [-8.5, -1.4],
    [-5.7, -1.4],
    [-5.7, -4],
  ],
  6: [
    [-10, 17],
    [-10, 12],
    [-9, 9],
    [-10, 12],
    [-10, 17],
    [-10.7, 19.8],
  ],
  7: [
    [12, -10],
    [15, -6],
    [16, -2],
    [18, 2],
    [16, -2],
    [15, -6],
    [12, -10],
    [10.4, -12],
  ],
  8: [
    [21, 5],
    [18, 4],
    [16, 2],
    [18, 4],
    [21, 5],
    [21.5, 9],
  ],
};
const CONVERSATIONS = [
  {
    ids: [7, 8],
    to: {
      7: [
        [12, -10],
        [15, -6],
        [16, -2],
        [18, 2],
      ],
      8: [
        [21, 5],
        [19.8, 3.5],
      ],
    },
    back: {
      7: [
        [16, -2],
        [15, -6],
        [12, -10],
        [10.4, -12],
      ],
      8: [
        [21, 5],
        [21.5, 9],
      ],
    },
    lines: [
      { speaker: 7, text: "Rocha, alguma novidade no pátio?" },
      { speaker: 8, text: "Tudo tranquilo, Lima. Vou reforçar a ronda." },
      { speaker: 7, text: "Beleza. Me avise se surgir ocorrência." },
    ],
  },
  {
    ids: [16, 17],
    to: {},
    back: {},
    lines: [
      { speaker: 16, text: "Oliveira, as motos estão prontas?" },
      { speaker: 17, text: "Sim. Rádio e equipamento conferidos." },
      { speaker: 16, text: "Ótimo. Seguimos atentos aos chamados." },
    ],
  },
];
const distance = (a, b) => Math.hypot(a.x - b.x, a.z - b.z);
function interval(a) {
  return 24 + ((a.id * 7 + a.cycles * 11) % 23);
}
function canWalk(s, a) {
  if (a.task !== "routine" || a.embarked || a.id >= 16 || a.teamwork)
    return false;
  if (
    (a.id === 5 || a.id === 6) &&
    ["setup", "active", "teardown"].includes(s.checkpoint.phase)
  )
    return false;
  if (
    (a.id === 0 || a.id === 1) &&
    s.reception.visitors.some((v) =>
      ["queue", "called", "player"].includes(v.state),
    )
  )
    return false;
  if (a.id === 8 && s.life.patrol.stage !== "parked") return false;
  return true;
}
export function scheduleCrewRoutine(s, a) {
  const brain = (a.autonomy ??= { timer: 6 + a.id * 1.5, phase: "work" });
  if (a.task !== "routine") {
    brain.phase = "work";
    return;
  }
  if (
    brain.phase === "meet" ||
    brain.phase === "talk" ||
    brain.phase === "human"
  )
    return;
  if (brain.phase === "walk" && a.path.length) return;
  if (brain.phase === "walk") {
    brain.phase = "work";
    brain.timer = interval(a);
    a.cycles++;
  }
  if (brain.timer > 0) return;
  if (!canWalk(s, a) || !ROUTINE_ROUTES[a.id]) {
    brain.timer = 6 + (a.id % 5);
    return;
  }
  const route = ROUTINE_ROUTES[a.id];
  a.path = (
    a.cycles % 2
      ? [...route.slice(0, -1)].reverse().concat([route.at(-1)])
      : route
  ).map((p) => [...p]);
  a.waypoint = 0;
  a.elapsed = 0;
  brain.phase = "walk";
  brain.timer = interval(a);
  a.status = "Realizando ronda completa";
}
export function updateCrewRoutineClock(a, dt) {
  if (a.task === "routine" && a.autonomy && a.autonomy.phase === "work")
    a.autonomy.timer = Math.max(0, a.autonomy.timer - dt);
}
export function crewRoutineStatus(s, a) {
  if (a.autonomy?.phase === "walk" && a.path.length)
    return "Em ronda pelo posto";
  const t = a.elapsed + a.id * 3.7;
  if (a.id === 0 || a.id === 1)
    return t % 42 < 5
      ? ["Conferindo atendimento", "Organizando documentos"][a.id]
      : null;
  if (a.id === 5 || a.id === 6)
    return t % 38 < 6 ? "Verificando a sinalização" : null;
  if (a.id === 7) return t % 31 < 5 ? "Checando canal de rádio" : null;
  if (a.id === 8) return t % 29 < 7 ? "Observando o movimento no pátio" : null;
  return t % 35 < 7 ? "Conferindo equipamento da motopatrulha" : null;
}
const findAgent = (s, id) => s.command.agents.find((a) => a.id === id);
const participating = (chat, id) => chat && chat.ids.includes(id);
export function isCrewTalking(s, id) {
  return participating(s.command.conversation, id);
}
function eligible(s, definition) {
  return definition.ids.every((id) => {
    const a = findAgent(s, id);
    if (
      !a ||
      !a.visible ||
      a.embarked ||
      a.task !== "routine" ||
      a.teamwork ||
      a.path.length ||
      distance(a, a.home) > 0.45
    )
      return false;
    if (id >= 16 && s.life.bikes[id - 16].stage !== "ready") return false;
    if (id === 8 && s.life.patrol.stage !== "parked") return false;
    return true;
  });
}
export function beginCrewConversation(s) {
  const c = s.command;
  if (
    c.conversation ||
    s.time < (c.nextConversationAt ?? 12) ||
    ["pursuit", "detained"].includes(s.life.evasion.stage)
  )
    return false;
  const def = CONVERSATIONS[c.conversationTurn ?? 0];
  if (!eligible(s, def)) {
    c.nextConversationAt = s.time + 4;
    return false;
  }
  const dialogue = contextualPoliceDialogue(s, def);
  c.conversation = {
    ids: [...def.ids],
    phase: def.to[def.ids[0]] ? "approach" : "talk",
    lines: dialogue.lines,
    speaker: dialogue.lines[0].speaker,
    text: dialogue.lines[0].text,
    topic: dialogue.topic,
    startedAt: s.time,
    duration: 8.4,
    index: 0,
    back: def.back,
  };
  c.conversationCount = (c.conversationCount ?? 0) + 1;
  c.conversationTurn = ((c.conversationTurn ?? 0) + 1) % CONVERSATIONS.length;
  for (const id of def.ids) {
    const a = findAgent(s, id);
    a.autonomy ??= { timer: 15, phase: "work" };
    a.autonomy.phase = c.conversation.phase === "talk" ? "talk" : "meet";
    a.path = (def.to[id] ?? []).map((p) => [...p]);
    a.waypoint = 0;
    a.status = "Indo falar com colega";
  }
  return true;
}
function returnFromConversation(s, a, back) {
  a.path = (back ?? []).map((p) => [...p]);
  a.waypoint = 0;
  a.autonomy ??= { timer: 20, phase: "work" };
  a.autonomy.phase = a.path.length ? "walk" : "work";
  a.autonomy.timer = 32 + (a.id % 9);
  a.heading = a.id >= 16 ? Math.PI : a.heading;
  a.status = a.path.length ? "Retornando ao posto" : "Em prontidão";
}
export function cancelCrewConversation(s, id = null) {
  const c = s.command,
    chat = c.conversation;
  if (!chat || (id !== null && !participating(chat, id))) return false;
  for (const member of chat.ids) {
    const a = findAgent(s, member);
    if (a) returnFromConversation(s, a, chat.back[member]);
  }
  c.conversation = null;
  c.nextConversationAt = s.time + 24;
  c.nextPatrolAt = s.time + 35;
  return true;
}
export function advanceCrewConversation(s) {
  const c = s.command,
    chat = c.conversation;
  if (!chat) return;
  if (
    chat.ids.some((id) => {
      const a = findAgent(s, id);
      return (
        !a ||
        a.task !== "routine" ||
        !a.visible ||
        (id >= 16 && s.life.bikes[id - 16].stage !== "ready")
      );
    })
  ) {
    cancelCrewConversation(s);
    return;
  }
  if (chat.phase === "approach") {
    if (!chat.ids.every((id) => !findAgent(s, id).path.length)) {
      const walking =
        chat.lines[
          Math.floor((s.time - chat.startedAt) / 2.8) % chat.lines.length
        ];
      chat.speaker = walking.speaker;
      chat.text = walking.text;
      return;
    }
    chat.phase = "talk";
    chat.startedAt = s.time;
    for (const id of chat.ids) findAgent(s, id).autonomy.phase = "talk";
  }
  const elapsed = s.time - chat.startedAt;
  if (elapsed >= chat.duration) {
    cancelCrewConversation(s);
    c.nextConversationAt = s.time + 29;
    return;
  }
  chat.index = Math.min(chat.lines.length - 1, Math.floor(elapsed / 2.8));
  const line = chat.lines[chat.index];
  chat.speaker = line.speaker;
  chat.text = line.text;
  for (const id of chat.ids) {
    const a = findAgent(s, id),
      other = findAgent(
        s,
        chat.ids.find((p) => p !== id),
      );
    a.heading = Math.atan2(other.x - a.x, other.z - a.z);
    a.moving = false;
    a.action = id === chat.speaker ? "signal" : "watch";
    a.status = "Conversando com " + other.name;
  }
}
