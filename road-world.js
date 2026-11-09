import * as T from "./vendor/engine.js?v=2.3.0";
import { createSurfaceMaps, createPrfBase } from "./road-graphics.js?v=2.3.0";

function labelTexture(
  text,
  {
    background = "#122843",
    color = "#f5cc42",
    width = 512,
    height = 128,
    font = 48,
  } = {},
) {
  const c = document.createElement("canvas");
  c.width = width;
  c.height = height;
  const x = c.getContext("2d");
  x.fillStyle = background;
  x.fillRect(0, 0, width, height);
  x.fillStyle = color;
  x.font = `bold ${font}px Arial`;
  x.textAlign = "center";
  x.textBaseline = "middle";
  x.fillText(text, width / 2, height / 2, width - 20);
  const map = new T.CanvasTexture(c);
  map.colorSpace = T.SRGBColorSpace;
  return map;
}
function mergeGroup(group) {
  const groups = new Map();
  for (const m of [...group.children]) {
    if (!m.isMesh || m.userData.dynamic) continue;
    m.updateMatrix();
    const g = m.geometry.index ? m.geometry.toNonIndexed() : m.geometry.clone();
    g.applyMatrix4(m.matrix);
    if (!groups.has(m.material)) groups.set(m.material, []);
    groups.get(m.material).push(g);
    group.remove(m);
    m.geometry.dispose();
  }
  for (const [material, geometries] of groups) {
    group.add(new T.Mesh(T.mergeGeometries(geometries), material));
    geometries.forEach((g) => g.dispose());
  }
}
const rounded = (w, h, d) =>
  new T.RoundedBoxGeometry(w, h, d, 1, Math.min(0.16, w / 6, h / 6, d / 6));
function addMesh(parent, geometry, material, x, y, z) {
  const m = new T.Mesh(geometry, material);
  m.position.set(x, y, z);
  parent.add(m);
  return m;
}
function box(parent, material, x, y, z, w, h, d) {
  return addMesh(parent, rounded(w, h, d), material, x, y, z);
}

