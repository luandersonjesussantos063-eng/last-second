import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation,interactMission,actionLabel} from "../road-sim.js";
import {requestCopom,currentCopom,copomStatus,completeCopom} from "../copom-sim.js";
import {readFileSync} from "node:fs";

test("COPOM despacha ocorrência fictícia e rejeita duplicação",()=>{
  const s=createSimulation();
  assert.equal(s.copom.stage,"available");
  assert.equal(s.copom.completed,0);
  assert(requestCopom(s));
  assert.equal(s.copom.stage,"dispatched");
  assert.equal(requestCopom(s),false);
  assert.equal(completeCopom(s),false);
  assert.equal(copomStatus(s),"EM DESLOCAMENTO");
});

test("comandante encontra local, desembarca, sinaliza e registra fechamento",()=>{
  const s=createSimulation();
  assert(requestCopom(s));
  const site=currentCopom(s);
  Object.assign(s.car,{x:site.x,z:site.z+3,speed:0});
  s.mode="drive";
  stepSimulation(s,0.05);
  assert.equal(s.copom.stage,"on_scene");
  assert.equal(completeCopom(s),false,"não pode concluir de dentro do carro");
  Object.assign(s.player,{x:site.x,z:site.z+1});
  s.mode="foot";
  assert.match(actionLabel(s),/ISOLAR/);
  assert.equal(interactMission(s),"incident");
  assert.equal(s.incident.stage,"secured");
  assert.equal(interactMission(s),"incident");
  assert.equal(s.incident.stage,"surveyed");
  for(let i=0;i<30*20;i++)stepSimulation(s,.05);
  assert.equal(s.incident.support.stage,"deployed");
  assert.equal(interactMission(s),"incident");
  assert.equal(s.incident.stage,"towCalled");
  for(let i=0;i<14*20;i++)stepSimulation(s,.05);
  assert.equal(s.incident.stage,"towReady");
  assert.equal(interactMission(s),"incident");
  for(let i=0;i<19*20;i++)stepSimulation(s,.05);
  assert.equal(s.incident.stage,"resolved");
  assert.match(actionLabel(s),/COPOM/);
  assert.equal(interactMission(s),"copom");
  assert.equal(s.copom.stage,"complete");
  assert.equal(s.copom.completed,1);
  assert.equal(s.copom.history.length,1);
  assert.equal(s.copom.history[0].id,"COP-001");
  assert.equal(requestCopom(s),false,"cooldown do próximo chamado");
});

test("longe do local não existe botão de conclusão",()=>{
  const s=createSimulation();
  assert(requestCopom(s));
  s.mode="foot";
  s.player.x=23;s.player.z=0;
  stepSimulation(s,0.05);
  assert.equal(s.copom.stage,"dispatched");
  assert.equal(completeCopom(s),false);
  assert.doesNotMatch(actionLabel(s),/CONCLUIR COPOM/);
});

test("pausa congela o chamado e bloqueia novo despacho",()=>{
  const s=createSimulation();
  s.paused=true;
  assert.equal(requestCopom(s),false);
  s.paused=false;
  assert(requestCopom(s));
  const before=JSON.stringify(s.copom);
  s.paused=true;
  for(let i=0;i<60;i++)stepSimulation(s,0.05);
  assert.equal(JSON.stringify(s.copom),before);
});

test("painel COPOM renderiza texto seguro e contém ações com estados",()=>{
  const html=readFileSync("index.html","utf8");
  const ui=readFileSync("command-ui.js","utf8");
  for (const id of ["copomHud","copomHeading","copomStatus","copomTitle","copomDescription","copomDistance","copomAcceptBtn","copomHistory"]) {
    assert(html.includes('id="'+id+'"'),"ausente "+id);
  }
  assert(ui.includes("requestCopom(s)"));
  assert(ui.includes('copomAcceptBtn").disabled'));
  assert(ui.includes("copomHistory") && ui.includes("replaceChildren"));
  assert(!ui.includes("innerHTML"));
});

test("cenário contém nova área 3D de descanso sem assets externos",()=>{
  const source=readFileSync("road-graphics.js","utf8");
  assert(source.includes("DESCANSO • EQUIPE"));
  assert(source.includes("Cantinho de descanso"));
  assert(source.includes("new T.CylinderGeometry"));
});
