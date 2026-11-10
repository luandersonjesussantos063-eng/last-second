import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation} from "../road-sim.js";
import {requestCopom} from "../copom-sim.js";
import {issueOrder} from "../command-sim.js";
import {updateReception} from "../reception-sim.js";
import {npcQueueAssistance} from "../npc-cooperation.js";
const advance=(s,seconds)=>{
 for(let i=0;i<seconds*20;i++)stepSimulation(s,.05);
};
const officer=(s,id)=>s.command.agents.find(a=>a.id===id);
test("Lima e Rocha reagem ao COPOM andando até postos de apoio sem teleportar",()=>{
 const s=createSimulation();
 assert(requestCopom(s));
 const initial=[7,8].map(id=>[officer(s,id).x,officer(s,id).z]);
 let moved=[false,false],maxStep=0;
 for(let tick=0;tick<180;tick++){
  const before=[7,8].map(id=>[officer(s,id).x,officer(s,id).z]);
  stepSimulation(s,.05);
  for(const [i,id] of [7,8].entries()){
   const a=officer(s,id),jump=Math.hypot(a.x-before[i][0],a.z-before[i][1]);
   maxStep=Math.max(maxStep,jump);
   moved[i] ||= Math.hypot(a.x-initial[i][0],a.z-initial[i][1])>1.2;
  }
 }
 assert.deepEqual(moved,[true,true]);
 assert(maxStep<.2,"o agente nunca deve se teleportar");
 assert.equal(officer(s,7).teamwork?.phase,"working");
 assert.equal(officer(s,8).teamwork?.phase,"working");
 assert.equal(officer(s,7).action,"radio");
 assert.equal(officer(s,8).action,"signal");
});
test("Lima e Rocha registram ações concluídas e retomam seus postos",()=>{
 const s=createSimulation();assert(requestCopom(s));
 // Conferir a volta no instante da conclusão; depois o agente pode sair para
 // outra tarefa legítima, sem ficar congelado artificialmente no posto.
 const arrived=new Set();
 for(let i=0;i<50*20 && arrived.size<2;i++) {
  stepSimulation(s,.05);
  for(const id of [7,8]){
   const a=officer(s,id);
   if(a.completed.cooperation===1 && !arrived.has(id)){
    assert.equal(a.teamwork,null);
    assert(Math.hypot(a.x-a.home.x,a.z-a.home.z)<.25,
      a.name+" deve concluir a iniciativa no posto");
    arrived.add(id);
   }
  }
 }
 assert.equal(arrived.size,2);
 const c=s.command.cooperation;
 assert.equal(c.completed,2);
 assert.deepEqual(c.history.map(x=>x.agent).sort(),["Lima","Rocha"]);
 for(const id of [7,8]){
  const a=officer(s,id);
  assert(a.mind.memories.some(m=>m.type==="cooperation"));
  assert.equal(a.completed.cooperation,1);
 }
 const count=c.completed;
 advance(s,8);
 assert.equal(c.completed,count,"não repetir automaticamente o mesmo COPOM");
});
test("Costa percebe fila, caminha até a recepção e agiliza o atendimento",()=>{
 const s=createSimulation();
 s.reception.nextArrival=1000;
 for(let i=0;i<5;i++){
  Object.assign(s.reception.visitors[i],{state:"queue",ticket:i+1,x:35,z:18-i});
 }
 advance(s,5);
 const a=officer(s,1);
 assert(a.teamwork,"Costa deveria colaborar ao detectar fila");
 assert.equal(a.teamwork.type,"queue");
 assert.equal(a.teamwork.phase,"working");
 assert(Math.hypot(a.x-34,a.z-22)<1.1);
 assert(npcQueueAssistance(s));
 s.reception.visitors[0].state="agent";
 s.reception.agentId=0;s.reception.agentTime=0;
 updateReception(s,1);
 assert(s.reception.agentTime>1.25,"a ajuda deve acelerar o atendimento, não só mudar texto");
 advance(s,30);
 assert.equal(a.teamwork,null);
 assert.equal(a.completed.cooperation,1);
 assert(s.command.cooperation.history.some(h=>h.agent==="Costa"));
});
test("ordem manual interrompe imediatamente uma colaboração autônoma",()=>{
 const s=createSimulation();assert(requestCopom(s));
 advance(s,1);
 const lima=officer(s,7);
 assert(lima.teamwork);
 assert(issueOrder(s,7,"report"));
 advance(s,1);
 assert.equal(lima.teamwork,null);
 assert.equal(lima.task,"report");
 assert.equal(lima.action,"radio");
 assert(!s.command.cooperation?.history?.some(x=>x.agent==="Lima"));
});
test("escolta e agentes externos não são desviados por cooperação local",()=>{
 const s=createSimulation();assert(requestCopom(s));
 advance(s,6);
 for(const id of [18,19,20,21,22]){
  const a=officer(s,id);
  assert(!a.teamwork);
 }
 assert.equal(s.escort.stage,"idle");
});
test("plantão pausado não inicia nem conclui iniciativa NPC",()=>{
 const s=createSimulation();assert(requestCopom(s));
 advance(s,2);
 const before=JSON.stringify(officer(s,7).teamwork);
 s.paused=true;advance(s,30);
 assert.equal(JSON.stringify(officer(s,7).teamwork),before);
});
test("painel do comando exibe nome, apoios e histórico de colaboração",()=>{
 const fs=requireFile("command-ui.js");
 const html=requireFile("index.html");
 assert(html.includes('id="npcTeamworkTotal"'));
 assert(html.includes('id="npcTeamworkHistory"'));
 assert(fs.includes("s.command.cooperation"));
});
import {readFileSync} from "node:fs";
function requireFile(path){return readFileSync(path,"utf8");}
