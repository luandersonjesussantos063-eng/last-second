import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation,circleBlocked} from "../road-sim.js";
import {agentById,issueOrder} from "../command-sim.js";
import {
  LIFE_IDS, REST_POINTS, SWAP_PATHS, pathFor,
  maybeStartHumanShift, maybeStartPostRotation,
} from "../officer-life.js";

const advance=(s,seconds)=>{
  for(let i=0;i<seconds*20;i++)stepSimulation(s,0.05);
};
test("água, banheiro e revezamento têm percursos livres de obstáculos estáticos",()=>{
  const s=createSimulation();
  for(const id of LIFE_IDS) {
    const a=agentById(s,id);
    for(const purpose of ["water","restroom","post"]) {
      const path=pathFor(a,purpose);
      assert(path.length>=3,`${a.name} - ${purpose}`);
      let from=[a.home.x,a.home.z];
      for(const dest of path) {
        const d=Math.hypot(dest[0]-from[0],dest[1]-from[1]);
        const steps=Math.max(1,Math.ceil(d/0.18));
        for(let i=0;i<=steps;i++) {
          const x=from[0]+(dest[0]-from[0])*i/steps;
          const z=from[1]+(dest[1]-from[1])*i/steps;
          assert.equal(circleBlocked(x,z,0.32),false,`${a.name} - ${purpose} cruza parede em ${x.toFixed(2)},${z.toFixed(2)}`);
        }
        from=dest;
      }
    }
  }
  for(const id of [7,8]) {
    let from=[agentById(s,id).home.x,agentById(s,id).home.z];
    for(const to of SWAP_PATHS[id]) {
      const length=Math.hypot(to[0]-from[0],to[1]-from[1]);
      for(let j=0;j<=Math.ceil(length/0.18);j++) {
        const n=Math.ceil(length/0.18), t=j/n;
        assert(!circleBlocked(from[0]+(to[0]-from[0])*t,
          from[1]+(to[1]-from[1])*t,0.32));
      }
      from=to;
    }
  }
  assert.deepEqual(REST_POINTS.indoorWater,[37.8,13.5]);
});

test("policial sai do posto, bebe água, retorna caminhando e lembra da pausa",()=>{
  const s=createSimulation(),silva=agentById(s,5);
  silva.human.nextAt=0;
  silva.human.sequence=1; // O primeiro descanso de Silva será água, não troca de posto.
  s.checkpoint.nextDay=3;
  s.life.evasion.nextAt=10000;
  let left=false, drank=false, returned=false, maxStep=0;
  let prev=[silva.x,silva.z];
  for(let i=0;i<1200;i++) {
    stepSimulation(s,0.05);
    maxStep=Math.max(maxStep,Math.hypot(silva.x-prev[0],silva.z-prev[1]));
    prev=[silva.x,silva.z];
    left ||= silva.human?.phase==="going";
    drank ||= silva.action==="drink" && silva.human?.phase==="break";
    if(drank && silva.human?.phase==="idle" && silva.human.counts.water>0) {
      returned=true;break;
    }
  }
  assert(left);
  assert(drank,"deve fazer gesto de beber água próximo ao bebedouro: "+
    JSON.stringify({human:silva.human,position:[silva.x,silva.z],status:silva.status,checkpoint:s.checkpoint.phase}));
  assert(returned,"deve voltar após a pausa");
  assert(maxStep<0.2,"não pode se teletransportar");
  assert(Math.hypot(silva.x-silva.home.x,silva.z-silva.home.z)<0.25);
  assert(silva.ai.memories.some(m=>m.type==="activity"));
});

test("banheiro é privativo e o agente volta visível ao mesmo posto",()=>{
  const s=createSimulation(),costa=agentById(s,1);
  costa.human.nextAt=0;
  s.checkpoint.nextDay=3;
  s.life.evasion.nextAt=10000;
  let privacy=false, returned=false;
  for(let i=0;i<1500;i++) {
    stepSimulation(s,0.05);
    if(costa.human.phase==="break" && costa.human.purpose==="restroom") {
      privacy=true;
      assert.equal(costa.visible,false);
      assert.equal(costa.status,"No banheiro");
    }
    if(privacy && costa.human.phase==="idle" && costa.human.counts.restroom>0) {
      returned=true;break;
    }
  }
  assert(privacy && returned);
  assert.equal(costa.visible,true);
  assert(Math.hypot(costa.x-costa.home.x,costa.z-costa.home.z)<0.25,
    JSON.stringify({position:[costa.x,costa.z],home:costa.home,human:costa.human}));
});

test("postos de rádio e vigilância são trocados por dois agentes, sem mudar função de outros",()=>{
  const s=createSimulation();
  s.time=65;
  assert.equal(maybeStartPostRotation(s),true);
  for(const id of [7,8]) {
    const a=agentById(s,id);
    assert.equal(a.human.phase,"going");
    assert.equal(a.human.purpose,"swap");
    assert(a.path.length>=3);
  }
  assert.equal(agentById(s,16).task,"routine");
  assert.equal(maybeStartPostRotation(s),false);
});

test("em uma ordem do comandante a pausa é cancelada imediatamente",()=>{
  const s=createSimulation(),a=agentById(s,7);
  a.human.nextAt=0;
  assert(maybeStartHumanShift(s,a));
  assert.equal(a.human.phase,"going");
  assert(issueOrder(s,7,"report"));
  assert.equal(a.human.phase,"idle");
  assert.equal(a.task,"report");
  assert.equal(a.path.length,0);
  advance(s,7);
  assert((a.completed.report??0)>0);
});

test("serviço da blitz, fila, motos em ocorrência e múltiplas pausas simultâneas são protegidos",()=>{
  const s=createSimulation();
  s.checkpoint.phase="active";
  const silva=agentById(s,5);
  silva.human.nextAt=0;
  assert.equal(maybeStartHumanShift(s,silva),false);
  s.checkpoint.phase="closed";
  s.reception.visitors[0].state="queue";
  const almeida=agentById(s,0);almeida.human.nextAt=0;
  assert.equal(maybeStartHumanShift(s,almeida),false);
  s.reception.visitors[0].state="away";
  assert.equal(maybeStartHumanShift(s,almeida),true);
  const costa=agentById(s,1);costa.human.nextAt=0;
  assert.equal(maybeStartHumanShift(s,costa),false);
  const santos=agentById(s,16);santos.human.nextAt=0;
  s.life.bikes[0].stage="pursuit";
  assert.equal(maybeStartHumanShift(s,santos),false);
});

test("jogo pausado não avança pausas ou memórias",()=>{
  const s=createSimulation(),a=agentById(s,5);
  a.human.nextAt=0;
  stepSimulation(s,0.05);
  const before=JSON.stringify({human:a.human,x:a.x,z:a.z,memories:a.ai.memories});
  s.paused=true;
  advance(s,25);
  assert.equal(JSON.stringify({human:a.human,x:a.x,z:a.z,memories:a.ai.memories}),before);
});
