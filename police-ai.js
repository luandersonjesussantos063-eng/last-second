// IA comportamental local: percepção, memórias curtas e decisão por prioridades.
// Não usa API generativa, dados reais de cidadãos nem acesso externo.
const MAX_MEMORIES = 6;
const PROFILES = {
  0: ["atencioso", "atendimento"],
  1: ["metódico", "atendimento"],
  5: ["vigilante", "blitz"],
  6: ["analítico", "blitz"],
  7: ["comunicativo", "rádio"],
  8: ["proativo", "patrulha"],
  16: ["prudente", "motopatrulha"],
  17: ["observador", "motopatrulha"],
  18: ["disciplinado", "patrulha"],
  19: ["solidário", "patrulha"],
  20: ["atento", "patrulha"],
  21: ["cooperativo", "apoio"],
  22: ["calmo", "apoio"],
};
export function createPoliceMind(definition) {
  const [personality, specialty] = PROFILES[definition.id] || ["atento", "patrulha"];
  return {
    personality, specialty, memories: [], observed: {},
    decision: "vigilância", current: null, nextDecision: 4 + definition.id % 7,
    sequence: 0,
  };
}
export function rememberPoliceEvent(agent, type, key, summary, time) {
  const mind = agent.ai;
  if (!mind || mind.observed[type] === key) return false;
  mind.observed[type] = key;
  mind.memories.push({ type, summary, time: Math.round(time) });
  if (mind.memories.length > MAX_MEMORIES) mind.memories.shift();
  mind.nextDecision = Math.min(mind.nextDecision, time);
  return true;
}
function observations(s) {
  const events = [];
  const evasion = s.life.evasion;
  if (evasion.stage !== "idle") {
    const msg = evasion.stage === "pursuit" ? "Motopatrulha acompanha um veículo em evasão"
      : evasion.stage === "detained" ? "Veículo interceptado pela motopatrulha"
        : "Motopatrulha retorna do atendimento";
    events.push({ type:"evasion", key:evasion.stage + ":" + evasion.vehicleId + ":" + evasion.completed,
      summary:msg, group:"radio" });
  }
  const cp = s.checkpoint;
  if (cp.phase !== "closed") {
    const msg = { setup:"Equipe montando a blitz", active:"Blitz operando na rodovia",
      teardown:"Equipe recolhendo cones após a blitz" }[cp.phase];
    events.push({ type:"blitz", key:s.clock.day + ":" + cp.phase, summary:msg, group:"blitz" });
  }
  const backup = s.escort.backup;
  if (backup.stage !== "idle") {
    const msg = { enroute:"Reforço acionado pelo comandante", onScene:"Viatura de reforço chegou ao atendimento",
      returning:"Viatura de reforço retornando" }[backup.stage];
    events.push({ type:"backup", key:backup.stage + ":" + backup.since, summary:msg, group:"radio" });
  }
  const queue = s.reception.visitors.filter(v => v.state === "queue").length;
  if (queue >= 3) {
    events.push({ type:"reception", key:s.clock.day + ":" + Math.floor(s.time / 40) + ":" + Math.floor(queue / 3),
      summary:"Recepção com " + queue + " cidadãos aguardando", group:"reception" });
  }
  return events;
}
function hears(agent, event) {
  if (event.group === "reception") return [0, 1, 7].includes(agent.id);
  if (event.group === "blitz") return [5, 6, 7, 8, 18, 19, 20].includes(agent.id);
  return true; // Canal geral de comunicação simulada.
}
export function observePoliceWorld(s) {
  const c = s.command;
  if (s.time < (c.nextAiObservation ?? 0)) return;
  c.nextAiObservation = s.time + 2;
  const active = observations(s);
  for (const a of c.agents) {
    a.ai ??= createPoliceMind(a);
    for (const event of active) {
      if (hears(a, event)) rememberPoliceEvent(a, event.type, event.key, event.summary, s.time);
    }
    // Reencaminhar o mesmo tipo de evento em uma ocorrência futura.
    for (const type of ["evasion", "blitz", "backup", "reception"])
      if (!active.some(e => e.type === type)) delete a.ai.observed[type];
  }
}
const BASE_RESPONSES = {
  0: [
    ["typing", "Atendendo e organizando os registros dos cidadãos"],
    ["documents", "Conferindo relatórios pendentes da unidade"],
    ["watch", "Acompanhando movimentação da recepção"],
  ],
  1: [
    ["typing", "Conferindo a escala e os registros de serviço"],
    ["documents", "Revisando protocolos de atendimento"],
    ["radio", "Atualizando a equipe sobre o plantão"],
  ],
  5: [
    ["watch", "Observando as condições de tráfego"],
    ["radio", "Conferindo sinalização da rodovia"],
    ["signal", "Orientando motoristas na base"],
  ],
  6: [
    ["documents", "Revisando fichas fictícias de fiscalização"],
    ["watch", "Observando o movimento da baia"],
    ["radio", "Conferindo o encerramento de ocorrências"],
  ],
  7: [
    ["radio", "Coordenando comunicação entre as equipes"],
    ["watch", "Acompanhando os chamados do COPOM"],
    ["radio", "Conferindo atualizações da motopatrulha"],
  ],
  8: [
    ["watch", "Avaliando acessos e segurança do pátio"],
    ["radio", "Solicitando situação das equipes externas"],
    ["watch", "Observando os veículos que chegam ao posto"],
  ],
  16: [
    ["watch", "Inspecionando motos antes do serviço"],
    ["radio", "Conferindo o rádio da motopatrulha"],
    ["documents", "Revisando ordens de patrulhamento"],
  ],
  17: [
    ["watch", "Avaliando condições do trecho rodoviário"],
    ["radio", "Verificando comunicação da motopatrulha"],
    ["documents", "Conferindo registros de deslocamento"],
  ],
};
export function decidePoliceAction(s, agent) {
  const mind = agent.ai;
  if (!mind || agent.task !== "routine" || agent.moving || agent.path.length ||
      agent.embarked || ["meet", "talk", "walk"].includes(agent.autonomy?.phase)) return null;
  if ((agent.id === 5 || agent.id === 6) &&
      ["setup", "active", "teardown"].includes(s.checkpoint.phase)) return null;
  if ([16, 17].includes(agent.id) && s.life.bikes[agent.id - 16].stage !== "ready") return null;
  if (agent.id >= 18) return null; // Escolta e reforço seguem as próprias tarefas.
  const evasion = s.life.evasion.stage;
  if (["pursuit", "detained"].includes(evasion)) {
    const emergency = ["Acompanhando evasão pelo rádio", "Monitorando posicionamento do apoio"];
    return { action: agent.id === 5 ? "signal" : "radio",
      status: emergency[agent.id % 2], priority: 100 };
  }
  if (s.escort.backup.stage === "enroute" || s.escort.backup.stage === "onScene") {
    return { action:"radio", status:"Compartilhando informações com o reforço", priority: 85 };
  }
  const queue = s.reception.visitors.filter(v => v.state === "queue").length;
  if (queue >= 3 && [0, 1, 7].includes(agent.id)) {
    return { action:agent.id === 7 ? "radio" : "typing",
      status:"Organizando atendimento da fila", priority: 75 };
  }
  if (s.time >= mind.nextDecision || !mind.current) {
    const pool = BASE_RESPONSES[agent.id] || BASE_RESPONSES[8];
    const i = (agent.id * 3 + mind.sequence * 5 + Math.floor(s.clock.minute / 37)) % pool.length;
    const [action, status] = pool[i];
    mind.current = { action, status, priority: 10 };
    mind.sequence += 1;
    mind.nextDecision = s.time + 7 + ((agent.id * 5 + mind.sequence * 3) % 9);
  }
  return mind.current;
}
export function applyPoliceDecision(s, agent) {
  const choice = decidePoliceAction(s, agent);
  if (!choice) return false;
  agent.action = choice.action;
  agent.status = choice.status;
  agent.ai.decision = choice.status;
  return true;
}
export function contextualPoliceDialogue(s, definition) {
  const [one, two] = definition.ids;
  const a = s.command.agents.find(p => p.id === one);
  const b = s.command.agents.find(p => p.id === two);
  const recent = [...a.ai.memories, ...b.ai.memories]
    .filter(m => s.time - m.time <= 150)
    .sort((x, y) => y.time - x.time);
  const latest = recent[0];
  let topic = latest?.type || "routine";
  if (topic === "evasion" && s.life.evasion.stage === "idle") topic = "post_evasion";
  const options = {
    post_evasion:[
      "Você viu o atendimento da motopatrulha?",
      "Vi sim, a equipe já retornou à rotina.",
      "Ótimo. Vamos registrar e manter a atenção no trecho.",
    ],
    evasion:[
      "Recebeu o comunicado de ocorrência na rodovia?",
      "Recebi. A motopatrulha já está acompanhando.",
      "Vou continuar monitorando a situação pelo rádio.",
    ],
    blitz:[
      "Como está a organização da fiscalização?",
      "A escala está sendo cumprida e o trânsito está monitorado.",
      "Certo. Depois do turno, vamos conferir os equipamentos.",
    ],
    backup:[
      "O apoio do comandante já foi comunicado?",
      "Sim, a outra viatura recebeu o chamado.",
      "Entendido. Vamos acompanhar pelo rádio.",
    ],
    reception:[
      "A recepção está com muita movimentação?",
      "A equipe está organizando os atendimentos.",
      "Vou avisar o restante do plantão.",
    ],
  };
  const quiet = [
    ["Conferiu a escala de patrulha de hoje?", "Conferi, os horários estão organizados.", "Perfeito. Qualquer novidade, avise no rádio."],
    ["Como está o movimento por aqui?", "Trânsito normal, mas estamos acompanhando tudo.", "Certo. Vou fazer outra verificação."],
    ["Os equipamentos da equipe estão em ordem?", "Sim, conferi rádio e materiais de serviço.", "Ótimo. Segurança em primeiro lugar."],
  ];
  const lines = options[topic] || quiet[(s.command.conversationCount ?? 0) % quiet.length];
  return {topic, lines:lines.map((text,i) => ({speaker:i % 2 === 0 ? one : two, text}))};
}
