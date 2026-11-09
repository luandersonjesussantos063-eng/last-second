import * as THREE from "./vendor/engine.js";
import { ROOMS, FLOOR_Y, UPPER_FLOOR, RAMP } from "./station-layout.js";
import { FLIGHT_LABELS } from "./station-operations.js";

export function addStationTechnology({
  root,
  box,
  mesh,
  sign,
  props,
  metal,
  dark,
  pale,
  blue,
  glow,
  mobile,
}) {
  const atlas = document.createElement("canvas");
  atlas.width = mobile ? 1024 : 2048;
  atlas.height = mobile ? 256 : 512;
  const context = atlas.getContext("2d");
  context.scale(atlas.width / 2048, atlas.height / 512);
  const texture = new THREE.CanvasTexture(atlas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const screenMaterial = new THREE.MeshBasicMaterial({
    map: texture,
    toneMapped: false,
  });
  function panel(x, y, z, w, h, yaw, index, tilt = 0) {
    const geometry = new THREE.PlaneGeometry(w, h),
      uv = geometry.attributes.uv;
    const column = index % 4,
      row = Math.floor(index / 4);
    for (let i = 0; i < uv.count; i++)
      uv.setXY(i, (column + uv.getX(i)) / 4, 1 - (row + 1 - uv.getY(i)) / 2);
    const screen = mesh(geometry, screenMaterial, x, y, z);
    screen.rotation.set(tilt, yaw, 0, "YXZ");
    return screen;
  }
  for (const room of ROOMS) {
    const x = room.side * 49.6;
    for (const dz of [-3.5, 0, 3.5]) {
      if (room.kind === "quarters" || room.kind === "medical") continue;
      panel(
        x,
        -2.85,
        room.z + dz,
        2.3,
        1.35,
        (-room.side * Math.PI) / 2,
        room.kind === "workshop" ? 4 : 2,
      );
    }
    for (const edge of [-8, 8]) {
      box(room.side * 44, 0.65, room.z + edge, 15, 0.07, 0.1, glow);
      box(room.side * 53.3, -1.9, room.z + edge, 0.12, 4.4, 0.18, blue);
    }
    if (room.kind === "medical") {
      for (const dz of [-5.6, 5.6]) {
        const ring = mesh(
          new THREE.TorusGeometry(1.35, 0.07, 5, 18),
          glow,
          room.side * 49.5,
          -2.3,
          room.z + dz,
        );
        ring.rotation.y = Math.PI / 2;
        panel(-53.25, -1.5, room.z + dz, 2.3, 1.5, Math.PI / 2, 6);
      }
    } else if (room.kind === "quarters") {
      panel(-49.45, -2.5, room.z, 2.2, 1.4, Math.PI / 2, 7);
      for (const dz of [-5.6, 5.6])
        box(-49.5, -3.35, room.z + dz, 3.6, 0.08, 0.06, glow);
    } else if (room.kind === "workshop") {
      for (const dz of [-6, 6]) {
        const base = mesh(
          new THREE.CylinderGeometry(0.5, 0.7, 0.5, 10),
          blue,
          42,
          -2.9,
          room.z + dz,
        );
        const arm = box(42, -2.05, room.z + dz, 0.3, 1.7, 0.3, pale);
        arm.rotation.z = 0.4;
        const tool = box(42.6, -1.3, room.z + dz, 1.2, 0.25, 0.25, blue);
        tool.rotation.z = -0.3;
      }
    } else {
      const globe = mesh(
        new THREE.IcosahedronGeometry(0.9, 1),
        new THREE.MeshBasicMaterial({ color: 0x63eaff, wireframe: true }),
        44,
        -1.6,
        room.z,
      );
      box(44, -4.45, room.z, 2, 1.5, 2, dark);
      props.push({ x: 44, z: room.z, hx: 1, hz: 1 });
    }
  }
  for (const ship of [
    [-20, 32],
    [20, 48],
    [-20, 74],
  ]) {
    const [x, z] = ship,
      side = Math.sign(x);
    // Marked service bays and physical briefing terminals.
    for (const edge of [-5, 5])
      box(x + edge, FLOOR_Y + 0.04, z, 0.1, 0.06, 13, glow);
    box(side * 28, -4.35, z - 2, 1.1, 1.7, 1.4, blue);
    panel(side * 27.42, -3.1, z - 2, 1.35, 0.9, (-side * Math.PI) / 2, 0);
    props.push({ x: side * 28, z: z - 2, hx: 0.55, hz: 0.7 });
    sign("ÁREA DE SERVIÇO", x, -0.3, z - 7, 0, "#ffd58a", 5);
  }
  // Upper level: a continuous sloping deck, balcony and command room.
  const rise = UPPER_FLOOR - FLOOR_Y,
    length = RAMP.maxZ - RAMP.minZ;
  const ramp = box(
    29.6,
    (FLOOR_Y + UPPER_FLOOR) / 2 - 0.13,
    4,
    4.4,
    0.25,
    Math.hypot(length, rise),
    metal,
  );
  ramp.rotation.x = -Math.atan2(rise, length);
  for (const x of [27.3, 31.9]) {
    const rail = box(
      x,
      (FLOOR_Y + UPPER_FLOOR) / 2 + 1.1,
      4,
      0.1,
      0.12,
      Math.hypot(length, rise),
      glow,
    );
    rail.rotation.x = -Math.atan2(rise, length);
    for (let z = -10; z <= 18; z += 7) {
      const y = FLOOR_Y + ((z + 10) / 28) * rise;
      box(x, y + 0.55, z, 0.1, 1.1, 0.1, blue);
    }
  }
  sign(
    "RAMPA • CENTRAL DE COMANDO ↑",
    29.6,
    -2.1,
    -10.8,
    Math.PI,
    "#9deaff",
    4.5,
  );
  box(29.8, UPPER_FLOOR - 0.22, 40, 4.8, 0.44, 44, metal);
  for (const x of [27.3, 32.3]) {
    box(x, UPPER_FLOOR + 1.1, 40, 0.1, 0.1, 44, glow);
    for (let z = 20; z <= 60; z += 8)
      box(x, UPPER_FLOOR + 0.55, z, 0.1, 1.1, 0.1, blue);
  }
  box(25.3, UPPER_FLOOR - 0.22, 78.2, 14.4, 0.44, 33.6, metal);
  box(25.3, 8.6, 78.2, 14.4, 0.35, 33.6, dark);
  for (const z of [64, 72, 80, 88, 94.5]) {
    box(18.2, 5.7, z, 0.18, 5.8, 0.18, blue);
    box(32.4, 5.7, z, 0.18, 5.8, 0.18, blue);
    box(25.3, 8.35, z, 14.4, 0.12, 0.12, glow);
  }
  const glass = new THREE.MeshBasicMaterial({
    color: 0x81cfff,
    transparent: true,
    opacity: 0.12,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  mesh(new THREE.PlaneGeometry(14, 5.4), glass, 25.3, 5.7, 95.2).rotation.y =
    Math.PI;
  // Side glazing overlooks the operating hangar; the front window sees real space geometry.
  mesh(new THREE.PlaneGeometry(32, 5.4), glass, 18.2, 5.7, 78.5).rotation.y =
    Math.PI / 2;
  for (const x of [18.2, 32.4])
    box(x, UPPER_FLOOR + 1.1, 78, 0.12, 0.12, 33, glow);
  for (const x of [22, 26, 30]) {
    box(x, 3.45, 90.1, 3.2, 1.3, 1.3, dark);
    box(x, 4.12, 89.8, 3.2, 0.1, 1.7, blue);
    props.push({ x, z: 90.1, hx: 1.6, hz: 0.85, floor: UPPER_FLOOR });
    panel(x, 5, 91, 3.1, 1.9, Math.PI, x === 22 ? 0 : x === 26 ? 1 : 2);
    panel(x, 4.2, 89.5, 2.9, 0.75, Math.PI, 3, -0.7);
  }
  for (const z of [74, 80]) {
    box(22.2, 3.5, z, 1.2, 1.4, 3, dark);
    panel(21.55, 4.7, z, 2.8, 1.6, -Math.PI / 2, z === 74 ? 4 : 5);
    props.push({ x: 22.2, z, hx: 0.6, hz: 1.5, floor: UPPER_FLOOR });
  }
  sign("CENTRAL DE COMANDO", 25.5, 6.8, 62.2, Math.PI, "#b9f7ff", 11);
  panel(32.25, 6.2, 80, 9, 3.6, -Math.PI / 2, 0);
  panel(32.25, 6.2, 69.5, 8, 3.6, -Math.PI / 2, 5);

  let elapsed = 10,
    revision = 0;
  function update(dt, time, traffic, workers) {
    elapsed += dt;
    if (elapsed < (mobile ? 0.75 : 0.4)) return;
    elapsed = 0;
    revision++;
    const titles = [
      "CONTROLE DE TRÁFEGO",
      "RADAR ORBITAL",
      "TELEMETRIA DA FROTA",
      "ENERGIA DA BASE",
      "ENGENHARIA",
      "EQUIPE E OPERAÇÕES",
      "SUPORTE MÉDICO",
      "SUPRIMENTOS",
    ];
    for (let index = 0; index < 8; index++) {
      const ox = (index % 4) * 512,
        oy = Math.floor(index / 4) * 256;
      context.save();
      context.translate(ox, oy);
      context.fillStyle = "#031721";
      context.fillRect(0, 0, 512, 256);
      context.strokeStyle = "#164555";
      context.lineWidth = 1;
      for (let x = 12; x < 512; x += 32) {
        context.beginPath();
        context.moveTo(x, 45);
        context.lineTo(x, 245);
        context.stroke();
      }
      for (let y = 48; y < 256; y += 32) {
        context.beginPath();
        context.moveTo(10, y);
        context.lineTo(502, y);
        context.stroke();
      }
      context.fillStyle = "#9deaff";
      context.font = "bold 23px Arial";
      context.fillText(titles[index], 14, 30);
      context.font = "19px monospace";
      if (index === 0 || index === 2) {
        traffic.ships.forEach((s, i) => {
          context.fillStyle = s.blocked ? "#ffc779" : "#b8ffdb";
          context.fillText(
            `${s.id}  ${s.blocked ? "AGUARDA PEDESTRE" : FLIGHT_LABELS[s.state]}`,
            14,
            78 + i * 48,
          );
        });
        context.fillStyle = "#65bbd0";
        context.fillText(
          `PISTA: ${traffic.owner ?? "LIVRE"}  VOOS: ${traffic.completedFlights}`,
          14,
          231,
        );
      } else if (index === 1) {
        context.strokeStyle = "#37b6ad";
        for (const r of [35, 68, 100]) {
          context.beginPath();
          context.arc(250, 150, r, 0, Math.PI * 2);
          context.stroke();
        }
        const a = time * 0.0006;
        context.beginPath();
        context.moveTo(250, 150);
        context.lineTo(250 + Math.sin(a) * 100, 150 + Math.cos(a) * 100);
        context.stroke();
        for (const s of traffic.ships) {
          context.fillStyle = "#afffd6";
          context.fillRect(250 + s.x * 0.7, 210 - s.z * 0.35, 6, 6);
        }
      } else if (index === 5) {
        for (let i = 0; i < 4; i++) {
          const w = workers[(i + Math.floor(time / 12000)) % workers.length];
          context.fillStyle = "#b8ffdb";
          context.fillText(
            `${w.role}: ${w.moving ? "EM DESLOCAMENTO" : "EM SERVIÇO"}`,
            14,
            77 + i * 40,
          );
        }
      } else {
        const rows =
          index === 3
            ? ["REATOR: ESTÁVEL", "SUPORTE DE VIDA: ATIVO", "ESCUDOS: NOMINAIS"]
            : index === 4
              ? [
                  "DIAGNÓSTICO: EM EXECUÇÃO",
                  "PROPULSÃO: PRONTA",
                  "MANUTENÇÃO: PROGRAMADA",
                ]
              : index === 6
                ? [
                    "LEITOS: DISPONÍVEIS",
                    "SCANNER: ATIVO",
                    "SUPORTE: EM SERVIÇO",
                  ]
                : [
                    "INVENTÁRIO: SINCRONIZADO",
                    "CARGA: EM CONFERÊNCIA",
                    "RESERVAS: NOMINAIS",
                  ];
        rows.forEach((text, i) => {
          context.fillStyle = "#b8ffdb";
          context.fillText(text, 14, 74 + i * 38);
        });
        context.strokeStyle = "#4cddc6";
        context.beginPath();
        for (let x = 14; x < 500; x += 5) {
          const y = 224 - Math.sin(x * 0.04 + revision * 0.2) * 9;
          x === 14 ? context.moveTo(x, y) : context.lineTo(x, y);
        }
        context.stroke();
      }
      context.restore();
    }
    texture.needsUpdate = true;
  }
  return { update, texture, panel };
}

export function createTrafficCraft(materials, color) {
  const { metal, dark, blue, glow } = materials,
    group = new THREE.Group(),
    pieces = new Map();
  const hullMat = metal.clone();
  hullMat.color.setHex(color);
  function part(geometry, material, x, y, z, sx = 1, sy = 1, sz = 1) {
    const object = new THREE.Mesh(geometry, material);
    object.position.set(x, y, z);
    object.scale.set(sx, sy, sz);
    group.add(object);
    if (!pieces.has(material)) pieces.set(material, []);
    pieces.get(material).push(object);
    return object;
  }
  part(new THREE.SphereGeometry(1, 14, 8), hullMat, 0, 0, 0, 1.8, 1.25, 4.2);
  part(new THREE.SphereGeometry(1, 12, 8), blue, 0, 0.8, 1.4, 1.2, 0.7, 1.7);
  for (const side of [-1, 1]) {
    const wing = part(
      new THREE.RoundedBoxGeometry(4, 0.25, 3.4, 1, 0.1),
      hullMat,
      side * 2.4,
      -0.35,
      -0.6,
    );
    wing.rotation.z = side * 0.1;
    const engine = part(
      new THREE.CapsuleGeometry(0.4, 2.3, 3, 8),
      dark,
      side * 1.7,
      0,
      -2.5,
    );
    engine.rotation.x = Math.PI / 2;
    part(
      new THREE.RoundedBoxGeometry(0.25, 1.1, 0.25, 1, 0.05),
      dark,
      side * 1.6,
      -1.9,
      -0.7,
    );
    part(
      new THREE.RoundedBoxGeometry(1.1, 0.2, 1.2, 1, 0.05),
      dark,
      side * 1.6,
      -2.5,
      -0.7,
    );
    const ramp = part(
      new THREE.RoundedBoxGeometry(3.2, 0.15, 1.6, 1, 0.05),
      hullMat,
      side * 3.7,
      -1.7,
      -2,
    );
    ramp.rotation.z = -side * 0.48;
  }
  for (const [material, objects] of pieces) {
    const gs = objects.map((o) => {
      o.updateMatrix();
      const g = o.geometry.index
        ? o.geometry.toNonIndexed()
        : o.geometry.clone();
      g.applyMatrix4(o.matrix);
      group.remove(o);
      o.geometry.dispose();
      return g;
    });
    group.add(new THREE.Mesh(THREE.mergeGeometries(gs), material));
    gs.forEach((g) => g.dispose());
  }
  const hatch = new THREE.Mesh(new THREE.SphereGeometry(1, 10, 6), blue);
  hatch.scale.set(1.15, 0.32, 1.55);
  hatch.position.set(0, 1.4, 0.5);
  group.add(hatch);
  const exhaust = new THREE.Mesh(new THREE.SphereGeometry(1, 10, 6), glow);
  exhaust.position.set(0, 0, -4.1);
  exhaust.scale.set(0.65, 0.55, 0.4);
  group.add(exhaust);
  return { group, hatch, exhaust };
}
