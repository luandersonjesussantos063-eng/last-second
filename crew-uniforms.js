import * as THREE from "./vendor/engine.js";
import { UNIFORMS, uniformForRole } from "./crew-roles.js?v=1.14.0";

export function createUniformedCrew(root, crew, dark, blue) {
  const parts = [],
    white = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.7 });
  const skin = new THREE.MeshStandardMaterial({
    color: 0xc6a18a,
    roughness: 0.8,
  });
  const visor = new THREE.MeshStandardMaterial({
    color: 0x315d79,
    metalness: 0.65,
    roughness: 0.2,
  });
  const armor = new THREE.MeshStandardMaterial({
    color: 0xc7d3de,
    metalness: 0.4,
    roughness: 0.5,
  });
  const gold = new THREE.MeshStandardMaterial({
    color: 0xdfb755,
    metalness: 0.35,
    roughness: 0.5,
  });
  const profiles = crew.map((p) => uniformForRole(p.role));
  function batch(
    geometry,
    material,
    x,
    y,
    z = 0,
    swing = 0,
    profile = null,
    colors = null,
    arm = false,
  ) {
    const indices = crew
      .map((_, i) => i)
      .filter((i) => !profile || profiles[i] === profile);
    if (!indices.length) return;
    const instances = new THREE.InstancedMesh(
      geometry,
      material,
      indices.length,
    );
    instances.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    instances.frustumCulled = false;
    if (colors)
      indices.forEach((index, i) =>
        instances.setColorAt(
          i,
          new THREE.Color(colors(UNIFORMS[profiles[index]])),
        ),
      );
    root.add(instances);
    parts.push({ instances, x, y, z, swing, profile, arm, indices });
  }
  const rounded = (w, h, d) =>
    new THREE.RoundedBoxGeometry(w, h, d, 1, Math.min(w, h, d) * 0.16);
  for (const [kind, profile] of Object.entries(UNIFORMS)) {
    const c = document.createElement("canvas");
    c.width = 512;
    c.height = 256;
    const ctx = c.getContext("2d");
    ctx.fillStyle = "#" + profile.color.toString(16).padStart(6, "0");
    ctx.fillRect(0, 0, 512, 256);
    for (const x of [0, 256]) {
      ctx.fillStyle = profile.trim;
      ctx.fillRect(x + 20, 52, 216, 18);
      ctx.fillStyle = "#11202b";
      ctx.fillRect(x + 33, 99, 190, 55);
      ctx.fillStyle = "#f1f5f8";
      ctx.font = "bold 22px Arial";
      ctx.textAlign = "center";
      ctx.fillText(
        kind === "police" ? "POLÍCIA" : profile.name,
        x + 128,
        124,
        180,
      );
      ctx.font = "bold 15px Arial";
      ctx.fillText(
        kind === "police" ? "ESPACIAL" : "ALPHA 01",
        x + 128,
        145,
        180,
      );
      ctx.strokeStyle = profile.trim;
      ctx.lineWidth = 3;
      ctx.strokeRect(x + 34, 175, 64, 42);
      ctx.strokeRect(x + 158, 175, 64, 42);
      if (kind === "medical") {
        ctx.fillStyle = "#3ed1b4";
        ctx.fillRect(x + 118, 74, 20, 50);
        ctx.fillRect(x + 103, 89, 50, 20);
      }
    }
    const map = new THREE.CanvasTexture(c);
    map.colorSpace = THREE.SRGBColorSpace;
    const material = new THREE.MeshStandardMaterial({ map, roughness: 0.75 });
    batch(
      new THREE.CapsuleGeometry(0.23, 0.45, 3, 10),
      material,
      0,
      1.16,
      0,
      0,
      kind,
    );
  }
  batch(new THREE.SphereGeometry(0.18, 10, 6), skin, 0, 1.76);
  for (const side of [-1, 1]) {
    batch(
      new THREE.CapsuleGeometry(0.078, 0.48, 3, 6),
      white,
      side * 0.31,
      1.13,
      0,
      side,
      null,
      (p) => p.color,
      true,
    );
    batch(
      new THREE.CapsuleGeometry(0.1, 0.52, 3, 6),
      white,
      side * 0.13,
      0.44,
      0,
      -side,
      null,
      (p) => p.trousers,
    );
    batch(rounded(0.2, 0.18, 0.32), dark, side * 0.13, 0.1, 0.06, -side);
  }
  batch(
    new THREE.TorusGeometry(0.225, 0.035, 4, 10).rotateX(Math.PI / 2),
    dark,
    0,
    0.87,
  );
  batch(rounded(0.3, 0.08, 0.35), blue, 0, 1.0, 0.4, 2);
  // Police armour, sealed helmet and tinted visor are visible silhouettes, not just colours.
  batch(new THREE.SphereGeometry(0.215, 12, 8), armor, 0, 1.79, 0, 0, "police");
  batch(
    new THREE.SphereGeometry(0.21, 12, 6).scale(1, 0.45, 1.04),
    visor,
    0,
    1.8,
    0.025,
    0,
    "police",
  );
  batch(rounded(0.37, 0.2, 0.09), armor, 0, 1.3, 0.22, 0, "police");
  batch(rounded(0.07, 0.09, 0.025), gold, -0.1, 1.32, 0.28, 0, "police");
  for (const side of [-1, 1])
    batch(rounded(0.2, 0.13, 0.29), armor, side * 0.29, 1.43, 0, 0, "police");
  // Control-room operators wear a headset with ear cups and microphone.
  batch(
    new THREE.TorusGeometry(0.205, 0.022, 4, 12, Math.PI),
    dark,
    0,
    1.76,
    0,
    0,
    "control",
  );
  for (const side of [-1, 1])
    batch(
      new THREE.SphereGeometry(0.06, 6, 4),
      dark,
      side * 0.2,
      1.75,
      0,
      0,
      "control",
    );
  batch(rounded(0.16, 0.02, 0.02), dark, 0.14, 1.67, 0.15, 0, "control");
  // Mechanics carry tool pouches and a hard hat with a protective brim.
  batch(
    new THREE.SphereGeometry(0.23, 10, 5, 0, Math.PI * 2, 0, Math.PI / 2),
    gold,
    0,
    1.82,
    0,
    0,
    "mechanic",
  );
  batch(
    new THREE.TorusGeometry(0.23, 0.025, 4, 10).rotateX(Math.PI / 2),
    gold,
    0,
    1.82,
    0,
    0,
    "mechanic",
  );
  for (const side of [-1, 1])
    batch(
      rounded(0.13, 0.19, 0.12),
      dark,
      side * 0.19,
      0.85,
      0.2,
      0,
      "mechanic",
    );
  batch(rounded(0.06, 0.28, 0.07), armor, 0.23, 0.89, 0.28, 0, "mechanic");
  batch(
    new THREE.SphereGeometry(0.19, 10, 5, 0, Math.PI * 2, 0, Math.PI / 2),
    white,
    0,
    1.84,
    0,
    0,
    "medical",
  );
  batch(rounded(0.15, 0.23, 0.1), gold, 0.15, 0.9, 0.21, 0, "supplies");
  return { parts, profiles };
}
