import test from "node:test";
import assert from "node:assert/strict";
import { footstepSamples, RoadAudio } from "../road-audio.js";
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
