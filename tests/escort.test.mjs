import test from "node:test";
import assert from "node:assert/strict";
import {createSimulation,stepSimulation,interactVehicle,ROAD_LIMIT} from "../road-sim.js";
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
  assert.equal(s.support[0].z,36);
  assert(s.checkpoint.nextDay>1);
  assert.notEqual(scheduledBlitzMinute(2),scheduledBlitzMinute(3));
});
test("three uniformed officers walk to the commander's car, sit inside and disembark",()=>{
  const s=createSimulation();
  Object.assign(s.player,{x:21.9,z:-8});
  assert.equal(interactVehicle(s),true);
  assert.equal(s.escort.stage,"boarding");
  advance(s,10);
  assert.equal(s.escort.stage,"aboard");
  assert.deepEqual([...s.escort.boarded].sort(),[18,19,20]);
  for(const id of [18,19,20]) {
    const a=s.command.agents.find(p=>p.id===id);
    assert.equal(a.action,"seated");
    assert(Math.hypot(a.x-s.car.x,a.z-s.car.z)<2);
  }
  assert.equal(interactVehicle(s),true);
  assert.equal(s.escort.stage,"idle");
  assert(s.command.agents.filter(a=>[18,19,20].includes(a.id)&&a.visible).length===3);
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
