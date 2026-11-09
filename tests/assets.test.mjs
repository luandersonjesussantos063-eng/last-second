import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
function glb(file) {
  const b = readFileSync(file);
  assert.equal(b.readUInt32LE(0), 0x46546c67);
  assert.equal(b.readUInt32LE(8), b.length);
  return JSON.parse(b.subarray(20, 20 + b.readUInt32LE(12)).toString());
}
test("mobile and desktop models preserve the cockpit and three named instrument meshes", () => {
  const original = glb("models/cockpit_scifi.glb");
  for (const name of ["mobile", "desktop"]) {
    const model = glb("models/cockpit-" + name + ".glb");
    assert.equal(model.meshes.length, original.meshes.length);
    assert.equal(
      model.meshes.reduce((n, m) => n + m.primitives.length, 0),
      13,
    );
    for (const label of ["ScreenLeft", "ScreenMid", "ScreenRight"])
      assert(model.nodes.some((n) => n.name?.includes(label)));
    assert(
      statSync("models/cockpit-" + name + ".glb").size <
        statSync("models/cockpit_scifi.glb").size * 0.6,
    );
  }
});
test("offline engine and decoder match the recorded release checksums", () => {
  const manifest = JSON.parse(readFileSync("vendor/manifest.json", "utf8"));
  assert.equal(manifest.version, "three@0.186.0");
  for (const [file, hash] of Object.entries(manifest.files))
    assert.equal(
      createHash("sha256")
        .update(readFileSync("vendor/" + file))
        .digest("hex"),
      hash,
      file,
    );
  assert(
    !/https:\/\/(?:esm.sh|www.gstatic.com)/.test(
      readFileSync("main.js", "utf8"),
    ),
  );
});
