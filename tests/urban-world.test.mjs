import test from "node:test";
import assert from "node:assert/strict";
import {districtPlan,urbanVehicles,URBAN_DISTRICT} from "../urban-world.js";
test("bairro urbano tem 12 construcoes em escala comprimida e sem cruzar a rodovia",()=>{
 const houses=districtPlan();assert.equal(houses.length,URBAN_DISTRICT.blocks);
 assert(houses.every(h=>h.x>50&&h.z>760&&h.z<940&&h.height>2));
 assert.equal(new Set(houses.map(h=>h.x+":"+h.z)).size,houses.length);
});

test("automoveis urbanos 3D nao bloqueiam a rodovia principal nem as ruas de cruzamento",()=>{
 const vehicles=urbanVehicles();
 assert.equal(vehicles.length,6);
 assert(vehicles.every(v=>v.x>50&&v.z>770&&v.z<930));
 assert(vehicles.every(v=>Math.abs(v.x-102)>5 || Math.abs(v.z-850)>8));
 assert.equal(new Set(vehicles.map(v=>v.x+":"+v.z)).size,vehicles.length);
});
