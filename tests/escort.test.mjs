import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation,interactVehicle,ROAD_LIMIT,circleBlocked} from "../road-sim.js";
import {ESCORT_WALKOUT_ROUTES} from "../escort-sim.js";
import {requestBackup} from "../escort-sim.js";
import {scheduledBlitzMinute} from "../blitz-sim.js";
const advance=(s,n)=>{for(let i=0;i<n*20;i++)stepSimulation(s,0.05);};
test("checkpoint is dismantled between variable daily shifts and cone count follows setup and teardown",()=>{
  const s=createSimulation();
  assert.equal(s.checkpoint.phase,"closed");
  assert.equal(s.checkpoint.conesPlaced,0);
  assert(s.checkpoint.startMinute>=16*60+44);
  assert(s.checkpoint.startMinute<=17*60);
  let setup=false, active=false, teardown=false, closed=false;
  for(let i=0;i<260*20;i++) {
    stepSimulation(s,0.05);
    const c=s.checkpoint;
    setup ||= c.phase==="setup"&&c.conesPlaced>0;
    active ||= c.phase==="active"&&c.conesPlaced>0;
    teardown ||= c.phase==="teardown"&&c.conesPlaced<13;
    if(active&&c.phase==="closed") {closed=true;break;}
  }
  assert(setup);assert(active);assert(teardown);assert(closed);
  assert.equal(s.checkpoint.conesPlaced,0);
  assert.equal(s.support[0].z,43);
  assert(s.checkpoint.nextDay>1);
  assert.notEqual(scheduledBlitzMinute(2),scheduledBlitzMinute(3));
});
test("three uniformed officers walk to the commander's car, sit inside and disembark",()=>{
  const s=createSimulation();
  Object.assign(s.player,{x:21.9,z:-8});
  assert.equal(interactVehicle(s),true);
  assert.equal(s.escort.stage,"boarding");
  advance(s,34);
  assert.equal(s.escort.stage,"aboard");
  assert.deepEqual([...s.escort.boarded].sort(),[18,19,20]);
  for(const id of [18,19,20]) {
    const a=s.command.agents.find(p=>p.id===id);
    assert.equal(a.action,"seated");
    assert(Math.hypot(a.x-s.car.x,a.z-s.car.z)<2);
  }
  assert.equal(interactVehicle(s),true);
  assert.equal(s.escort.stage,"returning");
  advance(s,42);
  assert.equal(s.escort.stage,"idle");
  for (const id of [18,19,20]) {
    const a=s.command.agents.find(p=>p.id===id);
    assert(Math.hypot(a.x-a.home.x,a.z-a.home.z)<0.2);
    assert(a.x>=39 && a.x<=43 && a.z>=26 && a.z<=29);
    assert.equal(a.task,"routine");
  }
});
test("backup request dispatches independent marked vehicle and two officers with cooldown",()=>{
  const s=createSimulation();
  assert.equal(requestBackup(s).ok,true);
  assert.equal(requestBackup(s).ok,false);
  advance(s,8);
  assert.equal(s.escort.backup.stage,"onScene");
  assert(s.command.agents.find(a=>a.id===21).visible);
  assert(s.command.agents.find(a=>a.id===22).visible);
  advance(s,50);
  assert.equal(s.escort.backup.stage,"idle");
  assert.equal(requestBackup(s).ok,false);
});
test("road extends nearly 1.5 km each way without changing the static-site model",()=>{
  assert(ROAD_LIMIT>=1450);
});

test("two traffic officers physically deploy and collect equipment during shift transitions", () => {
  const s=createSimulation();
  let started=false, workerMoved=false, cleaned=false;
  const worker=s.command.agents.find(a=>a.id===5);
  for(let i=0;i<260*20;i++) {
    stepSimulation(s,0.05);
    if(s.checkpoint.phase==="setup") {
      started=true;
      workerMoved ||= Math.hypot(worker.x-worker.home.x,worker.z-worker.home.z)>1;
    }
    if(started && s.checkpoint.phase==="closed" && s.checkpoint.nextDay===2) {
      cleaned=true;break;
    }
  }
  assert(started);
  assert(workerMoved, "the officer should walk while placing cones");
  assert(cleaned);
  assert.equal(s.checkpoint.conesPlaced,0);
});

