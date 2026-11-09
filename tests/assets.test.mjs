import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
import path from "node:path";
function runtime() {
  const files = new Set();
  function visit(name) {
    if (files.has(name)) return;
    files.add(name);
    const source = readFileSync(name, "utf8");
    for (const m of source.matchAll(
      /(?:from\s*|import\s*\(\s*)["'](\.\/[^"']+)["']/g,
    ))
      visit(path.normalize(path.join(path.dirname(name), m[1].split("?")[0])));
  }
  visit("main.js");
  return [...files];
}
test("the road entrypoint loads only the current local modules and no space assets", () => {
  const files = runtime();
  assert.deepEqual(
    files.sort(),
    [
      "main.js",
      "game-utils.js",
      "road-world.js",
      "road-graphics.js",
      "base-layout.js",
      "blitz-sim.js",
      "reception-sim.js",
      "road-sim.js",
      "road-audio.js",
      "siren-config.js",
      "vendor/engine.js",
    ].sort(),
  );
  assert(files.reduce((sum, f) => sum + statSync(f).size, 0) < 750000);
  for (const f of files.filter((f) => !f.startsWith("vendor/")))
    assert(
      !/\.(glb|wasm)|hangar|planet|DRACOLoader|GLTFLoader|https:\/\//i.test(
        readFileSync(f, "utf8"),
      ),
      f,
    );
});
test("published engine matches recorded checksums and no longer exports model decoders", async () => {
  const manifest = JSON.parse(readFileSync("vendor/manifest.json", "utf8"));
  assert.deepEqual(Object.keys(manifest.files).sort(), [
    "LICENSE-three.txt",
    "engine.js",
  ]);
  for (const [f, hash] of Object.entries(manifest.files))
    assert.equal(
      createHash("sha256")
        .update(readFileSync("vendor/" + f))
        .digest("hex"),
      hash,
    );
  const engine = await import("../vendor/engine.js");
  assert.equal(engine.GLTFLoader, undefined);
  assert.equal(engine.DRACOLoader, undefined);
  assert(engine.RoundedBoxGeometry);
});
test("page and game module imports share one release version", () => {
  const { version } = JSON.parse(readFileSync("package.json", "utf8"));
  assert(readFileSync("index.html", "utf8").includes("main.js?v=" + version));
  for (const f of runtime().filter((f) => !f.startsWith("vendor/")))
    for (const m of readFileSync(f, "utf8").matchAll(
      /(?:from\s*|import\s*\(\s*)["'](\.\/[^"']+)["']/g,
    ))
      assert(m[1].endsWith("?v=" + version), f + ": " + m[1]);
});
test("authorised source clips retain provenance, integrity and a small download budget", () => {
  const manifest = JSON.parse(
    readFileSync("assets/audio/manifest.json", "utf8"),
  );
  assert.equal(manifest.source, "videoplayback.m4a");
  let total = 0;
  for (const c of Object.values(manifest.clips)) {
    const bytes = readFileSync("assets/audio/" + c.file);
    total += bytes.length;
    assert.equal(createHash("sha256").update(bytes).digest("hex"), c.sha256);
    assert(c.source_end > c.source_start);
    assert(bytes.length > 4000);
  }
  assert(total < 40000);
});
