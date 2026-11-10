import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {createSimulation} from "../road-sim.js";
import {platformOccupied,weighbridgePanel,configureReference,interactWeighbridge,updateWeighbridge} from "../weighbridge-sim.js";
const atScale=()=>{const s=createSimulation();s.mode="foot";s.player.x=s.weighbridge.x;s.player.z=s.weighbridge.z;return s;};
test("painel e monitor 3D usam a mesma massa calculada, sem valor fantasma",()=>{
 const s=atScale(),w=s.weighbridge;
 assert(platformOccupied(w));
 assert.equal(weighbridgePanel(s).grossKg,w.grossKg);
 assert.equal(weighbridgePanel(s).excessKg,6600);
 w.truck.visible=false;
 assert.equal(weighbridgePanel(s).grossKg,null);
 assert.equal(weighbridgePanel(s).plate,null);
 assert.equal(interactWeighbridge(s),false);
 const world=readFileSync("weighbridge-world.js","utf8");
 assert.match(world,/w\.grossKg\.toLocaleString/);
});
test("limite é configurável somente antes da pesagem e com valores válidos",()=>{
 const s=atScale();
 assert.equal(configureReference(s,42000),true);
 assert.equal(weighbridgePanel(s).excessKg,9600);
 assert.equal(configureReference(s,0),false);
 assert.equal(configureReference(s,100001),false);
 assert.equal(configureReference(s,42500.1),false);
 s.paused=true;assert.equal(configureReference(s,45000),false);
 s.paused=false;
 assert.equal(interactWeighbridge(s),true);
 assert.equal(configureReference(s,45000),false);
 assert.equal(interactWeighbridge(s),true);
 assert.equal(s.weighbridge.stage,"released");
 assert.equal(weighbridgePanel(s).occupied,false);
 assert.equal(interactWeighbridge(s),false);
 assert.equal(s.weighbridge.completed,1);
 assert.equal(s.weighbridge.history[0].referenceKg,42000);
});
test("painel só autoriza ação presencial e bloqueia carreta em movimento",()=>{
 const s=atScale();
 s.mode="drive";assert.equal(interactWeighbridge(s),false);
 s.mode="foot";s.weighbridge.truck.speed=2;assert.equal(interactWeighbridge(s),false);
 s.weighbridge.truck.speed=0;s.player.z+=20;assert.equal(interactWeighbridge(s),false);
 s.player.z-=20;s.paused=true;assert.equal(interactWeighbridge(s),false);
});
test("painel web possui botões conectados ao simulador, responsividade e texto fictício",()=>{
 const html=readFileSync("index.html","utf8");
 const ui=readFileSync("command-ui.js","utf8");
 for(const id of ["scaleHeading","scaleOccupancy","scaleGross","scaleResult","scaleReference","scaleSave","scaleAction","scaleFeedback","scaleHistory","copomScene","copomObjective"])
  assert(html.includes('id="'+id+'"'),id);
 assert.match(ui,/configureReference\(s,kg\)/);
 assert.match(ui,/interactWeighbridge\(s\)/);
 assert.match(ui,/incidentSummary\(s\)/);
 assert.match(html,/SIMULAÇÃO/);
 assert.match(html,/max-width:100%/);
 assert(!ui.includes("innerHTML"));
});
