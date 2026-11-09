import test from 'node:test';
import assert from 'node:assert/strict';
import {createSimulation,stepSimulation,canWalk,interactVehicle} from '../road-sim.js';
import {sitAtComputer,callCitizen,currentReport,registerReport,leaveComputer} from '../reception-sim.js';
function advance(s,t){for(let i=0;i<t*20;i++)stepSimulation(s,.05);}
test('reception serves continuously with a bounded pool and opens the entrance',()=>{
 const s=createSimulation();advance(s,45);
 assert(s.reception.agentCompleted>0);assert.equal(s.reception.visitors.length,6);
 assert(s.reception.sequence>=4);
 advance(s,240);assert(s.reception.sequence>6);assert(s.reception.agentCompleted>5);
});
test('player sits, calls a citizen, reads, records and leaves without freezing the blitz',()=>{
 const s=createSimulation();assert.equal(sitAtComputer(s),false);
 Object.assign(s.player,{x:31,z:16});assert(sitAtComputer(s));
 advance(s,50);assert(callCitizen(s));assert.equal(registerReport(s),false);
 advance(s,10);assert(currentReport(s));const time=s.time;
 advance(s,2);assert.equal(s.player.x,30);assert(s.time>time);
 assert(registerReport(s));assert.equal(s.reception.completed,1);assert.equal(s.reception.records.length,1);
 assert.equal(registerReport(s),false);assert(interactVehicle(s));assert(!s.reception.seated);assert.equal(s.mode,'foot');
});
test('leaving returns a called citizen to the queue and room walls match walking collisions',()=>{
 const s=createSimulation();Object.assign(s.player,{x:30,z:16});sitAtComputer(s);advance(s,45);callCitizen(s);
 const id=s.reception.active;assert.notEqual(id,null);leaveComputer(s);
 assert.equal(s.reception.visitors[id].state,'queue');assert.equal(s.reception.active,null);
 assert(canWalk(s,33,16));assert(!canWalk(s,33,13));assert(!canWalk(s,26,16));
 s.paused=true;const before=s.reception.sequence;advance(s,20);assert.equal(s.reception.sequence,before);
});
