import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import { nearestWeighTruck, WEIGH_SITE } from "../weigh-station.js";
test("carretas leves aparecem no fluxo de trafego",()=>{
 const s=createSimulation(),trucks=s.traffic.filter(v=>v.kind==="truck");
 assert.equal(trucks.length,2);assert(trucks.every(t=>Math.abs(t.x)<7&&t.cruise>0));
});
test("monitor usa dados simulados atuais da carreta mais proxima",()=>{
 const s=createSimulation(),truck=s.traffic.find(v=>v.kind==="truck");
 truck.x=WEIGH_SITE.x;truck.z=WEIGH_SITE.z;truck.speed=12;
 const a=nearestWeighTruck(s.traffic);
 assert.equal(a.plate,truck.plate);assert.equal(a.speedKmh,43);assert(a.grossKg>15000);
 truck.z=WEIGH_SITE.z+500;assert.equal(nearestWeighTruck(s.traffic),null);
});
