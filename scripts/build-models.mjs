import { spawnSync } from "node:child_process";
import { mkdtemp, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = fileURLToPath(new URL("../", import.meta.url)),
  cli = path.join(root, "node_modules/@gltf-transform/cli/bin/cli.js"),
  dir = await mkdtemp(path.join(tmpdir(), "last-second-model-"));
const report = {
  source: "models/cockpit_scifi.glb",
  sourceBytes: (await stat(path.join(root, "models/cockpit_scifi.glb"))).size,
  profiles: {},
};
function run(args) {
  const result = spawnSync(process.execPath, [cli, ...args], {
    cwd: root,
    stdio: "inherit",
    env: { ...process.env, VIPS_CONCURRENCY: "2" },
  });
  if (result.status !== 0) throw Error("Otimização do modelo falhou.");
}
try {
  for (const [name, size] of [
    ["mobile", 1024],
    ["desktop", 2048],
  ]) {
    const intermediate = path.join(dir, name + ".glb"),
      out = "models/cockpit-" + name + ".glb";
    run([
      "resize",
      report.source,
      intermediate,
      "--width",
      String(size),
      "--height",
      String(size),
    ]);
    run(["webp", intermediate, out, "--quality", "90"]);
    report.profiles[name] = {
      file: out,
      bytes: (await stat(path.join(root, out))).size,
      maxTextureSize: size,
    };
  }
  await writeFile(
    path.join(root, "models/optimized-manifest.json"),
    JSON.stringify(report, null, 2) + "\n",
  );
  console.log(JSON.stringify(report, null, 2));
} finally {
  await rm(dir, { recursive: true, force: true });
}
