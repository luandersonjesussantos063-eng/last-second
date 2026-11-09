import test from "node:test";
import assert from "node:assert/strict";
import { footstepSamples, RoadAudio } from "../road-audio.js";
import { SIREN_COMMANDS } from "../siren-config.js";
test("recorded police commands are distinct and use the expected playback modes", () => {
  assert.deepEqual(Object.keys(SIREN_COMMANDS), [
    "perseguicao",
    "parada",
    "passagem",
  ]);
  assert(SIREN_COMMANDS.perseguicao.loop);
  assert.equal(SIREN_COMMANDS.perseguicao.seconds, 0);
  assert(SIREN_COMMANDS.parada.loop);
  assert(SIREN_COMMANDS.parada.seconds > 3);
  assert(!SIREN_COMMANDS.passagem.loop);
  assert.equal(SIREN_COMMANDS.passagem.seconds, 0);
  assert.equal(
    new Set(Object.values(SIREN_COMMANDS).map((c) => c.url)).size,
    3,
  );
});
test("shoe contact has a soft onset, bounded samples and multiple variations", () => {
  const a = footstepSamples(48000, 0),
    b = footstepSamples(48000, 1);
  assert.equal(a.length, 12000);
  assert.notDeepEqual(a, b);
  const peak = Math.max(...a.map(Math.abs));
  assert(peak > 0.02 && peak < 0.5);
  assert(Math.max(...a.slice(0, 96).map(Math.abs)) < peak * 0.6);
});
test("audio preferences are bounded and audio unavailable does not break simulation", () => {
  const audio = new RoadAudio();
  audio.setVolume(5);
  assert.equal(audio.volume, 1);
  audio.setVolume(-2);
  assert.equal(audio.volume, 0);
  assert.doesNotThrow(() => audio.update({}));
  assert.doesNotThrow(() => audio.emit("step"));
});
