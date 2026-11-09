import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
const binary = readFileSync("assets/models/prf-agent.glb"),
  manifest = JSON.parse(readFileSync("assets/models/manifest.json", "utf8"));
const gltf = JSON.parse(
  binary.subarray(20, 20 + binary.readUInt32LE(12)).toString(),
);
test("the distributed character is a licensed, self-contained skinned GLB within the mobile download budget", () => {
  assert.equal(binary.toString("ascii", 0, 4), "glTF");
  assert.equal(binary.readUInt32LE(4), 2);
  assert.equal(binary.readUInt32LE(8), binary.length);
  assert.equal(
    createHash("sha256").update(binary).digest("hex"),
    manifest.sha256,
  );
  assert.equal(binary.length, manifest.bytes);
  assert(binary.length < 5 * 1024 * 1024);
  assert(manifest.triangles < 15000);
  assert.equal(manifest.license, "MIT");
  assert(
    readFileSync(
      "assets/models/LICENSE-Microsoft-Rocketbox.txt",
      "utf8",
    ).includes("Copyright (c) 2020 Microsoft"),
  );
  assert(gltf.skins[0].joints.length >= 40);
  assert(
    gltf.meshes.some((m) =>
      m.primitives.some(
        (p) =>
          p.attributes.JOINTS_0 !== undefined &&
          p.attributes.WEIGHTS_0 !== undefined,
      ),
    ),
  );
  assert(gltf.images.length >= 4);
  assert(gltf.images.every((i) => i.bufferView !== undefined && !i.uri));
  assert(gltf.buffers.every((b) => !b.uri));
  assert(
    gltf.materials.some(
      (m) => m.normalTexture && m.pbrMetallicRoughness.baseColorTexture,
    ),
  );
});
test("locomotion and interaction clips contain sampled bone rotations with no horizontal root motion", () => {
  assert.deepEqual(
    gltf.animations.map((a) => a.name).sort(),
    ["Idle", "Walk", "Run", "Documents", "Seated", "Signal"].sort(),
  );
  const jsonBytes = binary.readUInt32LE(12),
    binStart = 20 + jsonBytes + 8;
  function samples(index) {
    const a = gltf.accessors[index],
      v = gltf.bufferViews[a.bufferView];
    assert.equal(a.componentType, 5126);
    const width = { SCALAR: 1, VEC3: 3, VEC4: 4 }[a.type];
    return Array.from({ length: a.count }, (_, i) =>
      Array.from({ length: width }, (_, j) =>
        binary.readFloatLE(
          binStart +
            (v.byteOffset ?? 0) +
            (a.byteOffset ?? 0) +
            i * (v.byteStride ?? width * 4) +
            j * 4,
        ),
      ),
    );
  }
  for (const name of ["Walk", "Run"]) {
    const clip = gltf.animations.find((a) => a.name === name);
    const rotating = clip.channels.filter((c) => c.target.path === "rotation");
    assert(
      rotating.some((c) => {
        const values = samples(clip.samplers[c.sampler].output);
        return values.some((v) =>
          v.some((n, j) => Math.abs(n - values[0][j]) > 0.05),
        );
      }),
      name + " must actually animate bones",
    );
    const roots = gltf.scenes[0].nodes;
    for (const c of clip.channels.filter(
      (c) => roots.includes(c.target.node) && c.target.path === "translation",
    )) {
      const values = samples(clip.samplers[c.sampler].output);
      assert(
        values.every(
          (v) =>
            Math.abs(v[0] - values[0][0]) < 1e-4 &&
            Math.abs(v[2] - values[0][2]) < 1e-4,
        ),
      );
    }
  }
});
