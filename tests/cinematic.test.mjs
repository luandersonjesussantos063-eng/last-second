import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import * as T from "../vendor/engine.js";

test("motor empacota pós-processamento local sem CDN", () => {
  for (const name of [
    "EffectComposer", "RenderPass", "OutputPass",
    "UnrealBloomPass", "SSAOPass", "SSRPass", "MeshPhysicalMaterial"
  ]) assert.equal(typeof T[name], "function", name);
  assert.equal(typeof T.PCFSoftShadowMap, "number");
});

test("o modo Cinemático é opcional, preserva móvel e tem proteção contra erro de GPU", () => {
  const source = readFileSync("visual-effects.js", "utf8");
  const main = readFileSync("main.js", "utf8");
  assert.match(source, /if \(composer \|\| mobile \|\| unavailable\) return/);
  assert.match(source, /reflections\.resolutionScale = 0\.5/);
  assert.match(source, /reflections\.enabled = enabled && wet/);
  assert.match(source, /composer\.render\(deltaSeconds\)/);
  assert.match(source, /renderer\.render\(scene, camera\)/);
  assert.match(source, /new T\.SSAOPass/);
  assert.match(source, /new T\.UnrealBloomPass/);
  assert.match(main, /quality === "cinematic"/);
  assert.match(main, /if \(mobile\)/);
  assert.match(main, /visualEffects\.render\(dt\)/);
});

test("sol acompanha jogador, faróis e sombras têm controle de qualidade", () => {
  const environment = readFileSync("day-night.js", "utf8");
  assert.match(environment, /sun\.target\.position\.set\(focusX, 0, focusZ\)/);
  assert.match(environment, /state\.setQuality = /);
  assert.match(environment, /shadow\.mapSize\.set\(size, size\)/);
  assert.match(environment, /PointLight\(0xffeed2/);
  assert.match(readFileSync("main.js","utf8"), /PCFSoftShadowMap/);
});

test("asfalto tem mapa de normais e rugosidade e viaturas têm verniz PBR", () => {
  const graphics = readFileSync("road-graphics.js", "utf8");
  const road = readFileSync("road-world.js", "utf8");
  assert.match(graphics, /function createMicroMaps\(albedo\)/);
  assert.match(graphics, /roadNormal: details\.normal/);
  assert.match(road, /mat\.asphalt\.normalMap = maps\.roadNormal/);
  assert.match(road, /mat\.asphalt\.roughnessMap = maps\.roadRoughness/);
  assert.match(road, /new T\.MeshPhysicalMaterial/);
  assert.match(road, /clearcoat: 0\.75/);
});
