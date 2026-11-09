import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation, stepSimulation } from "../road-sim.js";
import { agentById, agentBusy, issueOrder } from "../command-sim.js";
import {
  createPoliceMind,
  rememberPoliceEvent,
  observePoliceWorld,
  decidePoliceAction,
  contextualPoliceDialogue,
} from "../police-ai.js";

const advance = (s, seconds) => {
  for (let i = 0; i < seconds * 20; i++) stepSimulation(s, 0.05);
};

test("cada policial recebe identidade comportamental e memória própria", () => {
  const s = createSimulation();
  const lima = agentById(s, 7);
  const rocha = agentById(s, 8);
  assert.notEqual(lima.ai.personality, rocha.ai.personality);
  assert.notEqual(lima.ai, rocha.ai);
  assert.equal(lima.ai.memories.length, 0);
  assert.equal(agentById(s, 18).ai.specialty, "patrulha");
  assert.equal(agentBusy(s, agentById(s, 21)), false);
});

test("percepção da blitz, evasão e reforço guarda acontecimentos distintos, sem repetição", () => {
  const s = createSimulation();
  s.time = 2.5;
  s.checkpoint.phase = "setup";
  s.life.evasion.stage = "pursuit";
  s.life.evasion.vehicleId = 4;
  s.escort.backup.stage = "enroute";
  s.escort.backup.since = 2;
  observePoliceWorld(s);
  const lima = agentById(s, 7);
  assert.deepEqual(lima.ai.memories.map(m => m.type).sort(), ["backup", "blitz", "evasion"]);
  assert.equal(agentById(s, 0).ai.memories.some(m => m.type === "blitz"), false);
  const count = lima.ai.memories.length;
  s.time += 2.1;
  observePoliceWorld(s);
  assert.equal(lima.ai.memories.length, count);
  assert(lima.ai.memories.every(m => !("cpf" in m) && !("plate" in m)));
});

test("memória é limitada e permite reconhecer evento novo do mesmo tipo", () => {
  const agent = { id: 7, ai: createPoliceMind({id:7}) };
  for (let n = 0; n < 20; n++)
    rememberPoliceEvent(agent, "evasion", "case-" + n, "Ocorrência fictícia " + n, n);
  assert.equal(agent.ai.memories.length, 6);
  assert.equal(agent.ai.memories.at(-1).summary, "Ocorrência fictícia 19");
  assert.equal(agent.ai.memories[0].summary, "Ocorrência fictícia 14");
  assert.equal(rememberPoliceEvent(agent, "evasion", "case-19", "duplicado", 22), false);
});

test("IA prioriza emergências e não assume o controle durante ordens", () => {
  const s = createSimulation();
  const lima = agentById(s, 7);
  const rocha = agentById(s, 8);
  s.life.evasion.stage = "pursuit";
  assert.equal(decidePoliceAction(s, lima).priority, 100);
  assert.equal(decidePoliceAction(s, rocha).action, "radio");
  assert.equal(issueOrder(s, 7, "report"), true);
  assert.equal(decidePoliceAction(s, lima), null);
  advance(s, 1);
  assert.equal(lima.task, "report");
  assert.equal(lima.action, "radio");
  assert.equal(lima.status, "Transmitindo informe");
});

test("diálogos são sensíveis ao contexto e mudam após as ocorrências", () => {
  const s = createSimulation();
  const def = { ids: [7, 8] };
  const quiet = contextualPoliceDialogue(s, def);
  assert.equal(quiet.lines.length, 3);
  assert(quiet.lines.every(l => typeof l.text === "string" && l.text.length > 10));
  s.clock.day = 2;
  s.checkpoint.phase = "active";
  s.time = 10;
  observePoliceWorld(s);
  const checkpointTalk = contextualPoliceDialogue(s, def);
  assert.equal(checkpointTalk.topic, "blitz");
  assert(checkpointTalk.lines.some(l => /fiscalização|trânsito/.test(l.text)));
  s.checkpoint.phase = "closed";
  s.life.evasion.stage = "detained";
  s.life.evasion.vehicleId = 6;
  s.time = 13;
  observePoliceWorld(s);
  const followup = contextualPoliceDialogue(s, def);
  assert.equal(followup.topic, "evasion");
  assert.notDeepEqual(followup.lines, checkpointTalk.lines);
});

test("cenário parado e pausado não avança a memória nem troca as decisões", () => {
  const s = createSimulation();
  advance(s, 7);
  const lima = agentById(s, 7);
  const snapshot = JSON.stringify(lima.ai);
  s.paused = true;
  advance(s, 30);
  assert.equal(JSON.stringify(lima.ai), snapshot);
});

test("policial em escolta não recebe ação autônoma que atrapalhe a viatura", () => {
  const s = createSimulation();
  const ferreira = agentById(s, 18);
  ferreira.task = "escort";
  assert.equal(decidePoliceAction(s, ferreira), null);
});
