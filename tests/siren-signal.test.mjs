import test from "node:test";
import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
const available =
  spawnSync("ffmpeg", ["-version"], { stdio: "ignore" }).status === 0;
test(
  "each distributed siren MP3 contains audible decoded samples, not just a valid header",
  { skip: !available },
  () => {
    for (const kind of ["perseguicao", "parada", "passagem"]) {
      const pcm = execFileSync("ffmpeg", [
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        `assets/audio/${kind}.mp3`,
        "-ac",
        "1",
        "-f",
        "f32le",
        "pipe:1",
      ]);
      let sum = 0,
        peak = 0;
      for (let i = 0; i < pcm.length; i += 4) {
        const v = pcm.readFloatLE(i);
        sum += v * v;
        peak = Math.max(peak, Math.abs(v));
      }
      assert(
        Math.sqrt(sum / (pcm.length / 4)) > 0.02,
        `${kind}: amostras silenciosas`,
      );
      assert(peak > 0.05 && peak < 1, `${kind}: pico inválido`);
    }
  },
);