export function createVehicle({
  police = false,
  color = 0x4878a0,
  plate = "SIM-0000",
} = {}) {
  const group = new T.Group();
  const paint = new T.MeshStandardMaterial({
    color: police ? 0x152a4c : color,
    metalness: 0.38,
    roughness: 0.38,
  });
  const rubber = new T.MeshStandardMaterial({
    color: 0x182027,
    roughness: 0.86,
  });
  const glass = new T.MeshStandardMaterial({
    color: 0x264552,
    metalness: 0.38,
    roughness: 0.18,
  });
  const chrome = new T.MeshStandardMaterial({
    color: 0x98a4ac,
    metalness: 0.75,
    roughness: 0.27,
  });
  const yellow = new T.MeshStandardMaterial({
    color: 0xf3c83f,
    roughness: 0.5,
  });
  const light = new T.MeshBasicMaterial({ color: 0xfff0cc }),
    red = new T.MeshBasicMaterial({ color: 0xb73532 });
  box(group, rubber, 0, 0.49, 0, 1.88, 0.35, 4.65);
  box(group, paint, 0, 0.93, 0, 1.96, 0.62, 4.55);
  // A pickup-style patrol: four-door cab, bonnet, and rear cargo bed.
  box(group, paint, 0, 1.42, 0.32, 1.82, 0.67, 2.25);
  box(group, glass, 0, 1.48, 0.38, 1.84, 0.46, 2.04);
  box(group, paint, 0, 1.81, 0.32, 1.87, 0.13, 2.32);
  for (const side of [-1, 1]) {
    box(group, paint, side * 0.91, 1.48, 0.27, 0.07, 0.6, 0.13);
    box(group, paint, side * 0.91, 1.48, -0.67, 0.07, 0.6, 0.11);
    box(group, paint, side * 0.91, 1.48, 1.28, 0.07, 0.6, 0.11);
    box(group, paint, side * 0.95, 1.18, -1.6, 0.12, 0.4, 1.22);
    box(group, chrome, side * 1.08, 1.34, 1.04, 0.24, 0.16, 0.32);
    for (const z of [-0.2, 0.9])
      box(group, chrome, side * 0.99, 1.05, z, 0.04, 0.07, 0.24);
    box(group, light, side * 0.68, 0.98, 2.285, 0.46, 0.2, 0.06);
    box(group, red, side * 0.78, 0.96, -2.29, 0.23, 0.33, 0.06);
    if (police) box(group, yellow, side * 0.992, 0.97, -0.1, 0.025, 0.24, 4.1);
  }
  box(group, rubber, 0, 1.1, -1.62, 1.63, 0.1, 1.1);
  box(group, paint, 0, 1.16, -2.16, 1.85, 0.4, 0.14);
  box(group, chrome, 0, 0.68, 2.32, 1.85, 0.18, 0.16);
  box(group, chrome, 0, 0.65, -2.33, 1.85, 0.16, 0.18);
  box(group, rubber, 0, 0.98, 2.3, 0.75, 0.2, 0.07);
  const wheelGroups = [];
  for (const side of [-1, 1])
    for (const z of [-1.48, 1.45]) {
      const wheel = new T.Object3D();
      wheel.position.set(side * 0.98, 0.43, z);
      wheel.rotation.order = "YXZ";
      wheelGroups.push(wheel);
    }
  const plateMat = new T.MeshBasicMaterial({
    map: labelTexture(plate, {
      background: "#e2e7e4",
      color: "#263644",
      width: 256,
      height: 64,
      font: 36,
    }),
  });
  for (const sign of [-1, 1])
    addMesh(
      group,
      new T.PlaneGeometry(0.6, 0.18),
      plateMat,
      0,
      0.77,
      sign * 2.42,
    ).rotation.y = sign < 0 ? Math.PI : 0;
  if (police) {
    const marking = new T.MeshBasicMaterial({
      map: labelTexture("PRF", { font: 82 }),
    });
    for (const side of [-1, 1])
      addMesh(
        group,
        new T.PlaneGeometry(1.0, 0.47),
        marking,
        side * 1.015,
        1.19,
        0.38,
      ).rotation.y = (side * Math.PI) / 2;
    addMesh(
      group,
      new T.PlaneGeometry(1.15, 0.4),
      marking,
      0,
      1.48,
      -0.72,
    ).rotation.y = Math.PI;
    const rear = new T.MeshBasicMaterial({
      map: labelTexture("POLÍCIA RODOVIÁRIA FEDERAL", { font: 27 }),
    });
    addMesh(
      group,
      new T.PlaneGeometry(1.68, 0.19),
      rear,
      0,
      1.2,
      -2.25,
    ).rotation.y = Math.PI;
    box(group, rubber, 0, 1.94, 0.25, 1.35, 0.11, 0.34);
    box(group, chrome, 0, 1.94, -0.5, 1.3, 0.08, 0.15);
  }
  mergeGroup(group);
  const tyres = new T.InstancedMesh(
    new T.CylinderGeometry(0.4, 0.4, 0.24, 12).rotateZ(Math.PI / 2),
    rubber,
    4,
  );
  const hubs = new T.InstancedMesh(
    new T.CylinderGeometry(0.22, 0.22, 0.25, 10).rotateZ(Math.PI / 2),
    chrome,
    4,
  );
  tyres.instanceMatrix.setUsage(T.DynamicDrawUsage);
  hubs.instanceMatrix.setUsage(T.DynamicDrawUsage);
  tyres.frustumCulled = hubs.frustumCulled = false;
  group.add(tyres, hubs);
  const lamps = [];
  if (police)
    for (const side of [-1, 1]) {
      const lamp = box(
        group,
        new T.MeshBasicMaterial({ color: side < 0 ? 0xff3345 : 0x3c8fff }),
        side * 0.38,
        2.04,
        0.25,
        0.56,
        0.15,
        0.3,
      );
      lamps.push(lamp);
    }
  const shadow = addMesh(
    group,
    new T.CircleGeometry(1, 20),
    new T.MeshBasicMaterial({
      color: 0x101810,
      transparent: true,
      opacity: 0.19,
      depthWrite: false,
    }),
    0,
    0.025,
    0,
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.scale.set(1.22, 2.65, 1);
  group.traverse((m) => {
    if (m.isMesh && !m.material.transparent) {
      m.castShadow = true;
      m.receiveShadow = true;
    }
  });
  return {
    group,
    wheels: wheelGroups,
    lamps,
    update(c, time) {
      group.position.set(c.x, 0, c.z);
      group.rotation.y = c.heading;
      wheelGroups.forEach((w, i) => {
        w.rotation.x = -(c.wheelSpin ?? c.z / 0.4);
        if (i % 2 === 1) w.rotation.y = c.steering ?? 0;
        w.updateMatrix();
        tyres.setMatrixAt(i, w.matrix);
        hubs.setMatrixAt(i, w.matrix);
      });
      tyres.instanceMatrix.needsUpdate = hubs.instanceMatrix.needsUpdate = true;
      lamps.forEach((l, i) => {
        l.visible = c.lights && Math.floor(time * 5) % 2 === i;
      });
    },
  };
}

function createPeople(root) {
  const roles = [
    "PRF",
    "CONTROLE",
    "MANUTENÇÃO",
    "CONDUTOR",
    "PRF",
    "PRF",
    "PRF",
    "PRF",
    "PRF",
    "CONDUTOR",
  ];
  roles.push(...Array(6).fill("VISITANTE"));
  const colors = [
    0x1b304f, 0x3d6476, 0xc0833f, 0x66828b, 0x1b304f, 0x1b304f, 0x1b304f,
    0x1b304f, 0x1b304f, 0x8e8370,
  ];
  colors.push(0xa75f55, 0x647c95, 0xa68a58, 0x797293, 0x5e8f80, 0x96725b);
  const dark = new T.MeshStandardMaterial({ color: 0x1a2530, roughness: 0.8 });
  const skin = new T.MeshStandardMaterial({ color: 0xb88d71, roughness: 0.85 });
  const cloth = new T.MeshStandardMaterial({ color: 0xffffff, roughness: 0.9 });
  const parts = [];
  function batch(
    geometry,
    material,
    x,
    y,
    z = 0,
    limb = 0,
    indices = roles.map((_, i) => i),
    tint = null,
  ) {
    const instances = new T.InstancedMesh(geometry, material, indices.length);
    instances.instanceMatrix.setUsage(T.DynamicDrawUsage);
    instances.frustumCulled = false;
    if (tint)
      indices.forEach((index, i) =>
        instances.setColorAt(i, new T.Color(tint(index))),
      );
    root.add(instances);
    parts.push({ instances, x, y, z, limb, indices });
  }
  const badge = new T.MeshBasicMaterial({
    map: labelTexture("PRF", { width: 256, height: 128, font: 100 }),
  });
  batch(
    new T.CapsuleGeometry(0.22, 0.45, 3, 8),
    cloth,
    0,
    1.17,
    0,
    0,
    undefined,
    (i) => colors[i],
  );
  batch(new T.SphereGeometry(0.18, 10, 6), skin, 0, 1.76);
  for (const side of [-1, 1]) {
    batch(
      new T.CapsuleGeometry(0.075, 0.48, 3, 6),
      cloth,
      side * 0.3,
      1.15,
      0,
      side,
      undefined,
      (i) => colors[i],
    );
    batch(
      new T.CapsuleGeometry(0.1, 0.53, 3, 6),
      cloth,
      side * 0.12,
      0.45,
      0,
      -side,
      undefined,
      (i) =>
        i === 0 || i === 4 || (i >= 5 && i <= 8)
          ? 0xada185
          : i === 2
            ? 0x805a35
            : 0x273d4a,
    );
    batch(rounded(0.18, 0.16, 0.29), dark, side * 0.12, 0.09, 0.05, -side);
  }
  batch(
    new T.TorusGeometry(0.215, 0.035, 4, 10).rotateX(Math.PI / 2),
    dark,
    0,
    0.89,
  );
  batch(
    new T.SphereGeometry(0.19, 10, 5, 0, Math.PI * 2, 0, Math.PI / 2),
    dark,
    0,
    1.83,
    0,
    0,
    [0, 4, 5, 6, 7, 8],
  );
  batch(rounded(0.27, 0.035, 0.19), dark, 0, 1.83, 0.15, 0, [0, 4, 5, 6, 7, 8]);
  batch(
    new T.PlaneGeometry(0.3, 0.16),
    badge,
    0,
    1.25,
    0.228,
    0,
    [0, 4, 5, 6, 7, 8],
  );
  batch(
    new T.PlaneGeometry(0.36, 0.19).rotateY(Math.PI),
    badge,
    0,
    1.25,
    -0.228,
    0,
    [0, 4, 5, 6, 7, 8],
  );
  batch(new T.TorusGeometry(0.21, 0.018, 4, 12, Math.PI), dark, 0, 1.75, 0, 0, [
    1,
  ]);
  batch(
    new T.SphereGeometry(0.23, 10, 5, 0, Math.PI * 2, 0, Math.PI / 2),
    new T.MeshStandardMaterial({ color: 0xcda84d }),
    0,
    1.82,
    0,
    0,
    [2],
  );
  const vest = new T.MeshStandardMaterial({ color: 0xe4d44c, roughness: 0.8 });
  for (const side of [-1, 1])
    for (const front of [-1, 1])
      batch(
        rounded(0.045, 0.4, 0.03),
        vest,
        side * 0.11,
        1.17,
        front * 0.23,
        0,
        [5, 6],
      );
  batch(rounded(0.28, 0.04, 0.35), dark, 0, 1.0, 0.4, 0, [6]);
  parts.at(-1).clipboard = true;
  const body = new T.Object3D(),
    d = new T.Object3D();
  return {
    count: roles.length,
    update(s, firstPerson = s.firstPerson) {
      const playerHeading = s.player.yaw + Math.PI;
      const cp = s.checkpoint;
      const checking = cp.stage === "checking",
        returning = cp.stage === "release";
      const approach = checking
        ? Math.min(1, cp.elapsed / 1.5)
        : returning
          ? 1 - Math.min(1, cp.elapsed / 2)
          : 0;
      const people = [
        {
          x: 32,
          z: 22,
          heading: 0,
          phase: s.time * 4,
          action: "typing",
          visible: true,
        },
        {
          x: 38,
          z: 22,
          heading: 0,
          phase: s.time * 3,
          action: "typing",
          visible: true,
        },
        {
          x: 47,
          z: -22,
          heading: Math.PI / 2,
          phase: s.time * 5,
          action: "repair",
          visible: true,
        },
        {
          x: s.driver.x,
          z: s.driver.z,
          heading: s.driver.x < 0 ? Math.PI / 2 : -Math.PI / 2,
          phase: s.driver.phase,
          action: s.driver.walking ? "walk" : "idle",
          visible: s.driver.visible,
        },
        {
          x: s.player.x,
          z: s.player.z,
          heading: playerHeading,
          phase: s.player.distance * 5,
          action: s.radar ? "radar" : s.player.moving ? "walk" : "idle",
          visible: s.mode === "foot" && !firstPerson,
        },
        {
          x: -5.7,
          z: -4,
          heading: Math.PI,
          phase: s.time * 2,
          action: ["approach", "signal"].includes(cp.stage)
            ? "signal"
            : "watch",
          visible: true,
        },
        {
          x: -10.5 - approach * 0.2,
          z: 21 - approach * 1.2,
          heading: Math.PI,
          phase: cp.elapsed * 5,
          action:
            checking && cp.elapsed > 1.5
              ? "documents"
              : approach > 0 && approach < 1
                ? "walk"
                : "watch",
          visible: true,
        },
        {
          x: 10.4,
          z: -12,
          heading: -Math.PI / 2,
          phase: s.time * 2,
          action: "radio",
          visible: true,
        },
        {
          x: 21.5,
          z: 9,
          heading: Math.PI / 2,
          phase: 0,
          action: "watch",
          visible: true,
        },
        {
          x: cp.driverX,
          z: cp.driverZ,
          heading: Math.PI / 2,
          phase: cp.elapsed * 6,
          action: cp.stage === "release" ? "walk" : "idle",
          visible: cp.driverVisible,
        },
      ];
      people.push(
        ...s.reception.visitors.map((v) => ({
          x: v.x,
          z: v.z,
          heading: v.heading,
          phase: s.time * 8,
          action: v.moving ? "walk" : "idle",
          visible: v.state !== "away",
        })),
      );
      for (const part of parts) {
        part.indices.forEach((index, i) => {
          const p = people[index];
          body.position.set(p.x, 0, p.z);
          body.rotation.y = p.heading;
          body.updateMatrix();
          d.position.set(part.x, part.y, part.z);
          d.scale.setScalar(p.visible ? 1 : 0);
          let angle =
            p.action === "walk" ? part.limb * Math.sin(p.phase) * 0.35 : 0;
          if (p.action === "idle") angle = 0;
          if (
            part.y > 1 &&
            part.limb &&
            (p.action === "typing" ||
              p.action === "repair" ||
              p.action === "radar" ||
              p.action === "documents")
          )
            angle = -0.8 + Math.sin(p.phase) * 0.1;
          if (part.y > 1 && part.limb === 1 && p.action === "signal") {
            angle = -1.1;
            d.position.y += 0.22;
            d.position.z += 0.1;
          }
          if (part.y > 1 && part.limb === 1 && p.action === "radio") {
            angle = -2.3;
            d.position.y += 0.1;
          }
          if (part.clipboard && p.action !== "documents") d.scale.setScalar(0);
          d.rotation.set(angle, 0, 0);
          d.updateMatrix();
          d.matrix.premultiply(body.matrix);
          part.instances.setMatrixAt(i, d.matrix);
        });
        part.instances.instanceMatrix.needsUpdate = true;
      }
    },
  };
}

export function createRoadWorld(scene, camera, sim, mobile) {
  const fixed = new T.Group();
  scene.add(fixed);
  const mat = {
    ground: new T.MeshStandardMaterial({ color: 0x778867, roughness: 1 }),
    asphalt: new T.MeshStandardMaterial({ color: 0x41494b, roughness: 0.97 }),
    concrete: new T.MeshStandardMaterial({ color: 0xb9b9a7, roughness: 0.85 }),
    white: new T.MeshStandardMaterial({ color: 0xe7e3d5, roughness: 0.85 }),
    blue: new T.MeshStandardMaterial({ color: 0x203958, roughness: 0.65 }),
    yellow: new T.MeshStandardMaterial({ color: 0xedd168, roughness: 0.8 }),
    glass: new T.MeshStandardMaterial({
      color: 0x37606b,
      metalness: 0.25,
      roughness: 0.3,
    }),
    steel: new T.MeshStandardMaterial({
      color: 0x929d9e,
      metalness: 0.45,
      roughness: 0.6,
    }),
  };
  const maps = createSurfaceMaps(mobile);
  mat.ground.map = maps.terrain;
  mat.asphalt.map = maps.road;
  mat.asphalt.bumpMap = maps.road;
  mat.asphalt.bumpScale = 0.045;
  mat.asphalt.color.setHex(0xffffff);
  const yardMaterial = mat.asphalt.clone();
  yardMaterial.map = maps.yard;
  yardMaterial.bumpMap = maps.yard;
  box(fixed, mat.ground, 0, -0.25, 0, 1500, 0.4, 1800);
  box(fixed, mat.asphalt, 0, -0.02, 0, 14, 0.08, 1200);
  for (const side of [-1, 1])
    box(fixed, mat.concrete, side * 9, 0.005, 0, 4, 0.08, 1200);
  box(fixed, yardMaterial, 32, 0.03, 0, 51, 0.1, 90);
  for (const side of [-1, 1])
    box(fixed, mat.white, side * 6.75, 0.04, 0, 0.12, 0.025, 1190);
  for (let z = -590; z < 590; z += 16)
    for (const x of [-0.16, 0.16])
      box(fixed, mat.yellow, x, 0.05, z, 0.1, 0.025, 7);
  // Road arrows follow the right-hand lanes from the driver's perspective.
  for (let z = -480; z <= 480; z += 120)
    for (const direction of [-1, 1]) {
      const x = direction > 0 ? -3.4 : 3.4;
      addMesh(
        fixed,
        new T.PlaneGeometry(0.12, 3).rotateX(-Math.PI / 2),
        mat.white,
        x,
        0.065,
        z,
      );
      for (const side of [-1, 1]) {
        const arrow = addMesh(
          fixed,
          new T.PlaneGeometry(0.12, 1.1).rotateX(-Math.PI / 2),
          mat.white,
          x + side * 0.35,
          0.065,
          z + direction * 1.25,
        );
        arrow.rotation.y = (-side * direction * Math.PI) / 4;
      }
    }
  for (let z = -580; z < 580; z += 12) {
    for (const side of [-1, 1]) {
      if (side > 0 && z > -35 && z < 45) continue;
      box(fixed, mat.steel, side * 12, 0.55, z, 0.12, 1.1, 0.12);
    }
  }
  box(fixed, mat.steel, -12, 0.92, 0, 0.14, 0.22, 1190);
  box(fixed, mat.steel, 12, 0.92, -320, 0.14, 0.22, 550);
  box(fixed, mat.steel, 12, 0.92, 320, 0.14, 0.22, 550);
  const base = createPrfBase(
    scene,
    { mat, addMesh, mergeGroup, labelTexture },
    mobile,
  );
  for (const x of [16.2, 23.8])
    box(fixed, mat.white, x, 0.1, -8, 0.08, 0.02, 7);
  for (const z of [-12, -4]) box(fixed, mat.white, 20, 0.1, z, 7.5, 0.02, 0.1);
  function sign(
    text,
    x,
    y,
    z,
    width = 6,
    height = 1,
    rotation = 0,
    background = "#19364b",
    color = "#f7d746",
  ) {
    const material = new T.MeshBasicMaterial({
      map: labelTexture(text, {
        background,
        color,
        font: text.length > 20 ? 30 : 54,
      }),
    });
    const m = addMesh(
      fixed,
      new T.PlaneGeometry(width, height),
      material,
      x,
      y,
      z,
    );
    m.rotation.y = rotation;
    return m;
  }
  sign(
    "FISCALIZAÇÃO • 60 km/h",
    -11,
    2.5,
    -72,
    4,
    1.5,
    Math.PI,
    "#ece8d4",
    "#273e4b",
  );
  box(fixed, mat.steel, -11, 1.2, -72, 0.12, 2.4, 0.12);
  for (const z of [-520, 520])
    sign(
      "FIM DO TRECHO • RETORNE",
      z > 0 ? -10 : 10,
      2.4,
      z,
      5,
      1.6,
      z > 0 ? Math.PI : 0,
    );
  // Brazil flag drawn locally rather than fetched as an image.
  const flag = document.createElement("canvas");
  flag.width = 256;
  flag.height = 160;
  const f = flag.getContext("2d");
  f.fillStyle = "#398959";
  f.fillRect(0, 0, 256, 160);
  f.fillStyle = "#e5c74f";
  f.beginPath();
  f.moveTo(128, 20);
  f.lineTo(232, 80);
  f.lineTo(128, 140);
  f.lineTo(24, 80);
  f.closePath();
  f.fill();
  f.fillStyle = "#244a7c";
  f.beginPath();
  f.arc(128, 80, 37, 0, Math.PI * 2);
  f.fill();
  const flagMap = new T.CanvasTexture(flag);
  flagMap.colorSpace = T.SRGBColorSpace;
  addMesh(
    fixed,
    new T.PlaneGeometry(2, 1.25),
    new T.MeshBasicMaterial({ map: flagMap, side: T.DoubleSide }),
    48,
    4.3,
    5,
  );
  box(fixed, mat.steel, 47, 2.5, 5, 0.09, 5, 0.09);
  mergeGroup(fixed);
  fixed.traverse((m) => {
    if (m.isMesh) m.receiveShadow = true;
  });
  const doors = [-1, 1].map((side) =>
    box(scene, base.glass, 35 + side * 0.8, 1.4, 10, 1.55, 2.8, 0.12),
  );
  // Shared instanced foliage and distant low-poly hills.
  const count = mobile ? 100 : 180,
    trunks = new T.InstancedMesh(
      new T.CylinderGeometry(0.16, 0.26, 3, 5),
      new T.MeshStandardMaterial({ color: 0x6c6250 }),
      count,
    );
  const crowns = new T.InstancedMesh(
    new T.IcosahedronGeometry(1, 1),
    new T.MeshStandardMaterial({ color: 0x526f4b, roughness: 1 }),
    count,
  );
  const d = new T.Object3D();
  let seed = 73;
  const rand = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  for (let i = 0; i < count; i++) {
    const side = i % 2 ? 1 : -1,
      x = side * (20 + rand() * 150) + (side > 0 ? 55 : 0),
      z = -650 + rand() * 1300,
      size = 1.5 + rand() * 3;
    d.position.set(x, 1.5, z);
    d.scale.set(1, 1, 1);
    d.updateMatrix();
    trunks.setMatrixAt(i, d.matrix);
    d.position.y = 3.8;
    d.scale.set(size, 2.5 + size, size);
    d.rotation.y = rand() * 6;
    d.updateMatrix();
    crowns.setMatrixAt(i, d.matrix);
  }
  scene.add(trunks, crowns);
  const hills = new T.InstancedMesh(
    new T.SphereGeometry(1, 12, 6),
    new T.MeshStandardMaterial({ color: 0x849578, roughness: 1 }),
    18,
  );
  for (let i = 0; i < 18; i++) {
    d.position.set((i % 2 ? 1 : -1) * (180 + rand() * 140), -18, -750 + i * 90);
    d.scale.set(90 + rand() * 80, 45 + rand() * 45, 90 + rand() * 100);
    d.rotation.set(0, rand() * 6, 0);
    d.updateMatrix();
    hills.setMatrixAt(i, d.matrix);
  }
  scene.add(hills);
  const patrol = createVehicle({ police: true, plate: "SIM-0191" });
  scene.add(patrol.group);
  const traffic = sim.traffic.map((c) => {
    const m = createVehicle({ color: c.color, plate: c.plate });
    scene.add(m.group);
    return m;
  });
  const support = sim.support.map((c) => {
    const m = createVehicle({ police: true, plate: c.plate });
    scene.add(m.group);
    return m;
  });
  const people = createPeople(scene);
  const cabin = new T.Group();
  camera.add(cabin);
  cabin.visible = false;
  box(cabin, mat.blue, 0, -0.63, -0.94, 1.9, 0.32, 0.6);
  addMesh(
    cabin,
    new T.TorusGeometry(0.17, 0.018, 6, 20),
    mat.steel,
    -0.28,
    -0.4,
    -0.75,
  );
  const speedCanvas = document.createElement("canvas");
  speedCanvas.width = 256;
  speedCanvas.height = 128;
  const speedTexture = new T.CanvasTexture(speedCanvas);
  speedTexture.colorSpace = T.SRGBColorSpace;
  addMesh(
    cabin,
    new T.PlaneGeometry(0.4, 0.2),
    new T.MeshBasicMaterial({ map: speedTexture }),
    -0.28,
    -0.39,
    -0.93,
  );
  const radarDevice = new T.Group();
  camera.add(radarDevice);
  radarDevice.visible = false;
  box(radarDevice, mat.blue, 0.26, -0.31, -0.65, 0.28, 0.2, 0.15);
  const radarCanvas = document.createElement("canvas");
  radarCanvas.width = 256;
  radarCanvas.height = 128;
  const radarTexture = new T.CanvasTexture(radarCanvas);
  radarTexture.colorSpace = T.SRGBColorSpace;
  addMesh(
    radarDevice,
    new T.PlaneGeometry(0.24, 0.12),
    new T.MeshBasicMaterial({ map: radarTexture }),
    0.26,
    -0.3,
    -0.56,
  );
  let displayTime = 0;
  return {
    patrol,
    traffic,
    people,
    support,
    base,
    update(s, dt, reading, firstPerson = s.firstPerson) {
      base.update(dt, s.checkpoint);
      patrol.update(s.car, s.time);
      patrol.group.visible = !(s.mode === "drive" && s.car.interior);
      s.traffic.forEach((c, i) => traffic[i].update(c, s.time));
      s.support.forEach((c, i) => support[i].update(c, s.time));
      people.update(s, firstPerson);
      doors.forEach(
        (door, i) =>
          (door.position.x = 35 + (i ? 1 : -1) * (0.8 + s.door * 1.65)),
      );
      cabin.visible = s.mode === "drive" && s.car.interior;
      radarDevice.visible = s.mode === "foot" && firstPerson && s.radar;
      displayTime += dt;
      if (displayTime > 0.12) {
        displayTime = 0;
        const ctx = speedCanvas.getContext("2d");
        ctx.fillStyle = "#102731";
        ctx.fillRect(0, 0, 256, 128);
        ctx.fillStyle = "#ccece3";
        ctx.textAlign = "center";
        ctx.font = "bold 54px monospace";
        ctx.fillText(String(Math.round(Math.abs(s.car.speed) * 3.6)), 128, 66);
        ctx.font = "23px Arial";
        ctx.fillText("km/h • PRF", 128, 106);
        speedTexture.needsUpdate = true;
        const r = radarCanvas.getContext("2d");
        r.fillStyle = "#09251c";
        r.fillRect(0, 0, 256, 128);
        r.fillStyle = "#91eab1";
        r.textAlign = "center";
        r.font = "bold 45px monospace";
        r.fillText(
          reading
            ? Math.round(reading.vehicle.speed * 3.6) + " km/h"
            : "BUSCANDO",
          128,
          58,
        );
        r.font = "22px Arial";
        r.fillText(
          reading ? Math.round(reading.distance) + " m" : "RADAR",
          128,
          100,
        );
        radarTexture.needsUpdate = true;
      }
    },
  };
}
