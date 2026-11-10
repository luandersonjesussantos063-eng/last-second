import test from "node:test";
import assert from "node:assert/strict";
import { createSimulation } from "../road-sim.js";
import { SAVE_KEY, WEATHER, createOperations, updateOperations, setWeather, addRecord, saveCareer, restoreCareer, serviceVehicle, inspectionDetails, decideInspection, recordInspection, useRepairKit, careerRank } from "../operations-sim.js";
function fixture() { const s = createSimulation(); s.operations = createOperations(); s.car.fuel = 100; return s; }
function storage() { const data = new Map(); return { getItem: key => data.get(key) ?? null, setItem: (key, value) => data.set(key, value) }; }
test("career reload restores resolved records and counters without awarding the same work twice", () => {
  const s = fixture(), store = storage(); s.completed = 3; s.copom.completed = 2; s.command.completed = 1; updateOperations(s, 0); const xp = s.operations.career.xp;
  s.car.fuel = 42; s.car.condition = 55; s.clock.day = 2; s.clock.minute = 720;
  assert(saveCareer(s, store)); const restored = fixture(); assert(restoreCareer(restored, store)); assert.equal(restored.car.fuel, 42); assert.equal(restored.clock.day, 2); assert.equal(restored.completed, 3); assert.equal(restored.operations.career.xp, xp);
  updateOperations(restored, 0); assert.equal(restored.operations.career.xp, xp); assert(restored.operations.records.length >= 3);
});
test("missing, corrupted, unsupported and unavailable storage fail safely", () => {
  const s = fixture(), store = storage(); assert(!restoreCareer(s, store));
  for (const raw of ["{broken", "null", JSON.stringify({ schema: 2, career: {} }), JSON.stringify({ schema: 1, career: [] }), "x".repeat(26000)]) { store.setItem(SAVE_KEY, raw); assert(!restoreCareer(s, store)); }
  assert(!saveCareer(s, { setItem() { throw Error("denied"); } })); assert.match(s.operations.saveStatus, /indisponível/);
});
test("malformed fields are bounded and inherited object keys cannot become weather", () => {
  const s = fixture(), store = storage(); store.setItem(SAVE_KEY, JSON.stringify({ schema: 1, career: { xp: -10, rating: 999, shifts: 1e15 }, car: { fuel: -2, condition: 110 }, clock: { day: -50, minute: 9999 }, weather: "__proto__", records: Array.from({ length: 35 }, () => ({ text: "x".repeat(600), day: -2, minute: 9999 })) }));
  assert(restoreCareer(s, store)); assert.equal(s.operations.career.xp, 0); assert.equal(s.operations.career.rating, 100); assert.equal(s.car.fuel, 0); assert.equal(s.car.condition, 100); assert(s.operations.records.length <= 30); assert.equal(s.operations.records[0].text.length, 300); assert.equal(s.operations.weather.kind, "clear");
  for (const kind of ["__proto__", "constructor", "toString", "snow"]) assert(!setWeather(s, kind));
});
test("rain reduces grip and fuel consumption occurs only in a driven vehicle", () => {
  const s = fixture(); assert(setWeather(s, "rain")); assert(WEATHER.rain.grip < WEATHER.clear.grip); s.car.speed = 25; updateOperations(s, 10); assert.equal(s.car.fuel, 100); s.mode = "drive"; updateOperations(s, 10); assert(s.car.fuel < 100); assert(s.car.fuel > 99); assert.equal(s.operations.weather.automatic, false);
});
test("fuel and workshop services require a compatible nearby facility and stopped vehicle", () => {
  const s = fixture(), f = { kind: "fuel", x: 50, z: -35 }; s.car.fuel = 12; assert(!serviceVehicle(s, "fuel", f)); Object.assign(s.car, { x: 50, z: -35, speed: 2 }); assert(!serviceVehicle(s, "fuel", f)); s.car.speed = 0; assert(serviceVehicle(s, "fuel", f)); assert.equal(s.car.fuel, 100); s.car.condition = 35; assert(!serviceVehicle(s, "repair", f)); assert(serviceVehicle(s, "repair", { ...f, kind: "repair" })); assert.equal(s.car.condition, 100);
});
test("inspection decisions create fictional records and assess release of an irregular vehicle", () => {
  const s = fixture(); s.inspection = true; s.mission.report = inspectionDetails({ id: 2, plate: "FIC-0002" }); assert(s.mission.report.irregular); assert(!decideInspection(s, "invalid")); assert(decideInspection(s, "orient")); recordInspection(s); assert.equal(s.operations.career.rating, 98); assert.match(s.operations.records[0].text, /FIC-0002/); assert(decideInspection(s, "retain")); recordInspection(s); assert.match(s.operations.records[0].text, /pátio/);
});
test("completed shift and work are rewarded once and history stays bounded", () => {
  const s = fixture(); s.completed = 2; s.clock.day = 2; updateOperations(s, 0); assert.equal(s.operations.career.inspections, 2); assert.equal(s.operations.career.shifts, 1); const xp = s.operations.career.xp; updateOperations(s, 0); assert.equal(s.operations.career.xp, xp); for (let i = 0; i < 100; i++) addRecord(s, "test", "Registro"); assert.equal(s.operations.records.length, 30); s.operations.career.xp = 700; assert.equal(careerRank(s), "Comando regional");
});
test("the repair kit unlocks at 250 XP and repairs only once per game day", () => {
  const s = fixture(); s.car.condition = 40; assert(!useRepairKit(s)); s.operations.career.xp = 250; assert(useRepairKit(s)); assert.equal(s.car.condition, 60); assert(!useRepairKit(s)); s.clock.day++; s.car.speed = 2; assert(!useRepairKit(s)); s.car.speed = 0; assert(useRepairKit(s)); assert.equal(s.car.condition, 80);
});
test("reloading the career does not replenish the daily repair kit", () => {
  const s = fixture(), store = storage(); s.operations.career.xp = 250; s.car.condition = 20; assert(useRepairKit(s)); assert(saveCareer(s, store)); const r = fixture(); assert(restoreCareer(r, store)); assert(!useRepairKit(r)); r.clock.day++; assert(useRepairKit(r)); assert.equal(r.car.condition, 60);
});
