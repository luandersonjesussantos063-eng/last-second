import { BASE_HEIGHT } from "./base-life.js?v=2.16.0";
import { createComputerScreen } from "./computer-screen.js?v=2.16.0";
import * as T from "./vendor/engine.js?v=2.16.0";
import { CANOPY, BASE_COLUMNS, BLITZ_CONES } from "./base-layout.js?v=2.16.0";
function seeded(seed = 971) {
  return () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}
function surface(size, kind) {
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext("2d"),
    pixels = ctx.createImageData(size, size),
    random = seeded(kind === "asphalt" ? 73 : 129);
  for (let y = 0; y < size; y++)
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4,
        grain = (random() - 0.5) * 22,
        patch = Math.sin(x * 0.034) * Math.sin(y * 0.047) * 5;
      const color = kind === "asphalt" ? [73, 72, 68] : [104, 114, 75];
      for (let c = 0; c < 3; c++) pixels.data[i + c] = color[c] + grain + patch;
      pixels.data[i + 3] = 255;
    }
  ctx.putImageData(pixels, 0, 0);
  if (kind === "asphalt") {
    ctx.strokeStyle = "#20272a55";
    ctx.lineWidth = 0.8;
    for (let i = 0; i < 10; i++) {
      let x = random() * size,
        y = random() * size;
      ctx.beginPath();
      ctx.moveTo(x, y);
      for (let j = 0; j < 6; j++) {
        x += (random() - 0.5) * 45;
        y += random() * 16;
        ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.fillStyle = "#262b2d0d";
    for (let i = 0; i < 12; i++)
      ctx.fillRect(random() * size, 0, 2 + random() * 5, size);
  }
  const map = new T.CanvasTexture(canvas);
  map.colorSpace = T.SRGBColorSpace;
  map.wrapS = map.wrapT = T.RepeatWrapping;
  map.anisotropy = 4;
  return map;
}
export function createSurfaceMaps(mobile) {
  const road = surface(mobile ? 256 : 512, "asphalt"),
    yard = road.clone(),
    terrain = surface(256, "terrain");
  yard.needsUpdate = true;
  road.repeat.set(3, 150);
  yard.repeat.set(10, 18);
  terrain.repeat.set(85, 100);
  return { road, yard, terrain };
}
export function createPrfBase(scene, api, mobile) {
  const { mat, addMesh, mergeGroup, labelTexture } = api,
    root = new T.Group();
  scene.add(root);
  const dark = new T.MeshStandardMaterial({
    color: 0x233441,
    metalness: 0.55,
    roughness: 0.5,
  });
  const roof = new T.MeshStandardMaterial({
    color: 0x303b43,
    metalness: 0.65,
    roughness: 0.55,
  });
  const glass = new T.MeshStandardMaterial({
    color: 0x7ba2aa,
    transparent: true,
    opacity: 0.22,
    roughness: 0.16,
    metalness: 0.25,
    depthWrite: false,
    side: T.DoubleSide,
  });
  const warm = new T.MeshBasicMaterial({ color: 0xffe4b1 });
  const rect = (material, x, y, z, w, h, d) =>
    addMesh(root, new T.BoxGeometry(w, h, d), material, x, y, z);
  function panel(text, x, y, z, w, h, rotation = 0, font = 60) {
    const map = labelTexture(text, {
      width: w > 15 ? 2048 : 1024,
      height: 128,
      font,
      background: "#20313e",
      color: "#ffd64f",
    });
    const m = addMesh(
      root,
      new T.PlaneGeometry(w, h),
      new T.MeshBasicMaterial({ map, toneMapped: false }),
      x,
      y,
      z,
    );
    m.rotation.y = rotation;
    return m;
  }
  function beam(a, b, r = 0.06) {
    const start = new T.Vector3(...a),
      end = new T.Vector3(...b),
      delta = end.clone().sub(start);
    const m = addMesh(
      root,
      new T.CylinderGeometry(r, r, delta.length(), 6),
      dark,
      ...start.clone().add(end).multiplyScalar(0.5).toArray(),
    );
    m.quaternion.setFromUnitVectors(new T.Vector3(0, 1, 0), delta.normalize());
  }
  // Photo reference: broad road-spanning portal and visible lattice structure.
  rect(roof, 4.5, 9, -0.4, 40.8, 0.25, 0.8);
  rect(roof, 4.5, 9.08, 12.5, 40.8, 0.22, 34.5);
  for (const column of BASE_COLUMNS) {
    rect(mat.concrete, column.x, 0.32, column.z, 1.15, 0.64, 1.15);
    rect(dark, column.x, 4.3, column.z, 0.25, 8, 0.6);
    for (const side of [-1, 1])
      rect(dark, column.x + side * 0.16, 4.3, column.z, 0.1, 8, 0.72);
    rect(mat.yellow, column.x, 1.1, column.z, 0.48, 0.18, 0.75);
  }
  for (const z of [-3, 5, 13, 21, 28]) {
    rect(dark, 4.25, 8.78, z, 39, 0.16, 0.2);
    rect(dark, 4.25, 7.72, z, 39, 0.16, 0.2);
    for (let x = -15; x < 23; x += 3)
      beam([x, 7.72, z], [Math.min(x + 3, 23.5), 8.78, z], 0.055);
  }
  for (let x = -15; x <= 24; x += 3) rect(dark, x, 8.92, 12, 0.1, 0.16, 33);
  rect(dark, 4.5, 8.65, -4.6, 40.8, 1.25, 0.55);
  rect(dark, 4.5, 8.65, 29.55, 40.8, 1.25, 0.55);
  panel("POLÍCIA RODOVIÁRIA FEDERAL", 4.5, 8.66, -4.9, 35, 0.94, Math.PI, 85);
  panel("POLÍCIA RODOVIÁRIA FEDERAL", 4.5, 8.66, 29.86, 35, 0.94, 0, 85);
  // Small generated shield/crest at each end of the fascia.
  const badge = document.createElement("canvas");
  badge.width = badge.height = 256;
  const b = badge.getContext("2d");
  b.fillStyle = "#20313e";
  b.fillRect(0, 0, 256, 256);
  b.strokeStyle = "#e8c963";
  b.lineWidth = 11;
  b.beginPath();
  b.moveTo(44, 30);
  b.lineTo(212, 30);
  b.lineTo(204, 158);
  b.quadraticCurveTo(190, 202, 128, 232);
  b.quadraticCurveTo(66, 202, 52, 158);
  b.closePath();
  b.stroke();
  b.fillStyle = "#f4d16a";
  b.textAlign = "center";
  b.font = "bold 57px Arial";
  b.fillText("PRF", 128, 137);
  b.font = "22px Arial";
  b.fillText("BRASIL", 128, 174);
  const badgeMap = new T.CanvasTexture(badge);
  badgeMap.colorSpace = T.SRGBColorSpace;
  const badgeMat = new T.MeshBasicMaterial({
    map: badgeMap,
    toneMapped: false,
  });
  for (const x of [-14.4, 23.3])
    for (const z of [-4.91, 29.87])
      addMesh(
        root,
        new T.PlaneGeometry(1.05, 1.05),
        badgeMat,
        x,
        8.65,
        z,
      ).rotation.y = z < 0 ? Math.PI : 0;
  for (const x of [-10, 0, 10, 20]) rect(warm, x, 7.65, 12, 0.12, 0.06, 8);
  const officeStart = root.children.length;
  // Office remains walkable; the façade now has tall transparent window bays.
  rect(mat.concrete, 35, 0.07, 20, 19, 0.14, 21);
  rect(mat.white, 44, 2.1, 20, 0.6, 4.2, 20);
  // Road-facing transparent observation window in the player's office.
  rect(mat.white, 26, 0.5, 20, 0.6, 1, 20);
  rect(mat.white, 26, 3.6, 20, 0.6, 1.2, 20);
  rect(glass, 26, 2, 20, 0.08, 2, 20);
  for (const z of [10, 14, 18, 22, 26, 30])
    rect(dark, 25.94, 2, z, 0.12, 2.2, 0.07);
  for (const [z, depth] of [
    [12.2, 4.4],
    [20.3, 4.6],
  ])
    rect(glass, 33, 1.8, z, 0.08, 3.6, depth);
  rect(glass, 29.5, 1.8, 20.8, 7, 3.6, 0.08);
  for (const z of [14.4, 18]) rect(dark, 33, 1.8, z, 0.1, 3.6, 0.1);
  panel("COMANDO GERAL", 33.1, 2.7, 16, 2.7, 0.4, Math.PI / 2, 90);
  panel("COMANDO GERAL", 32.9, 2.7, 16, 2.7, 0.4, -Math.PI / 2, 90);
  panel("RECEPÇÃO • RETIRE SUA SENHA", 38, 2.8, 29.6, 7, 0.5, Math.PI, 38);
  // Desk faces the doorway (+X); the low, offset monitor leaves the visitor visible.
  rect(mat.steel, 29.9, 0.83, 16, 1.1, 0.12, 3);
  rect(dark, 30, 1.25, 16.85, 0.12, 0.84, 1.4);
  rect(dark, 30, 0.94, 16.85, 0.12, 0.2, 0.12);
  rect(dark, 29.3, 0.91, 16, 0.34, 0.025, 0.7);
  rect(dark, 28.3, 0.48, 16, 0.7, 0.15, 0.7);
  rect(mat.blue, 27.95, 0.95, 16, 0.12, 0.9, 0.7);
  for (const x of [28.05, 28.55])
    for (const z of [15.75, 16.25]) rect(dark, x, 0.25, z, 0.06, 0.5, 0.06);
  rect(mat.white, 35, 2.1, 30, 18, 4.2, 0.6);
  for (const x of [29.7, 40.3]) {
    rect(mat.white, x, 0.5, 10, 7.4, 1, 0.5);
    rect(glass, x, 2.05, 10, 7.4, 2.1, 0.06);
    for (const offset of [-3.6, -1.2, 1.2, 3.6])
      rect(dark, x + offset, 2.1, 9.94, 0.065, 2.3, 0.09);
  }
  rect(dark, 35, 3.65, 10, 18.6, 0.75, 0.7);
  rect(dark, 35, 4.22, 20, 20, 0.25, 22);
  rect(mat.white, 35, 3.2, 10, 3.2, 0.6, 0.5);
  rect(dark, 35, 3.28, 5, 21, 0.17, 10);
  for (const x of [25, 45]) rect(dark, x, 1.65, 1, 0.16, 3.3, 0.16);
  panel("191 • PRF", 35, 3.65, 9.61, 8, 0.46, Math.PI, 58);
  panel("UNIDADE OPERACIONAL • BR-163", 35, 2.9, 9.6, 10, 0.35, Math.PI, 40);
  rect(mat.blue, 35, 0.85, 24, 7, 1.5, 2.2);
  const screenMat = new T.MeshBasicMaterial({
    map: labelTexture("SISTEMA DE FISCALIZAÇÃO", {
      background: "#173b43",
      color: "#a4d6b6",
      font: 30,
    }),
  });
  for (const x of [32, 38]) {
    rect(mat.steel, x, 1.46, 23.6, 1.7, 0.08, 0.6);
    rect(dark, x, 1.82, 24.3, 1.7, 0.9, 0.1);
    addMesh(
      root,
      new T.PlaneGeometry(1.5, 0.7),
      screenMat,
      x,
      1.82,
      24.235,
    ).rotation.y = Math.PI;
  }
  rect(mat.blue, 41, 1, 17, 2, 2, 4);
  rect(mat.steel, 49, 0.9, -23, 2.4, 1.8, 4);
  rect(mat.blue, 49, 2, -23, 2.6, 0.12, 4.2);
  for (const z of [16, 25]) rect(warm, 35, 4.04, z, 9, 0.06, 0.2);
  // Espaço de apoio interno: bebedouro visível e sanitário reservado.
  rect(mat.steel, 38.3, 0.72, 13.5, 0.65, 1.35, 0.62);
  rect(mat.blue, 38.3, 1.49, 13.5, 0.42, 0.22, 0.44);
  addMesh(root, new T.CylinderGeometry(0.23, 0.19, 0.5, 12),
    new T.MeshStandardMaterial({color:0x84c9ed,transparent:true,opacity:0.75}),
    38.3, 1.85, 13.5);
  rect(dark, 38.02, 1.16, 13.32, 0.12, 0.08, 0.16);
  panel("ÁGUA", 38.35, 2.32, 12.98, 1.6, 0.35, Math.PI, 58);
  // Divisórias deixam o interior do banheiro discreto; a porta fica na lateral.
  rect(mat.white, 42.85, 1.24, 13.7, 0.14, 2.48, 2.1);
  rect(mat.white, 42.1, 1.24, 14.72, 1.6, 2.48, 0.13);
  rect(mat.blue, 42.7, 1.22, 12.65, 0.1, 2.4, 0.7);
  panel("WC • EQUIPE", 41.8, 2.45, 12.52, 2.25, 0.39, Math.PI, 43);
  // IA-03 | Cantinho de descanso visível junto à parede lateral da unidade.
  // Mantém corredor central e rotas para bebedouro, banheiro e escolta livres.
  const timber = new T.MeshStandardMaterial({color:0x93694a,roughness:0.86});
  const cushion = new T.MeshStandardMaterial({color:0x346273,roughness:0.95});
  rect(timber, 43.1, 0.63, 23.2, 1.25, 0.12, 0.8); // mesa de apoio
  for (const x of [42.58,43.62]) for(const z of [22.87,23.53])
    rect(dark,x,0.32,z,0.08,0.6,0.08);
  rect(mat.steel,43.35,1.25,20.3,0.85,1.1,0.38); // armário
  rect(cushion,42.65,0.55,25.0,1.55,0.23,0.62); // banco
  rect(dark,43.32,0.95,25.0,0.14,0.84,0.64);
  for (const x of [42,43.25])rect(dark,x,0.27,25.0,0.1,0.51,0.48);
  const coffee = new T.MeshStandardMaterial({color:0x202f34,metalness:0.55,roughness:0.4});
  addMesh(root,new T.CylinderGeometry(0.12,0.15,0.23,8),coffee,43.05,0.83,23.2);
  addMesh(root,new T.CylinderGeometry(0.095,0.095,0.09,8),mat.white,43.3,0.77,23.0);
  panel("DESCANSO • EQUIPE",42.15,2.75,23.0,3.0,0.43,Math.PI,35);
  for (const m of root.children.slice(officeStart)) {
    if (m.position.x < 46) m.position.y += BASE_HEIGHT;
  }
  // Raised platform, broad steps, accessible ramp and planted beds.
  rect(mat.concrete, 35, 0.3, 19.5, 19, 0.6, 21);
  for (let i = 0; i < 3; i++)
    rect(mat.concrete, 34.85, (i + 1) * 0.1, 6.5 + i, 3.7, (i + 1) * 0.2, 1);
  const ramp = rect(mat.concrete, 37.85, 0.3, 6, 2.3, 0.1, 6.03);
  ramp.rotation.x = -Math.atan(0.6 / 6);
  const grass = new T.MeshStandardMaterial({ color: 0x58743d, roughness: 1 });
  for (const [x, w] of [
    [29.4, 6.4],
    [41.6, 4.2],
  ]) {
    rect(mat.concrete, x, 0.17, 6, w, 0.34, 4);
    rect(grass, x, 0.36, 6, w - 0.24, 0.08, 3.76);
  }
  for (let i = 0; i < 7; i++)
    rect(mat.white, 27 + i * 4.1, 0.09, -13, 0.1, 0.025, 7);
  for (const z of [-16.5, -9.5])
    rect(mat.white, 39.3, 0.09, z, 24.6, 0.025, 0.1);
  // Água e sanitário de apoio no acostamento para agentes de fiscalização.
  rect(mat.steel, -9.55, 0.68, -17, 0.54, 1.3, 0.52);
  rect(mat.blue, -9.55, 1.38, -17, 0.52, 0.22, 0.56);
  addMesh(root,new T.CylinderGeometry(0.18,0.17,0.42,10),
    new T.MeshStandardMaterial({color:0x89c9de,transparent:true,opacity:0.7}),
    -9.55,1.7,-17);
  rect(mat.blue,-10.25,1.12,-24.4,1.45,2.24,1.55);
  rect(mat.white,-10.25,2.28,-24.4,1.55,0.1,1.65);
  panel("WC", -10.21, 1.75, -25.2, 0.85, 0.36, Math.PI, 60);
  // A chair opposite the commander, offset from the monitor's silhouette.
  rect(dark, 31.7, BASE_HEIGHT + 0.48, 15.5, 0.7, 0.15, 0.7);
  rect(mat.blue, 32.05, BASE_HEIGHT + 0.9, 15.5, 0.1, 0.8, 0.7);
  for (const x of [31.45, 31.95])
    for (const z of [15.25, 15.75])
      rect(dark, x, BASE_HEIGHT + 0.25, z, 0.06, 0.5, 0.06);
  const commandDoors = [];
  for (const sign of [-1, 1]) {
    const door = new T.Group();
    door.position.set(33, BASE_HEIGHT + 1.65, 16 + sign * 0.85);
    addMesh(door, new T.BoxGeometry(0.08, 3.3, 1.65), glass, 0, 0, 0);
    for (const y of [-1.6, 1.6])
      addMesh(door, new T.BoxGeometry(0.12, 0.08, 1.7), dark, 0, y, 0);
    for (const z of [-0.8, 0.8])
      addMesh(door, new T.BoxGeometry(0.12, 3.3, 0.06), dark, 0, 0, z);
    scene.add(door);
    commandDoors.push(door);
  }
  // Equipment is a separate group so cones can appear one-by-one and be removed.
  const blitzEquipment = new T.Group();
  blitzEquipment.name = "Equipamento temporário da blitz";
  scene.add(blitzEquipment);
  const coneMeshes = [];
  const signMeshes = [];
  const orange = new T.MeshStandardMaterial({
    color: 0xe98036,
    roughness: 0.8,
  });
  for (const cone of BLITZ_CONES) {
    const marker = new T.Group();
    marker.position.set(cone.x, 0, cone.z);
    blitzEquipment.add(marker);
    addMesh(marker, new T.ConeGeometry(0.23, 0.7, 10), orange, 0, 0.4, 0);
    addMesh(marker, new T.BoxGeometry(0.31, 0.12, 0.31), mat.white, 0, 0.39, 0);
    addMesh(marker, new T.BoxGeometry(0.48, 0.1, 0.48), dark, 0, 0.06, 0);
    coneMeshes.push(marker);
    marker.visible = false;
  }
  for (const z of [-62, -28]) {
    const pole = addMesh(blitzEquipment, new T.BoxGeometry(0.12, 1.8, 0.12), dark, -10.3, 0.9, z);
    const sign = panel(z < -30 ? "BLITZ • REDUZA" : "FISCALIZAÇÃO", -10.3, 1.85, z, 3.4, 0.9, Math.PI, 51);
    root.remove(sign);
    blitzEquipment.add(sign);
    signMeshes.push(pole, sign);
  }
  rect(mat.white, -3.4, 0.08, 2, 3.4, 0.02, 0.22);
  for (const z of [11, 25]) rect(mat.yellow, -9, 0.08, z, 4, 0.02, 0.1);
  for (const x of [-11, -7]) rect(mat.yellow, x, 0.08, 18, 0.1, 0.02, 14);
  const boardCanvas = document.createElement("canvas");
  boardCanvas.width = 512;
  boardCanvas.height = 192;
  const boardMap = new T.CanvasTexture(boardCanvas);
  boardMap.colorSpace = T.SRGBColorSpace;
  rect(dark, 17, 1.35, 3, 0.1, 2.7, 0.1);
  addMesh(
    root,
    new T.PlaneGeometry(4.2, 1.6),
    new T.MeshBasicMaterial({ map: boardMap, toneMapped: false }),
    17,
    2.8,
    2.94,
  ).rotation.y = Math.PI;
  mergeGroup(root);
  root.traverse((m) => {
    if (m.isMesh) {
      m.receiveShadow = true;
      m.castShadow = m.material !== glass;
    }
  });
  // Cheap broad contact shade is also available on mobile, where shadow maps stay off.
  const shade = addMesh(
    scene,
    new T.PlaneGeometry(40, 33).rotateX(-Math.PI / 2),
    new T.MeshBasicMaterial({
      color: 0x14212a,
      transparent: true,
      opacity: mobile ? 0.19 : 0.08,
      depthWrite: false,
    }),
    4.5,
    0.115,
    12.5,
  );
  const computer = createComputerScreen(scene);
  computer.mesh.position.y += BASE_HEIGHT;
  let boardElapsed = 10;
  return {
    root,
    shade,
    glass,
    computer,
    update(dt, state, sim) {
      const deployed = state.conesPlaced ?? 0;
      coneMeshes.forEach((m, i) => (m.visible = i < deployed));
      signMeshes.forEach(m => (m.visible = deployed > 0));
      computer.update(sim);
      commandDoors.forEach(
        (door, i) =>
          (door.position.z = 16 + (i ? 1 : -1) * (0.85 + sim.roomDoor * 1.65)),
      );
      boardElapsed += dt;
      if (boardElapsed < 0.8) return;
      boardElapsed = 0;
      const c = boardCanvas.getContext("2d");
      c.fillStyle = "#152d36";
      c.fillRect(0, 0, 512, 192);
      c.fillStyle = "#f6d671";
      c.textAlign = "center";
      c.font = "bold 36px Arial";
      c.fillText("BLITZ • PRF", 256, 43);
      c.fillStyle = "#d8e7df";
      c.font = "23px Arial";
      c.fillText(state.status, 256, 99, 488);
      c.font = "21px Arial";
      c.fillText(`${state.completed} VEÍCULO(S) LIBERADO(S)`, 256, 150);
      boardMap.needsUpdate = true;
    },
  };
}
