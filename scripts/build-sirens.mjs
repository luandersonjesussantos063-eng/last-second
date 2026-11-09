import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
const source = process.argv[2];
if (!source)
  throw Error(
    "Informe o áudio original: npm run build:sirens -- /caminho/videoplayback.m4a",
  );
const directory = new URL("../assets/audio/", import.meta.url);
mkdirSync(directory, { recursive: true });
function levels(pcm) {
  let sum = 0,
    peak = 0;
  for (let i = 0; i < pcm.length; i += 4) {
    const v = pcm.readFloatLE(i);
    sum += v * v;
    peak = Math.max(peak, Math.abs(v));
  }
  return { rms: Math.sqrt(sum / (pcm.length / 4)), peak };
}
const manifest = {
  source: "videoplayback.m4a",
  source_sha256: createHash("sha256")
    .update(readFileSync(source))
    .digest("hex"),
  authorization:
    "Áudio fornecido pelo usuário para uso no jogo nesta conversa.",
  conversion:
    "Recorte com atrim e timestamps zerados antes dos fades. PCM e MP3 decodificado verificados contra silêncio.",
  clips: {},
};
for (const [key, start, end] of [
  ["perseguicao", 5.56, 6.72],
  ["parada", 9.13, 10.98],
  ["passagem", 6.98, 8.1],
]) {
  const duration = end - start;
  // Fades must run on the trimmed timeline, not on the original timestamps.
  const filter = `atrim=start=${start}:end=${end},asetpts=PTS-STARTPTS,highpass=f=420,lowpass=f=6000,afade=t=in:st=0:d=0.015,afade=t=out:st=${duration - 0.02}:d=0.02`;
  const pcm = execFileSync("ffmpeg", [
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    source,
    "-af",
    filter,
    "-ac",
    "1",
    "-ar",
    "44100",
    "-f",
    "f32le",
    "pipe:1",
  ]);
  const raw = levels(pcm);
  if (raw.rms < 0.005 || raw.peak < 0.02)
    throw Error(`${key}: recorte original silencioso`);
  const gain = Math.min(10 ** (-18 / 20) / raw.rms, 10 ** (-2 / 20) / raw.peak);
  const target = fileURLToPath(new URL(`${key}.mp3`, directory));
  execFileSync(
    "ffmpeg",
    [
      "-y",
      "-hide_banner",
      "-loglevel",
      "error",
      "-f",
      "f32le",
      "-ac",
      "1",
      "-ar",
      "44100",
      "-i",
      "pipe:0",
      "-af",
      `volume=${gain}`,
      "-c:a",
      "libmp3lame",
      "-b:a",
      "64k",
      "-map_metadata",
      "-1",
      target,
    ],
    { input: pcm },
  );
  const decoded = execFileSync("ffmpeg", [
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    target,
    "-ac",
    "1",
    "-f",
    "f32le",
    "pipe:1",
  ]);
  const measured = levels(decoded);
  if (measured.rms < 0.02 || measured.peak < 0.05)
    throw Error(`${key}: MP3 silencioso após conversão`);
  const bytes = readFileSync(target);
  manifest.clips[key] = {
    file: `${key}.mp3`,
    source_start: start,
    source_end: end,
    bytes: bytes.length,
    sha256: createHash("sha256").update(bytes).digest("hex"),
    decoded_rms_dbfs: Number((20 * Math.log10(measured.rms)).toFixed(2)),
    decoded_peak_dbfs: Number((20 * Math.log10(measured.peak)).toFixed(2)),
  };
  console.log(
    `${key}: RMS ${manifest.clips[key].decoded_rms_dbfs} dBFS; pico ${manifest.clips[key].decoded_peak_dbfs} dBFS`,
  );
}
writeFileSync(
  new URL("manifest.json", directory),
  JSON.stringify(manifest, null, 2) + "\n",
);
