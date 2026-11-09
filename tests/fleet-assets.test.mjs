import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
function glb(file) {
  const bytes = readFileSync("assets/models/" + file);
  assert.equal(bytes.toString("ascii", 0, 4), "glTF");
  assert.equal(bytes.readUInt32LE(8), bytes.length);
  return {
    bytes,
    json: JSON.parse(
      bytes.subarray(20, 20 + bytes.readUInt32LE(12)).toString(),
    ),
  };
}
test("police squad asset has its own uniform, riding/radio poses and optional duty equipment", () => {
  const m = JSON.parse(
      readFileSync("assets/models/officer-manifest.json", "utf8"),
    ),
    { bytes, json } = glb(m.file);
  assert.equal(createHash("sha256").update(bytes).digest("hex"), m.sha256);
  assert(bytes.length < 3 * 1024 * 1024);
  assert(m.triangles < 12000);
  assert.equal(m.license, "MIT");
  for (const name of ["Idle", "Walk", "Documents", "Signal", "Riding", "Radio"])
    assert(json.animations.some((a) => a.name === name));
  for (const part of ["PRF_Officer", "SafetyVest", "MotoHelmet", "HandRadio"])
    assert(
      json.nodes.some((n) => n.name?.startsWith(part)),
      part,
    );
  assert(!json.nodes.some((n) => n.name?.startsWith("HeldRifle")));
  assert(json.skins[0].joints.length >= 40);
});
test("original police vehicles have real wheel nodes, warning LEDs and self-contained PBR materials", () => {
  const manifest = JSON.parse(
    readFileSync("assets/models/fleet-manifest.json", "utf8"),
  );
  for (const [name, metadata] of Object.entries(manifest.files)) {
    const { bytes, json } = glb(name);
    assert.equal(
      createHash("sha256").update(bytes).digest("hex"),
      metadata.sha256,
    );
    assert(bytes.length < 2 * 1024 * 1024);
    assert(metadata.triangles < 20000);
    const wheels = json.nodes.filter((n) =>
      /^Wheel(?:FL|FR|RL|RR|F|R)$/.test(n.name),
    );
    assert.equal(wheels.length, name.includes("suv") ? 4 : 2);
    assert(json.nodes.some((n) => n.name?.startsWith("FlashRed")));
    assert(json.nodes.some((n) => n.name?.startsWith("FlashBlue")));
    assert(
      json.materials.some((m) => m.pbrMetallicRoughness?.metallicFactor > 0.5),
    );
    assert(json.buffers.every((b) => !b.uri));
  }
});
test("the commander rifle has distinct held/slung skinned parts and matching carry clips", () => {
  const { json } = glb("prf-agent.glb");
  for (const part of ["HeldRifle", "SlungRifle"]) {
    const nodes = json.nodes.filter((n) => n.name?.startsWith(part));
    assert(nodes.length >= 2);
    assert(nodes.every((n) => n.skin !== undefined));
  }
  for (const clip of ["RifleIdle", "RifleWalk", "RifleRun"])
    assert(json.animations.some((a) => a.name === clip));
});
