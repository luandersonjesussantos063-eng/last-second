import * as THREE from "./vendor/engine.js";
import { createUniformedCrew } from "./crew-uniforms.js?v=1.14.0";
import {
  FLOOR_Y,
  EYE_HEIGHT,
  ROOMS,
  DOOR_HALF_WIDTH,
  UPPER_FLOOR,
  moveWalker,
} from "./station-layout.js?v=1.14.0";
import {
  StationTraffic,
  createStationWorkers,
  updateStationWorkers,
  FLIGHT_LABELS,
} from "./station-operations.js?v=1.14.0";
import {
  addStationTechnology,
  createTrafficCraft,
} from "./station-technology.js?v=1.14.0";

export function createHangarStation(scene, camera, canvas, mobile, isBlocked) {
  const root = new THREE.Group();
  scene.add(root);
  const metal = new THREE.MeshStandardMaterial({
    color: 0x435668,
    metalness: 0.55,
    roughness: 0.5,
  });
  const dark = new THREE.MeshStandardMaterial({
    color: 0x172633,
    metalness: 0.45,
    roughness: 0.6,
  });
  const pale = new THREE.MeshStandardMaterial({
    color: 0xb3cad0,
    metalness: 0.15,
    roughness: 0.7,
  });
  const blue = new THREE.MeshStandardMaterial({
    color: 0x286785,
    metalness: 0.5,
    roughness: 0.4,
  });
  const glow = new THREE.MeshBasicMaterial({
    color: 0x9deaff,
    toneMapped: false,
  });
  const fixed = new Map(),
    props = [],
    doors = [];
  function mesh(geometry, material, x, y, z, parent = root, batch = true) {
    const object = new THREE.Mesh(geometry, material);
    object.position.set(x, y, z);
    parent.add(object);
    if (batch && parent === root) {
      if (!fixed.has(material)) fixed.set(material, []);
      fixed.get(material).push(object);
    }
    return object;
  }
  function box(
    x,
    y,
    z,
    w,
    h,
    d,
    material = metal,
    parent = root,
    batch = true,
  ) {
    return mesh(
      new THREE.RoundedBoxGeometry(
        w,
        h,
        d,
        1,
        Math.min(0.15, w / 6, h / 6, d / 6),
      ),
      material,
      x,
      y,
      z,
      parent,
      batch,
    );
  }
  function solid(x, z, w, d, y, h, material = metal) {
    box(x, y, z, w, h, d, material);
    props.push({ x, z, hx: w / 2, hz: d / 2 });
  }
  function sign(text, x, y, z, rotation, color = "#a9edff", width = 5.5) {
    const c = document.createElement("canvas");
    c.width = 512;
    c.height = 128;
    const ctx = c.getContext("2d");
    ctx.fillStyle = "#0c1b29";
    ctx.fillRect(0, 0, 512, 128);
    ctx.strokeStyle = color;
    ctx.lineWidth = 5;
    ctx.strokeRect(5, 5, 502, 118);
    ctx.fillStyle = color;
    ctx.font = "bold 34px Arial";
    ctx.textAlign = "center";
    ctx.fillText(text, 256, 76, 480);
    const texture = new THREE.CanvasTexture(c);
    texture.colorSpace = THREE.SRGBColorSpace;
    const label = mesh(
      new THREE.PlaneGeometry(width, width / 4),
      new THREE.MeshBasicMaterial({ map: texture, toneMapped: false }),
      x,
      y,
      z,
    );
    label.rotation.y = rotation;
  }
  for (const side of [-1, 1]) {
    // Split the lateral wall around two actual passageways.
    let previous = -15;
    for (const z of [24, 62]) {
      const edge = z - DOOR_HALF_WIDTH;
      box(side * 34, 3.2, (previous + edge) / 2, 1.2, 18, edge - previous);
      box(side * 34, 5.3, z, 1.2, 13.4, DOOR_HALF_WIDTH * 2);
      previous = z + DOOR_HALF_WIDTH;
    }
    box(side * 34, 3.2, (previous + 96) / 2, 1.2, 18, 96 - previous);
    // A separate pedestrian lane keeps crew and players away from the runway.
    for (let z = -8; z <= 88; z += 8) {
      box(side * 25, FLOOR_Y + 0.04, z, 0.12, 0.06, 5, glow);
    }
    // The upper right facade is glazed for the command room's space view.
    box(
      side * 25.5,
      side > 0 ? -1.75 : 3.2,
      96,
      17,
      side > 0 ? 6.9 : 18,
      1.2,
      dark,
    );
    for (const z of [-5, 10, 40, 78, 89]) {
      box(side * 33.28, 0.2, z, 0.12, 3.3, 7, dark);
      box(side * 33.18, -1.7, z, 0.14, 0.08, 7, glow);
    }
  }
  for (const room of ROOMS) {
    const { side, z, kind } = room,
      x = side * 44;
    const accent = new THREE.MeshBasicMaterial({
      color: room.color,
      toneMapped: false,
    });
    box(x, -5.8, z, 20, 1.2, 20, metal);
    box(x, 1.5, z, 20, 0.6, 20, dark);
    box(side * 54, -1.8, z, 1.2, 7, 20, metal);
    for (const end of [-10, 10]) box(x, -1.8, z + end, 20, 7, 1.2, metal);
    box(x, 1.12, z, 14, 0.08, 0.4, accent);
    for (const edge of [-2.65, 2.65])
      box(side * 33.28, -3.1, z + edge, 0.14, 4.4, 0.15, accent);
    sign(
      room.name,
      side * 33.25,
      -0.35,
      z,
      (-side * Math.PI) / 2,
      "#" + room.color.toString(16).padStart(6, "0"),
    );
    sign(room.name, side * 53.3, -0.3, z, (-side * Math.PI) / 2);
    const panels = [];
    for (const edge of [-1, 1]) {
      const panel = box(
        side * 34,
        -3.3,
        z + edge * 1.2,
        0.25,
        3.8,
        2.4,
        blue,
        root,
        false,
      );
      panels.push(panel);
    }
    doors.push({ ...room, open: 0, hold: 0, panels });
    if (kind === "quarters" || kind === "medical") {
      for (const offset of [-5.6, 5.6]) {
        solid(side * 49.5, z + offset, 5, 2.2, -4.35, 1.6, dark);
        box(side * 49.5, -3.48, z + offset, 4.8, 0.25, 2, pale);
        box(
          side * 51,
          -3.25,
          z + offset,
          1,
          0.3,
          1.7,
          kind === "medical" ? pale : blue,
        );
      }
      if (kind === "medical") {
        box(side * 53.3, -1.3, z, 0.15, 1.8, 0.55, accent);
        box(side * 53.3, -1.3, z, 0.15, 0.55, 1.8, accent);
      } else solid(side * 51, z, 3, 2.5, -3.8, 2.8, metal);
    } else {
      solid(side * 50, z, 3.4, 11, -4.3, 1.8, dark);
      for (const offset of [-3.5, 0, 3.5]) {
        const panel = box(side * 50, -2.9, z + offset, 0.15, 1.2, 2.3, accent);
        panel.rotation.z = -side * 0.25;
        if (kind === "command")
          solid(side * 46.5, z + offset, 1.2, 1.2, -4.5, 1.4, blue);
      }
      if (kind === "workshop") {
        for (const offset of [-6, 6])
          solid(side * 42, z + offset, 2.4, 2.4, -4.2, 2, metal);
      }
    }
  }
  sign("ALPHA 01 • HANGAR", 0, 5.6, -14.3, 0, "#c6f6ff", 15);
  // The player's parked ship shares the patrol's police identity.
  const playerModel = createTrafficCraft(
    { metal, dark, blue, glow },
    0xdce6ed,
    "ALPHA-1",
  );
  const ship = playerModel.group;
  root.add(ship);
  ship.visible = false;
  ship.position.set(0, -2.08, 8);
  ship.rotation.y = Math.PI;
  ship.scale.setScalar(1.2);
  playerModel.hatch.rotation.z = 0.8;
  playerModel.exhaust.visible = false;
  const boardPoint = { x: 7.4, z: 10 };
  sign("EMBARQUE", 5.2, -1.7, 10, Math.PI / 2, "#a9edff", 2.4);
  const shipObstacle = { x: 0, z: 8, hx: 6.6, hz: 6.2 };
  const traffic = new StationTraffic();
  let workers = createStationWorkers();
  const crew = [...workers, ...traffic.ships.map((s) => s.pilot)];
  const materials = { metal, dark, blue, glow };
  const craft = traffic.ships.map((s, i) => {
    const model = createTrafficCraft(
      materials,
      [0x708da5, 0xac895d, 0x5a9190][i],
      s.id,
    );
    model.group.position.set(s.x, s.y, s.z);
    root.add(model.group);
    return model;
  });
  const technology = addStationTechnology({
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
  });
  const craftProps = traffic.ships.map((s) => ({
    x: s.x,
    z: s.z,
    hx: 4.6,
    hz: 4.7,
  }));

  // Merge fixed props by material. Dynamic doors and crew remain separate.
  for (const [material, objects] of fixed) {
    const geometries = objects.map((object) => {
      object.updateMatrix();
      const geometry = object.geometry.index
        ? object.geometry.toNonIndexed()
        : object.geometry.clone();
      geometry.applyMatrix4(object.matrix);
      root.remove(object);
      object.geometry.dispose();
      return geometry;
    });
    const combined = THREE.mergeGeometries(geometries);
    root.add(new THREE.Mesh(combined, material));
    for (const geometry of geometries) geometry.dispose();
  }

  const { parts: crewParts, profiles: crewProfiles } = createUniformedCrew(
    root,
    crew,
    dark,
    blue,
  );
  const dummy = new THREE.Object3D(),
    body = new THREE.Object3D();
  const position = new THREE.Vector3(
    boardPoint.x,
    FLOOR_Y + EYE_HEIGHT,
    boardPoint.z,
  );
  let active = false,
    yaw = -Math.PI * 0.85,
    pitch = 0,
    bob = 0,
    lookId = null,
    moveId = null;
  let lookX = 0,
    lookY = 0,
    stickX = 0,
    stickY = 0,
    moveX = 0,
    moveY = 0;
  const walkHud = document.getElementById("walkHud"),
    zoneText = document.getElementById("walkZone");
  const pad = document.getElementById("walkPad"),
    nub = document.getElementById("walkNub");
  const allProps = [...props, shipObstacle, ...craftProps];
  for (const side of [-1, 1])
    for (let z = -8; z <= 92; z += 20)
      allProps.push({ x: side * 32.7, z, hx: 0.55, hz: 0.75 });
  function release() {
    lookId = moveId = null;
    moveX = moveY = 0;
    nub.style.transform = "translate(-50%, -50%)";
    if (document.pointerLockElement === canvas) document.exitPointerLock();
  }
  function look(dx, dy) {
    yaw -= dx * 0.003;
    pitch = THREE.MathUtils.clamp(pitch - dy * 0.003, -1.25, 1.25);
  }
  canvas.addEventListener("pointerdown", (event) => {
    if (!active || isBlocked() || lookId !== null) return;
    lookId = event.pointerId;
    lookX = event.clientX;
    lookY = event.clientY;
    try {
      canvas.setPointerCapture(event.pointerId);
    } catch {}
    if (event.pointerType === "mouse" && canvas.requestPointerLock) {
      try {
        canvas.requestPointerLock()?.catch(() => {});
      } catch {}
    }
    event.preventDefault();
  });
  canvas.addEventListener("pointermove", (event) => {
    if (!active || isBlocked()) return;
    if (document.pointerLockElement === canvas) return;
    if (lookId !== event.pointerId) return;
    look(event.clientX - lookX, event.clientY - lookY);
    lookX = event.clientX;
    lookY = event.clientY;
  });
  document.addEventListener("mousemove", (event) => {
    if (active && !isBlocked() && document.pointerLockElement === canvas)
      look(event.movementX, event.movementY);
  });
  function endLook(event) {
    if (event.pointerId === lookId) lookId = null;
  }
  for (const type of ["pointerup", "pointercancel", "lostpointercapture"])
    canvas.addEventListener(type, endLook);
  pad.addEventListener("pointerdown", (event) => {
    if (!active || isBlocked() || moveId !== null) return;
    moveId = event.pointerId;
    const rect = pad.getBoundingClientRect();
    stickX = rect.left + rect.width / 2;
    stickY = rect.top + rect.height / 2;
    try {
      pad.setPointerCapture(event.pointerId);
    } catch {}
    updateStick(event);
    event.preventDefault();
  });
  function updateStick(event) {
    if (event.pointerId !== moveId) return;
    const dx = event.clientX - stickX,
      dy = event.clientY - stickY,
      length = Math.max(38, Math.hypot(dx, dy));
    moveX = dx / length;
    moveY = dy / length;
    nub.style.transform = `translate(-50%, -50%) translate(${moveX * 32}px, ${moveY * 32}px)`;
  }
  pad.addEventListener("pointermove", updateStick);
  for (const type of ["pointerup", "pointercancel", "lostpointercapture"])
    pad.addEventListener(type, (event) => {
      if (event.pointerId === moveId) {
        moveId = null;
        moveX = moveY = 0;
        nub.style.transform = "translate(-50%, -50%)";
      }
    });

  function enter() {
    active = true;
    position.set(boardPoint.x, FLOOR_Y + EYE_HEIGHT, boardPoint.z);
    yaw = -Math.PI * 0.85;
    pitch = 0;
    bob = 0;
    scene.add(camera);
    camera.fov = 75;
    camera.updateProjectionMatrix();
    walkHud.hidden = false;
    pad.hidden = !mobile;
    ship.visible = true;
    release();
  }
  function leave() {
    active = false;
    walkHud.hidden = true;
    pad.hidden = true;
    ship.visible = false;
    release();
  }
  function canBoard() {
    return (
      Math.abs(position.y - FLOOR_Y - EYE_HEIGHT) < 0.3 &&
      Math.hypot(position.x - boardPoint.x, position.z - boardPoint.z) < 3
    );
  }
  function update(dt, time, keys, flight = {}) {
    traffic.update(dt, {
      playerPriority: flight.playerPriority,
      walker: active ? position : null,
    });
    updateStationWorkers(workers, dt, traffic.ships);
    if (root.visible) technology.update(dt, time, traffic, workers);
    traffic.ships.forEach((s, i) => {
      const model = craft[i];
      model.group.position.set(s.x, s.y, s.z);
      model.group.rotation.y = s.yaw;
      model.hatch.rotation.z = s.hatch * 0.8;
      model.hatch.position.y = 1.4 + s.hatch * 0.5;
      model.exhaust.visible = s.thruster > 0;
      model.exhaust.scale.set(
        1,
        1,
        0.3 + s.thruster * (1 + Math.sin(time * 0.025) * 0.1),
      );
      model.lights.forEach((lamp, index) => {
        lamp.visible = Math.floor(time / 420) % 2 === index;
      });
      craftProps[i].x = s.y > 0 ? 10000 : s.x;
      craftProps[i].z = s.z;
    });
    playerModel.lights.forEach((lamp, index) => {
      lamp.visible = Math.floor(time / 550) % 2 === index;
    });
    for (const door of doors) {
      const nearby =
        active &&
        Math.abs(position.y - FLOOR_Y - EYE_HEIGHT) < 0.4 &&
        Math.hypot(position.x - door.side * 34, position.z - door.z) < 5.5;
      const occupied =
        active &&
        Math.abs(position.y - FLOOR_Y - EYE_HEIGHT) < 0.4 &&
        Math.abs(position.x - door.side * 34) < 1 &&
        Math.abs(position.z - door.z) < 3;
      const workerNearby = crew.some(
        (p) =>
          p.visible &&
          Math.abs(p.y - FLOOR_Y) < 0.2 &&
          Math.hypot(p.x - door.side * 34, p.z - door.z) < 3,
      );
      if (nearby || occupied || workerNearby) door.hold = 1.5;
      else door.hold = Math.max(0, door.hold - dt);
      door.open = THREE.MathUtils.damp(door.open, door.hold > 0 ? 1 : 0, 5, dt);
      door.panels.forEach((panel, i) => {
        panel.position.z = door.z + (i ? 1 : -1) * (1.2 + door.open * 2.4);
      });
    }
    if (active) {
      let forward =
        Number(keys.has("KeyW") || keys.has("ArrowUp")) -
        Number(keys.has("KeyS") || keys.has("ArrowDown")) -
        moveY;
      let strafe =
        Number(keys.has("KeyD") || keys.has("ArrowRight")) -
        Number(keys.has("KeyA") || keys.has("ArrowLeft")) +
        moveX;
      const magnitude = Math.max(1, Math.hypot(forward, strafe));
      forward /= magnitude;
      strafe /= magnitude;
      const speed = keys.has("ShiftLeft") || keys.has("ShiftRight") ? 5.2 : 3.3;
      const oldX = position.x,
        oldZ = position.z;
      moveWalker(
        position,
        (-Math.sin(yaw) * forward + Math.cos(yaw) * strafe) * speed * dt,
        (-Math.cos(yaw) * forward - Math.sin(yaw) * strafe) * speed * dt,
        doors,
        allProps,
      );
      const moved = Math.hypot(position.x - oldX, position.z - oldZ);
      bob += moved * 5;
      camera.position.set(
        position.x,
        position.y + (moved > 0.001 ? Math.sin(bob) * 0.025 : 0),
        position.z,
      );
      camera.rotation.set(pitch, yaw, 0, "YXZ");
      const room = ROOMS.find(
        (r) => position.x * r.side > 34 && Math.abs(position.z - r.z) < 10,
      );
      const label =
        position.y > UPPER_FLOOR + 1
          ? position.z > 62
            ? "CENTRAL DE COMANDO • PISO 2"
            : "PASSARELA • PISO 2"
          : room
            ? room.name
            : "HANGAR ALPHA-01";
      if (zoneText.textContent !== label) zoneText.textContent = label;
      const nearbyWorker = crew.find(
        (p) =>
          p.visible &&
          Math.abs(p.y + EYE_HEIGHT - position.y) < 1 &&
          Math.hypot(p.x - position.x, p.z - position.z) < 3,
      );
      const activity = nearbyWorker
        ? `${nearbyWorker.role} · ${{ walking: "A CAMINHO DO POSTO", typing: "OPERANDO CONSOLE", repair: "MANUTENÇÃO", scan: "INSPEÇÃO", briefing: "RELATÓRIO DE VOO" }[nearbyWorker.action] ?? "EM SERVIÇO"}`
        : traffic.owner
          ? `TRÁFEGO: ${traffic.owner} · ${FLIGHT_LABELS[traffic.ships.find((s) => s.id === traffic.owner).state]}`
          : "PISTA LIVRE · RAMPA À DIREITA PARA A CENTRAL";
      if (document.getElementById("walkActivity").textContent !== activity)
        document.getElementById("walkActivity").textContent = activity;
    }
    if (!root.visible) return;
    for (const part of crewParts) {
      part.indices.forEach((index, i) => {
        const person = crew[index];
        body.position.set(person.x, person.y, person.z);
        body.rotation.y = person.yaw;
        body.updateMatrix();
        dummy.scale.setScalar(person.visible ? 1 : 0);
        dummy.position.set(part.x, part.y, part.z);
        let angle =
          person.moving || person.action === "walking"
            ? Math.sin(person.phase) * 0.42 * part.swing
            : 0;
        if (part.arm)
          angle = person.moving
            ? angle
            : person.action === "repair"
              ? -0.9 + Math.sin(person.phase) * 0.28
              : -0.8 + Math.sin(person.phase) * 0.08;
        if (part.swing === 2) {
          angle = 0;
          if (
            person.action !== "scan" &&
            person.action !== "briefing" &&
            person.action !== "repair"
          )
            dummy.scale.setScalar(0);
        }
        dummy.rotation.set(angle, 0, 0);
        dummy.updateMatrix();
        dummy.matrix.premultiply(body.matrix);
        part.instances.setMatrixAt(i, dummy.matrix);
      });
      part.instances.instanceMatrix.needsUpdate = true;
    }
  }
  return {
    root,
    position,
    doors,
    crew,
    props: allProps,
    traffic,
    technology,
    crewProfiles,
    resetOperations() {
      traffic.reset();
      workers = createStationWorkers();
      crew.splice(
        0,
        crew.length,
        ...workers,
        ...traffic.ships.map((s) => s.pilot),
      );
    },
    enter,
    leave,
    release,
    update,
    canBoard,
    get active() {
      return active;
    },
  };
}
