import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { uniformForRole, UNIFORMS } from "../crew-roles.js";
import { GameAudio, acousticPosition } from "../game-audio.js";

test("jobs select distinct police, control, mechanical, medical and supply uniforms", () => {
  assert.equal(uniformForRole("PILOTO"), "police");
  assert.equal(UNIFORMS.police.gear, "helmet");
  for (const role of ["CONTROLE DE VOO", "SENSORES", "COMUNICAÇÕES"])
    assert.equal(uniformForRole(role), "control");
  assert.equal(UNIFORMS.control.gear, "headset");
  assert.equal(uniformForRole("ENGENHARIA"), "mechanic");
  assert.equal(uniformForRole("MEDICINA"), "medical");
  assert.equal(uniformForRole("SUPRIMENTOS"), "supplies");
});
test("positional sound falls with distance and pans according to the listener's direction", () => {
  const near = acousticPosition({ x: 0, y: 0, z: 0 }, { x: 3, y: 0, z: 0 });
  const far = acousticPosition({ x: 0, y: 0, z: 0 }, { x: 60, y: 0, z: 0 });
  assert(near.gain > far.gain * 15);
  assert(near.pan > 0);
  assert(acousticPosition({ x: 0, z: 0 }, { x: 3, z: 0 }, Math.PI).pan < 0);
  assert.equal(acousticPosition({ x: 0, z: 0 }, { x: 100, z: 0 }).gain, 0);
});
function fakeContext() {
  const sources = [],
    param = () => ({
      value: 0,
      setValueAtTime() {},
      exponentialRampToValueAtTime() {},
      setTargetAtTime() {},
    });
  const node = () => ({
    gain: param(),
    frequency: param(),
    pan: param(),
    Q: param(),
    threshold: param(),
    knee: param(),
    ratio: param(),
    playbackRate: param(),
    connect() {},
    disconnect() {},
    start() {},
    stop() {},
  });
  return {
    state: "running",
    currentTime: 1,
    sampleRate: 100,
    destination: node(),
    sources,
    createGain: node,
    createDynamicsCompressor: node,
    createBiquadFilter: node,
    createStereoPanner: node,
    createBuffer: () => ({ getChannelData: () => new Float32Array(100) }),
    createBufferSource: () => {
      const n = node();
      delete n.frequency;
      sources.push(n);
      return n;
    },
    createOscillator: () => {
      const n = node();
      delete n.playbackRate;
      sources.push(n);
      return n;
    },
  };
}
test("audio uses one fixed loop pool, caps transient voices and releases finished nodes", () => {
  const audio = new GameAudio(),
    ctx = fakeContext();
  audio.activate(ctx);
  audio.activate(ctx);
  assert.equal(audio.loops.length, 6);
  for (let i = 0; i < 100; i++) audio.emit("step");
  assert.equal(audio.voices, 24);
  assert.equal(audio.events.step, 24);
  for (const source of ctx.sources) source.onended?.();
  assert.equal(audio.voices, 0);
  audio.toggleMute();
  audio.emit("step");
  assert.equal(audio.voices, 0);
  audio.setVolume(4);
  assert.equal(audio.volume, 1);
  audio.setVolume(-1);
  assert.equal(audio.volume, 0);
});
test("both sampled mechanical effects and synthesised console/siren tones can be created", () => {
  const audio = new GameAudio(),
    ctx = fakeContext();
  audio.activate(ctx);
  for (const kind of [
    "step",
    "servo",
    "latch",
    "hatch",
    "repair",
    "scan",
    "ui",
    "impact",
    "boarding",
    "siren",
  ])
    assert.doesNotThrow(() => audio.emit(kind));
  assert.equal(audio.voices, 10);
  for (const source of ctx.sources) source.onended?.();
  assert.equal(audio.voices, 0);
});
test("an unavailable audio device cannot prevent the game from updating", () => {
  const audio = new GameAudio();
  audio.activate({
    createGain() {
      throw Error("No device");
    },
  });
  assert.equal(audio.ctx, null);
  assert.equal(audio.output, null);
  assert.doesNotThrow(() => audio.update(0.1, {}));
});
test("all game module URLs carry the same release to avoid mixing cached versions", () => {
  const { version } = JSON.parse(readFileSync("package.json", "utf8"));
  assert(readFileSync("index.html", "utf8").includes(`main.js?v=${version}`));
  for (const file of readdirSync(".").filter((f) => f.endsWith(".js"))) {
    const text = readFileSync(file, "utf8");
    for (const match of text.matchAll(
      /(?:from\s*|import\s*\(\s*)["'](\.\/(?!vendor\/)[^"']+\.js(?:\?[^"']+)?)["']/g,
    ))
      assert(match[1].endsWith("?v=" + version), `${file}: ${match[1]}`);
  }
});