test("a equipe começa dentro do prédio e não sai sozinha antes de o comandante embarcar",()=>{
  const s=createSimulation();
  for(const id of [18,19,20]) {
    const a=s.command.agents.find(p=>p.id===id);
    assert(a.x>39 && a.x<43 && a.z>26 && a.z<29);
    assert.equal(a.task,"routine");
    assert.equal(a.path.length,0);
  }
  advance(s,72);
  assert.equal(s.escort.stage,"idle");
  for(const id of [18,19,20]) {
    const a=s.command.agents.find(p=>p.id===id);
    assert(Math.hypot(a.x-a.home.x,a.z-a.home.z)<0.2,"agente não deve sair sozinho");
  }
});

test("policiais caminham desde a unidade até a viatura sem teleporte",()=>{
  const s=createSimulation();
  Object.assign(s.player,{x:21.9,z:-8});
  assert(interactVehicle(s));
  let outside=false, maxStep=0;
  const former=s.command.agents.filter(a=>[18,19,20].includes(a.id));
  for(let i=0;i<900 && s.escort.stage!=="aboard";i++) {
    const previous=former.map(a=>[a.x,a.z]);
    stepSimulation(s,0.05);
    former.forEach((a,j)=>{
      const delta=Math.hypot(a.x-previous[j][0],a.z-previous[j][1]);
      // O embarque na posição do assento pode avançar um metro na animação.
      if(a.action!=="seated")maxStep=Math.max(maxStep,delta);
      if(a.z<9)outside=true;
    });
  }
  assert(outside,"a equipe deve sair pela porta do prédio");
  assert(maxStep<0.25,"deslocamento dos agentes deve ser gradual");
  assert.equal(s.escort.stage,"aboard");
});
test("ao sair longe da base, acompanhantes aguardam na viatura sem caminhar até o posto",()=>{
  const s=createSimulation();
  Object.assign(s.player,{x:21.9,z:-8});
  assert(interactVehicle(s));
  advance(s,34);
  assert.equal(s.escort.stage,"aboard");
  Object.assign(s.car,{x:5,z:-250,speed:0});
  assert(interactVehicle(s));
  assert.equal(s.escort.stage,"aboard");
  advance(s,4);
  for(const id of [18,19,20]){
    const a=s.command.agents.find(p=>p.id===id);
    assert.equal(a.action,"seated");
    assert(Math.hypot(a.x-s.car.x,a.z-s.car.z)<2);
  }
  Object.assign(s.player,{x:s.car.x+1,z:s.car.z});
  assert(interactVehicle(s));
  assert.equal(s.escort.stage,"aboard");
});

test("saída dos três policiais segue caminhos transitáveis, sem atravessar paredes",()=>{
  const s=createSimulation();
  for(let i=0;i<3;i++) {
    const a=s.command.agents.find(p=>p.id===18+i);
    const path=ESCORT_WALKOUT_ROUTES[i];
    let from=[a.home.x,a.home.z];
    for(const to of path) {
      const distance=Math.hypot(to[0]-from[0],to[1]-from[1]);
      const count=Math.max(1,Math.ceil(distance/0.16));
      for(let k=0;k<=count;k++) {
        const t=k/count;
        const x=from[0]+(to[0]-from[0])*t;
        const z=from[1]+(to[1]-from[1])*t;
        assert(!circleBlocked(x,z,0.32),
          `${a.name}: o caminho atravessa um obstáculo em ${x.toFixed(2)},${z.toFixed(2)}`);
      }
      from=to;
    }
  }
});
