import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import { startCommandMission } from "../command-sim.js";
import { copomSnapshot } from "../copom-board.js";
test("COPOM: despacho altera status e não duplica chamado ativo", () => {
  const s = createSimulation();
  assert.equal(copomSnapshot(s).status, "Aguardando despacho");
  assert.match(copomSnapshot(s).action, /DESPACHAR/);
  assert.equal(startCommandMission(s), true);
  assert.equal(copomSnapshot(s).status, "Em atendimento");
  assert.equal(copomSnapshot(s).action, null);
  assert.equal(startCommandMission(s), false);
  assert.equal(copomSnapshot(s).total, 3);
});
test("COPOM: pausa bloqueia despacho e histórico fica local", () => {
  const s = createSimulation();
  s.paused = true;
  assert.equal(startCommandMission(s), false);
  assert.equal(copomSnapshot(s).history.length, 0);
  s.paused = false;
  assert.equal(startCommandMission(s), true);
  assert.match(copomSnapshot(s).history[0].text, /Missão iniciada/);
});
