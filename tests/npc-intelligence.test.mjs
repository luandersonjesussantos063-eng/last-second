import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation} from "../road-sim.js";
import {npcCandidates,contextualNpcAnswer} from "../npc-local-chat.js";
import {
  createNpcMind,rememberNpc,perceiveNpc,chooseNpcGoal,updateNpcMinds,NPC_MEMORY_LIMIT
} from "../npc-intelligence.js";
const advance=(s,t)=>{for(let i=0;i<t*20;i++)stepSimulation(s,0.05)};
test("todos os policiais, civis e motoristas recebem memória e objetivos individuais",()=>{
  const s=createSimulation();
  const group=[...s.command.agents,...s.reception.visitors,...s.traffic];
  assert.equal(group.length,33);
  assert(group.every(n=>n.mind && n.mind.memories.length===0));
  assert.notEqual(s.command.agents[0].mind,s.command.agents[1].mind);
  assert.notEqual(s.traffic[0].mind,s.traffic[1].mind);
  advance(s,2.5);
  assert(group.every(n=>n.mind.thoughtCount>0 && n.mind.goal.length>0));
});
test("percepção, memória individual limitada e objetivos de emergência",()=>{
  const s=createSimulation();
  const a=s.command.agents.find(n=>n.id===7);
  s.life.evasion.stage="pursuit";s.life.evasion.vehicleId=2;
  s.time=5;
  const perceptions=perceiveNpc(s,a,a.mind);
  assert(perceptions.some(e=>e.type==="evasion"));
  assert.equal(chooseNpcGoal(s,a,a.mind,perceptions),"apoiar_ocorrencia");
  updateNpcMinds(s);
  assert(a.mind.memories.some(m=>m.type==="evasion"));
  for(let i=0;i<22;i++)rememberNpc(a.mind,"test",i,"Evento fictício "+i,i);
  assert.equal(a.mind.memories.length,NPC_MEMORY_LIMIT);
  assert.equal(rememberNpc(a.mind,"test",21,"Duplicado",25),false);
});
test("ordem do comandante e escolta prevalecem sobre metas autônomas",()=>{
  const s=createSimulation();
  const rocha=s.command.agents.find(n=>n.id===8),ferreira=s.command.agents.find(n=>n.id===18);
  s.life.evasion.stage="pursuit";
  rocha.task="report";
  const scenes=perceiveNpc(s,rocha,rocha.mind);
  assert.equal(chooseNpcGoal(s,rocha,rocha.mind,scenes),"cumprir_ordem");
  s.escort.stage="boarding";
  assert.equal(chooseNpcGoal(s,ferreira,ferreira.mind,perceiveNpc(s,ferreira,ferreira.mind)),"acompanhar_comandante");
});
test("motorista reage à sirene sem sobrepor a fiscalização e o limite existente",()=>{
  const s=createSimulation(),driver=s.traffic[0];
  Object.assign(s,{mode:"drive",time:5});
  Object.assign(s.car,{x:driver.x,z:driver.z-12,speed:12,siren:true});
  const perceptions=perceiveNpc(s,driver,driver.mind);
  assert(perceptions.some(e=>e.type==="siren"));
  assert.equal(chooseNpcGoal(s,driver,driver.mind,perceptions),"reduzir_por_sirene");
  updateNpcMinds(s);
  assert(driver.mind.pace<1);
  s.car.siren=false;
  s.time=10;s.nextNpcThoughtAt=0;driver.mind.nextThought=0;
  updateNpcMinds(s);
  assert.equal(driver.mind.goal,"seguir_viagem");
  assert.equal(driver.mind.pace,1);
});
test("cidadãos percebem atendimento, saída e mudança na fila",()=>{
  const s=createSimulation(),visitor=s.reception.visitors[0];
  visitor.state="queue";visitor.ticket=7;s.time=4;
  const obs=perceiveNpc(s,visitor,visitor.mind);
  assert.equal(chooseNpcGoal(s,visitor,visitor.mind,obs),"aguardar_atendimento");
  visitor.state="agent";s.time=8;
  assert.equal(chooseNpcGoal(s,visitor,visitor.mind,perceiveNpc(s,visitor,visitor.mind)),"prestar_informacoes");
  visitor.state="exit";
  assert.equal(chooseNpcGoal(s,visitor,visitor.mind,perceiveNpc(s,visitor,visitor.mind)),"retornar_viagem");
});
test("o NPC responde sobre fatos verdadeiros da partida sem acesso a API externa",()=>{
  const s=createSimulation();
  const target=npcCandidates(s).find(p=>p.key==="police:7");
  assert(target);
  const quiet=contextualNpcAnswer(s,target,"Como está a blitz?");
  s.checkpoint.phase="active";
  const on=contextualNpcAnswer(s,target,"Como está a blitz?");
  assert.notEqual(quiet,on);
  assert.match(on,/andamento/);
  s.copom.stage="dispatched";
  assert.match(contextualNpcAnswer(s,target,"Tem chamado COPOM?"),/atendimento/);
  assert(contextualNpcAnswer(s,target,"Qual seu nome?").includes("Lima"));
});
test("nenhuma mente evolui enquanto o jogo está pausado",()=>{
  const s=createSimulation();
  advance(s,2);
  const before=JSON.stringify(s.traffic[0].mind);
  s.paused=true;advance(s,30);
  assert.equal(JSON.stringify(s.traffic[0].mind),before);
});
test("o navegador exibe um botão de diálogo e ativa modelo generativo só por consentimento",()=>{
  const html=awaitFile("index.html"),js=awaitFile("npc-local-chat.js");
  for(const id of ["npcTalkBtn","npcChatDialog","npcChatInput","npcChatTarget",
    "npcChatLocalEnable","npcChatAnswer","npcChatSend","npcChatClose"]){
    assert(html.includes('id="'+id+'"'),"Elemento de conversa ausente: "+id);
  }
  assert(js.includes('$("npcChatLocalEnable").onclick'));
  assert(js.includes("LanguageModel"));
  assert(!js.includes("fetch("));
  assert(!js.includes("innerHTML"));
});
import {readFileSync} from "node:fs";
function awaitFile(path){return readFileSync(path,"utf8");}

test("o atalho de conversa não fecha a janela quando o usuário digita N",()=>{
  const src=readFileSync("main.js","utf8");
  assert(src.includes('document.activeElement?.tagName'));
  assert(src.includes('e.code === "KeyN" && !typing'));
  assert(src.includes('e.code === "Escape"'));
});
