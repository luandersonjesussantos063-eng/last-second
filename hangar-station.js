import * as THREE from "./vendor/engine.js";
import {
  FLOOR_Y,
  EYE_HEIGHT,
  ROOMS,
  DOOR_HALF_WIDTH,
  moveWalker,
} from "./station-layout.js";

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
    box(side * 25.5, 3.2, 96, 17, 18, 1.2, dark);
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
  // A light external ship proxy: visible only when outside the cockpit.
  const ship = new THREE.Group();
  root.add(ship);
  ship.visible = false;
  const hull = mesh(
    new THREE.SphereGeometry(1, 16, 10),
    metal,
    0,
    -2.6,
    8,
    ship,
  );
  hull.scale.set(2.8, 1.6, 6);
  const canopy = mesh(
    new THREE.SphereGeometry(1, 16, 10),
    blue,
    0,
    -1.3,
    10,
    ship,
  );
  canopy.scale.set(1.7, 1, 2.5);
  for (const side of [-1, 1]) {
    const wing = box(side * 4, -3, 6, 5, 0.35, 5, metal, ship);
    wing.rotation.z = side * 0.12;
    const engine = mesh(
      new THREE.CapsuleGeometry(0.55, 3.8, 3, 8),
      dark,
      side * 2.4,
      -2.5,
      4,
      ship,
    );
    engine.rotation.x = Math.PI / 2;
    box(side * 2, -4.55, 7, 0.3, 1.3, 0.3, pale, ship);
    box(side * 2, -5.05, 7, 1.1, 0.25, 1.6, dark, ship);
  }
  // Boarding ramp is accessible from the starboard side.
  const ramp = box(4.5, -4.5, 10, 3, 0.16, 2, metal, ship);
  ramp.rotation.z = -0.38;
  const boardPoint = { x: 7.4, z: 10 };
  sign("EMBARQUE", 5.2, -1.7, 10, Math.PI / 2, "#a9edff", 2.4);
  const shipObstacle = { x: 0, z: 8, hx: 6.6, hz: 6.2 };

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

  // Humanoid crew share six instanced batches, including animated arms and legs.
  const crew = Array.from({ length: mobile ? 6 : 8 }, (_, i) => {
    const room = ROOMS[(i - 4 + ROOMS.length) % ROOMS.length];
    const side = i < 4 ? (i % 2 ? 1 : -1) : room.side;
    const z = i < 4 ? 20 + (i % 4) * 17 : room.z;
    const path =
      i < 4
        ? [
            [side * 28, z],
            [side * 28, z + 10],
            [side * 22, z + 10],
            [side * 22, z],
          ]
        : [
            [side * 39, z],
            [side * 43, z],
            [side * 43, z + 4],
            [side * 39, z + 4],
          ];
    return {
      x: path[0][0],
      z: path[0][1],
      path,
      next: 1,
      yaw: 0,
      phase: i,
      speed: 0.8 + i * 0.055,
    };
  });
  const skin = new THREE.MeshStandardMaterial({
    color: 0xc6a18a,
    roughness: 0.8,
  });
  const uniform = new THREE.MeshStandardMaterial({
    color: 0x428393,
    roughness: 0.7,
  });
  const crewParts = [
    [new THREE.CapsuleGeometry(0.22, 0.45, 3, 8), uniform, 0, 1.16, 0],
    [new THREE.SphereGeometry(0.18, 10, 6), skin, 0, 1.76, 0],
    [new THREE.CapsuleGeometry(0.075, 0.48, 3, 6), uniform, -0.31, 1.13, -1],
    [new THREE.CapsuleGeometry(0.075, 0.48, 3, 6), uniform, 0.31, 1.13, 1],
    [new THREE.CapsuleGeometry(0.095, 0.52, 3, 6), dark, -0.13, 0.44, 1],
    [new THREE.CapsuleGeometry(0.095, 0.52, 3, 6), dark, 0.13, 0.44, -1],
  ].map(([geometry, material, x, y, swing]) => {
    const instances = new THREE.InstancedMesh(geometry, material, crew.length);
    instances.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    instances.frustumCulled = false;
    root.add(instances);
    return { instances, x, y, swing };
  });
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
  const allProps = [...props, shipObstacle];
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
    return Math.hypot(position.x - boardPoint.x, position.z - boardPoint.z) < 3;
  }
  function update(dt, time, keys) {
    for (const person of crew) {
      const target = person.path[person.next],
        dx = target[0] - person.x,
        dz = target[1] - person.z;
      const distance = Math.hypot(dx, dz),
        step = Math.min(distance, dt * person.speed);
      if (distance > 0.001) {
        person.x += (dx / distance) * step;
        person.z += (dz / distance) * step;
        person.yaw = Math.atan2(dx, dz);
      }
      if (distance < 0.12) person.next = (person.next + 1) % person.path.length;
      person.phase += step * 5;
    }
    for (const door of doors) {
      const nearby =
        active &&
        Math.hypot(position.x - door.side * 34, position.z - door.z) < 5.5;
      const occupied =
        active &&
        Math.abs(position.x - door.side * 34) < 1 &&
        Math.abs(position.z - door.z) < 3;
      if (nearby || occupied) door.hold = 1.5;
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
      const label = room ? room.name : "HANGAR ALPHA-01";
      if (zoneText.textContent !== label) zoneText.textContent = label;
    }
    for (const part of crewParts) {
      crew.forEach((person, i) => {
        body.position.set(person.x, FLOOR_Y, person.z);
        body.rotation.y = person.yaw;
        body.updateMatrix();
        dummy.position.set(part.x, part.y, 0);
        dummy.rotation.set(Math.sin(person.phase) * 0.42 * part.swing, 0, 0);
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
