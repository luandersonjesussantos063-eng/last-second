import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,interactMission,stepSimulation} from "../road-sim.js";
import {weighbridgeActionLabel,interactWeighbridge,updateWeighbridge,weighbridgeSummary} from "../weighbridge-sim.js";
import {readFileSync} from "node:fs";

test("balança: não registra pesagem remota, em viatura ou com jogo pausado",()=>{
 const s=createSimulation(),w=s.weighbridge;
 assert.equal(interactWeighbridge(s),false);
 s.mode="foot";s.player.x=w.x+40;s.player.z=w.z;
 assert.equal(interactWeighbridge(s),false);
 s.player.x=w.x;s.paused=true;
 assert.equal(interactWeighbridge(s),false);
 assert.equal(w.completed,0);
});
test("balança: leitura e relatório usam exatamente a massa do estado do simulador",()=>{
 const s=createSimulation(),w=s.weighbridge;
 s.mode="foot";s.player.x=w.x;s.player.z=w.z;
 const mass=w.grossKg,reference=w.referenceKg;
 assert.match(weighbridgeActionLabel(s),/PESAR/);
 assert.equal(interactWeighbridge(s),true);
 assert.equal(w.report.grossKg,mass);
 assert.equal(w.report.referenceKg,reference);
 assert.equal(w.report.differenceKg,Math.max(0,mass-reference));
 assert.equal(interactWeighbridge(s),true);
 assert.equal(w.completed,1);
 assert.equal(w.history[0].grossKg,mass);
 assert.equal(interactWeighbridge(s),false);
});
test("balança: monitor 3D usa leitura real do estado e não valor constante",()=>{
 const source=readFileSync("weighbridge-world.js","utf8");
 assert(source.includes("w.grossKg.toLocaleString"));
 assert(source.includes("truck.group.visible=w.truck.visible"));
 assert(source.includes("truck.update(w.truck,s.time)"));
});
test("balança: transição de saída move carreta e preserva leitura do registro",()=>{
 const s=createSimulation(),w=s.weighbridge;
 s.mode="foot";s.player.x=w.x;s.player.z=w.z;
 assert(interactWeighbridge(s));assert(interactWeighbridge(s));
 const oldZ=w.truck.z,oldReport=w.history[0].grossKg;
 updateWeighbridge(s,1);
 assert(w.truck.z<oldZ);
 assert.equal(w.history[0].grossKg,oldReport);
});
test("COPOM e balança continuam com módulos locais independentes",()=>{
 const command=readFileSync("command-ui.js","utf8");
 const sim=readFileSync("road-sim.js","utf8");
 assert(command.includes("requestCopom(s)"));
 assert(sim.includes("interactWeighbridge"));
 assert(!command.includes("innerHTML"));
});
