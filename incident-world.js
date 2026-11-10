// Cenário 3D do atendimento COPOM: objetos e agentes reais no mundo.
// Construído com geometrias locais; sem textura remota nem asset pesado.
import { createFreightTruck } from "./freight-world.js?v=2.23.1";
import * as T from "./vendor/engine.js?v=2.23.1";
const mesh = (parent, g, m, x = 0, y = 0, z = 0) => {
  const o = new T.Mesh(g, m);
  o.position.set(x, y, z);
  o.receiveShadow = true;
  parent.add(o);
  return o;
};
const mat = (color, metalness = 0) =>
  new T.MeshStandardMaterial({ color, roughness: 0.74, metalness });
const orange = mat(0xf16d21),
  white = mat(0xf0eeea),
  red = mat(0xda3928);
const yellow = mat(0xe6c443),
  dark = mat(0x202b32),
  blue = mat(0x1b3552),
  skin = mat(0xb48b6f);
function cube(parent, m, x, y, z, w, h, d) {
  return mesh(parent, new T.BoxGeometry(w, h, d), m, x, y, z);
}
function makeCone(parent, x, z) {
  const g = new T.Group();
  g.position.set(x, 0, z);
  parent.add(g);
  cube(g, dark, 0, 0.045, 0, 0.6, 0.09, 0.6);
  mesh(g, new T.ConeGeometry(0.25, 0.8, 8), orange, 0, 0.49, 0);
  const rings = [0.31, 0.56];
  for (const y of rings)
    mesh(
      g,
      new T.CylinderGeometry(
        0.245 * (1 - y / 0.95),
        0.27 * (1 - y / 0.95),
        0.09,
        8,
      ),
      white,
      0,
      y,
      0,
    );
  return g;
}
function createActor(parent, police) {
  const g = new T.Group();
  parent.add(g);
  const coat = mat(police ? 0x182c4e : 0x906957),
    trousers = mat(police ? 0x1c2434 : 0x465c71);
  const body = mesh(
    g,
    new T.CapsuleGeometry(0.24, 0.53, 4, 8),
    coat,
    0,
    1.11,
    0,
  );
  const head = mesh(g, new T.SphereGeometry(0.18, 10, 8), skin, 0, 1.78, 0);
  const hat = police
    ? mesh(g, new T.CylinderGeometry(0.21, 0.23, 0.1, 10), dark, 0, 1.97, 0)
    : null;
  const left = mesh(
    g,
    new T.CapsuleGeometry(0.085, 0.36, 3, 6),
    coat,
    -0.32,
    1.13,
    0,
  );
  const right = mesh(
    g,
    new T.CapsuleGeometry(0.085, 0.36, 3, 6),
    coat,
    0.32,
    1.13,
    0,
  );
  for (const x of [-0.13, 0.13]) {
    mesh(g, new T.CapsuleGeometry(0.095, 0.46, 3, 6), trousers, x, 0.49, 0);
    cube(g, dark, x, 0.08, 0.1, 0.19, 0.15, 0.4);
  }
  if (police) {
    cube(g, yellow, 0, 1.36, 0.24, 0.34, 0.13, 0.035);
    mesh(g, new T.PlaneGeometry(0.25, 0.13), mat(0xf5d06d), 0, 1.54, 0.25);
  }
  return { g, left, right, body, head, hat };
}
function label(text, colors = { bg: "#112d40", fg: "#f8da62" }) {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 128;
  const x = c.getContext("2d");
  x.fillStyle = colors.bg;
  x.fillRect(0, 0, 512, 128);
  x.fillStyle = colors.fg;
  x.textAlign = "center";
  x.textBaseline = "middle";
  x.font = "bold 46px Arial";
  x.fillText(text, 256, 64, 485);
  const texture = new T.CanvasTexture(c);
  texture.colorSpace = T.SRGBColorSpace;
  return new T.MeshBasicMaterial({
    map: texture,
    side: T.DoubleSide,
    depthWrite: false,
  });
}
export function createIncidentWorld(scene, createVehicle, camera, mobile) {
  const root = new T.Group();
  scene.add(root);
  root.visible = false;
  const cones = new T.Group();
  root.add(cones);
  // Isolamento diagonal e duas barreiras de advertência na borda do acostamento.
  for (let n = 0; n < 7; n++)
    makeCone(cones, -0.1 + Math.sin(n * 0.65) * 1.05, -20 + n * 5.4);
  const barricade = new T.Group();
  cones.add(barricade);
  barricade.position.set(-1.3, 0.25, -21);
  cube(barricade, yellow, 0, 0.8, 0, 1.8, 0.42, 0.09);
  for (const x of [-0.62, 0, 0.62]) {
    const stripe = cube(barricade, dark, x, 0.8, 0.056, 0.21, 0.42, 0.025);
    stripe.rotation.z = -0.52;
  }
  for (const x of [-0.66, 0.66])
    cube(barricade, dark, x, 0.34, 0, 0.09, 0.7, 0.11);
  const labelPlane = mesh(
    root,
    new T.PlaneGeometry(6, 1.5),
    label("OCORRÊNCIA COPOM"),
    0,
    4.6,
    -20,
  );
  const skid = mesh(
    root,
    new T.PlaneGeometry(1.6, 6).rotateX(-Math.PI / 2),
    new T.MeshBasicMaterial({
      color: 0x1b2022,
      transparent: true,
      opacity: 0.55,
      depthWrite: false,
    }),
    0,
    0.08,
    0,
  );
  const impact = mesh(
    root,
    new T.BoxGeometry(1.8, 0.16, 2.2),
    mat(0x5e5144),
    1.1,
    0.07,
    0,
  );
  const debris = new T.Group();
  root.add(debris);
  for (let n = 0; n < 4; n++) {
    const o = cube(
      debris,
      n % 2 ? dark : mat(0x848c8c),
      0.4 + n * 0.27,
      0.2,
      (n - 2) * 0.6,
      0.45,
      0.38,
      0.39,
    );
    o.rotation.y = n * 0.77;
  }
  const driver = createActor(root, false);
  const officers = [createActor(root, true), createActor(root, true)];
  const stranded = createVehicle({
    kind: "hatchback",
    color: 0x9b4e4b,
    plate: "CIV-PANE",
  });
  scene.add(stranded.group);
  const truck = createFreightTruck(0x597d98);
  scene.add(truck.group);
  const crashed = createVehicle({
    kind: "sedan",
    color: 0xced5d7,
    plate: "CIV-COLISAO",
  });
  scene.add(crashed.group);
  const victim = createActor(root, false);
  victim.g.rotation.z = Math.PI / 2;
  const flames = [];
  for (let n = 0; n < 5; n++) {
    const flame = mesh(
      root,
      new T.ConeGeometry(0.25 + 0.07 * n, 0.8 + n * 0.1, 6),
      new T.MeshBasicMaterial({
        color: n % 2 ? 0xffd33a : 0xf76612,
        toneMapped: false,
      }),
      -0.65 + n * 0.23,
      1.4 + n * 0.08,
      0.6,
    );
    flames.push(flame);
  }
  const services = {};
  for (const kind of ["mechanic", "ambulance", "fire"]) {
    const colors = { mechanic: 0xd7aa54, ambulance: 0xe7ecea, fire: 0xb5342d };
    const vehicle = createVehicle({
      kind: kind === "mechanic" ? "van" : "pickup",
      color: colors[kind],
      plate:
        kind === "ambulance"
          ? "RESGATE"
          : kind === "fire"
            ? "BOMBEIROS"
            : "MECANICO",
    });
    scene.add(vehicle.group);
    const body = cube(
      vehicle.group,
      mat(colors[kind]),
      0,
      1.5,
      -0.7,
      2.15,
      1.4,
      2.7,
    );
    const beacons = [];
    for (const x of [-0.55, 0.55])
      beacons.push(
        cube(
          vehicle.group,
          new T.MeshBasicMaterial({
            color: kind === "mechanic" ? 0xffc13a : 0xf14432,
          }),
          x,
          2.3,
          0.8,
          0.4,
          0.18,
          0.3,
        ),
      );
    if (kind === "ambulance")
      for (const sign of [-1, 1]) {
        cube(vehicle.group, red, sign * 1.09, 1.7, -0.7, 0.03, 0.75, 0.2);
        cube(vehicle.group, red, sign * 1.11, 1.7, -0.7, 0.03, 0.2, 0.75);
      }
    if (kind === "fire")
      for (const x of [-0.75, 0.75])
        cube(vehicle.group, white, x, 2.3, -0.8, 0.1, 0.1, 2.4);
    const actor = createActor(root, false),
      old = actor.body.material,
      uniform = mat(
        { mechanic: 0x596a4b, ambulance: 0xe6ece7, fire: 0xe4b747 }[kind],
      );
    actor.g.traverse((o) => {
      if (o.material === old) o.material = uniform;
    });
    services[kind] = { vehicle, actor, beacons };
  }
  const support = createVehicle({ police: true, plate: "PRF-COPOM" });
  scene.add(support.group);
  const tow = createVehicle({
    kind: "pickup",
    color: 0xe7a329,
    plate: "SIM-GUINCHO",
  });
  scene.add(tow.group);
  // Lança de serviço e plataforma tornam a pickup uma silhueta de guincho reconhecível.
  cube(tow.group, dark, 0, 1.6, -1.38, 1.74, 0.23, 2.1);
  const boom = cube(tow.group, yellow, 0, 2.1, -1.1, 0.17, 0.19, 3.4);
  boom.rotation.x = -0.18;
  cube(tow.group, dark, 0, 1.31, -2.5, 0.55, 0.16, 0.7);
  const amber = new T.MeshBasicMaterial({ color: 0xffb52f });
  const beacon = cube(tow.group, amber, 0, 2.1, 0.5, 0.7, 0.19, 0.3);
  const smoke = [];
  if (!mobile)
    for (let n = 0; n < 5; n++) {
      const m = new T.MeshBasicMaterial({
        color: 0x9e9f9f,
        transparent: true,
        opacity: 0.18,
        depthWrite: false,
      });
      const puff = mesh(
        root,
        new T.SphereGeometry(0.45, 7, 5),
        m,
        -0.6,
        1.5 + n * 0.4,
        0.6,
      );
      smoke.push(puff);
    }
  return {
    group: root,
    officers,
    services,
    truck,
    victim,
    flames,
    update(s, dt) {
      const i = s.incident,
        observer = s.mode === "drive" ? s.car : s.player;
      const visible = !!i?.active && Math.abs(observer.z - i.site.z) < 680;
      root.visible = visible;
      stranded.group.visible =
        visible && i.vehicle.visible && i.kind !== "truck";
      truck.group.visible = visible && i.vehicle.visible && i.kind === "truck";
      crashed.group.visible =
        visible && ["collision", "fire"].includes(i.kind) && i.vehicle.visible;
      for (const kind of Object.keys(services)) {
        const model = services[kind],
          u = i.services.find((u) => u.kind === kind);
        model.vehicle.group.visible = visible && !!u?.visible;
        model.actor.g.visible = visible && !!u?.worker.visible;
        if (!visible || !u) continue;
        model.vehicle.update(u, s.time);
        model.beacons.forEach(
          (lamp, n) =>
            (lamp.visible =
              u.stage !== "complete" && Math.floor(s.time * 5) % 2 === n),
        );
        if (u.worker.visible) {
          const a = u.worker;
          model.actor.g.position.set(a.x - i.site.x, 0, a.z - i.site.z);
          model.actor.g.rotation.y = a.heading;
          model.actor.left.rotation.z = a.moving
            ? Math.sin(s.time * 7) * 0.3
            : -0.6;
          model.actor.right.rotation.z = a.moving
            ? -Math.sin(s.time * 7) * 0.3
            : 0.3;
        }
      }
      support.group.visible = visible && i.support.stage !== "idle";
      tow.group.visible = visible && i.tow.visible;
      victim.g.visible =
        visible && ["waiting", "treating"].includes(i.victim.state);
      if (victim.g.visible) {
        victim.g.position.set(
          i.victim.x - i.site.x,
          0.3,
          i.victim.z - i.site.z,
        );
        victim.g.rotation.z = Math.PI / 2;
      }
      if (!visible) return;
      root.position.set(i.site.x, 0, i.site.z);
      cones.visible = [
        "secured",
        "surveyed",
        "towCalled",
        "towReady",
        "recovering",
        "clearing",
        "resolved",
      ].includes(i.stage);
      impact.visible = i.kind !== "debris" && i.vehicle.visible;
      skid.visible = i.kind !== "debris" && i.vehicle.visible;
      debris.visible = i.kind === "debris" && i.debris.visible;
      labelPlane.visible = i.stage !== "resolved";
      labelPlane.quaternion.copy(camera.quaternion);
      smoke.forEach((p, n) => {
        p.visible =
          i.kind !== "debris" && i.vehicle.visible && i.stage !== "recovering";
        p.position.y = 1.7 + n * 0.39 + Math.sin(s.time * 0.6 + n) * 0.1;
        p.material.opacity = 0.11 + 0.06 * Math.sin(s.time + n);
      });
      flames.forEach((f, n) => {
        f.visible = i.fire && i.vehicle.visible;
        f.scale.y = 0.75 + Math.sin(s.time * 8 + n) * 0.25;
      });
      driver.g.visible = i.kind !== "debris" && i.driver.visible;
      if (driver.g.visible) {
        driver.g.position.set(i.driver.x - i.site.x, 0, i.driver.z - i.site.z);
        driver.g.rotation.y =
          i.driver.action === "talk" ? Math.PI * 0.45 : Math.PI;
        driver.right.rotation.z =
          i.driver.action === "talk" ? Math.sin(s.time * 3) * 0.4 : 0;
      }
      for (const [n, a] of i.agents.entries()) {
        const actor = officers[n];
        actor.g.visible = a.visible;
        if (!a.visible) continue;
        actor.g.position.set(a.x - i.site.x, 0, a.z - i.site.z);
        actor.g.rotation.y = a.heading;
        actor.left.rotation.z =
          a.action === "signal" ? -1.3 : Math.sin(s.time * 7 + n) * 0.15;
        actor.right.rotation.z = a.action === "documents" ? -0.65 : 0;
        actor.body.rotation.z = a.moving ? Math.sin(s.time * 5 + n) * 0.04 : 0;
      }
      stranded.update(i.vehicle, s.time);
      truck.update(i.vehicle, s.time);
      crashed.update(
        {
          ...i.vehicle,
          x: i.vehicle.x + 2.5,
          z: i.vehicle.z + 6,
          heading: 0.4,
        },
        s.time,
      );
      support.update(i.support, s.time);
      tow.update(i.tow, s.time);
      beacon.visible = i.tow.visible && Math.floor(s.time * 5) % 2 === 0;
    },
  };
}
