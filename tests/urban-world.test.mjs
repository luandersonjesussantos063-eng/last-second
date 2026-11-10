import test from "node:test";
import assert from "node:assert/strict";
import {districtPlan,URBAN_DISTRICT} from "../urban-world.js";
test("bairro urbano tem 12 construcoes em escala comprimida e sem cruzar a rodovia",()=>{
 const houses=districtPlan();assert.equal(houses.length,URBAN_DISTRICT.blocks);
 assert(houses.every(h=>h.x>50&&h.z>760&&h.z<940&&h.height>2));
 assert.equal(new Set(houses.map(h=>h.x+":"+h.z)).size,houses.length);
});
