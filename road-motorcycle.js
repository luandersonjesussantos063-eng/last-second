import { upgradePoliceVehicle } from "./fleet-models.js?v=2.12.0";
import * as T from "./vendor/engine.js?v=2.12.0";
export function createMotorcycle({ police = false, color = 0x6c4440 } = {}) {
  const group = new T.Group(),
    paint = new T.MeshStandardMaterial({
      color: police ? 0x142c52 : color,
      metalness: 0.4,
      roughness: 0.4,
    }),
    rubber = new T.MeshStandardMaterial({ color: 0x172129 }),
    metal = new T.MeshStandardMaterial({
      color: 0x9ca6aa,
      metalness: 0.7,
      roughness: 0.3,
    }),
    yellow = new T.MeshStandardMaterial({ color: 0xe6bd35 }),
    skin = new T.MeshStandardMaterial({ color: 0xac8069 });
  function box(m, x, y, z, w, h, d) {
    const q = new T.Mesh(new T.BoxGeometry(w, h, d), m);
    q.position.set(x, y, z);
    group.add(q);
    return q;
  }
  function cyl(m, x, y, z, r, len, rz = 0) {
    const q = new T.Mesh(new T.CylinderGeometry(r, r, len, 10), m);
    q.position.set(x, y, z);
    q.rotation.z = rz;
    group.add(q);
    return q;
  }
  const wheels = [];
  for (const z of [-0.85, 0.88]) {
    const q = cyl(rubber, 0, 0.38, z, 0.38, 0.18, Math.PI / 2);
    wheels.push(q);
    cyl(metal, 0, 0.38, z, 0.19, 0.19, Math.PI / 2);
  }
  box(metal, 0, 0.65, -0.2, 0.28, 0.24, 0.9);
  box(paint, 0, 1.02, 0.18, 0.58, 0.38, 0.72);
  box(rubber, 0, 1.04, -0.45, 0.42, 0.15, 0.75);
  box(paint, 0, 0.88, 1.0, 0.5, 0.12, 0.5);
  box(paint, 0, 1.22, 0.75, 0.58, 0.32, 0.35);
  for (const side of [-1, 1]) {
    cyl(metal, side * 0.15, 0.79, 0.83, 0.045, 0.85);
    box(metal, side * 0.27, 0.67, -0.3, 0.15, 0.2, 0.65);
    box(police ? paint : rubber, side * 0.43, 0.91, -0.75, 0.34, 0.48, 0.5);
    box(yellow, side * 0.61, 0.94, -0.75, 0.02, 0.09, 0.45);
    box(metal, side * 0.41, 0.72, 0.18, 0.055, 0.5, 0.8);
    cyl(metal, side * 0.46, 1.48, 0.58, 0.03, 0.38);
    box(metal, side * 0.46, 1.66, 0.58, 0.16, 0.11, 0.05);
  }
  box(metal, 0, 1.38, 0.58, 0.95, 0.06, 0.08);
  const windshield = box(
    new T.MeshStandardMaterial({
      color: 0x8baeb8,
      transparent: true,
      opacity: 0.4,
      depthWrite: false,
    }),
    0,
    1.57,
    0.84,
    0.55,
    0.5,
    0.05,
  );
  windshield.rotation.x = -0.2;
  box(
    new T.MeshBasicMaterial({ color: 0xffefbf }),
    0,
    1.22,
    0.95,
    0.36,
    0.2,
    0.06,
  );
  if (police) {
    const c = document.createElement("canvas");
    c.width = 256;
    c.height = 96;
    const a = c.getContext("2d");
    a.fillStyle = "#142c52";
    a.fillRect(0, 0, 256, 96);
    a.fillStyle = "#f2d04d";
    a.font = "bold 70px Arial";
    a.textAlign = "center";
    a.fillText("PRF", 128, 72);
    const map = new T.CanvasTexture(c);
    map.colorSpace = T.SRGBColorSpace;
    const m = new T.MeshBasicMaterial({ map });
    for (const side of [-1, 1]) {
      const q = new T.Mesh(new T.PlaneGeometry(0.55, 0.22), m);
      q.position.set(side * 0.3, 1.07, 0.14);
      q.rotation.y = (side * Math.PI) / 2;
      group.add(q);
    }
  }
  // Dedicated helmeted rider, animated with the motorcycle rather than an unrelated pedestrian.
  const rider = new T.Group();
  group.add(rider);
  const suit = new T.MeshStandardMaterial({
    color: police ? 0x18304b : 0x4c5964,
  });
  const body = new T.Mesh(new T.CapsuleGeometry(0.2, 0.38, 3, 8), suit);
  body.position.set(0, 1.46, -0.26);
  body.rotation.x = 0.14;
  rider.add(body);
  const helmet = new T.Mesh(
    new T.SphereGeometry(0.23, 10, 7),
    police ? paint : rubber,
  );
  helmet.position.set(0, 1.94, -0.18);
  rider.add(helmet);
  const visor = new T.Mesh(new T.BoxGeometry(0.33, 0.13, 0.09), rubber);
  visor.position.set(0, 1.95, 0.025);
  rider.add(visor);
  for (const side of [-1, 1]) {
    for (const [x, y, z, w, h, d, m] of [
      [side * 0.28, 1.42, 0.05, 0.13, 0.17, 0.65, suit],
      [side * 0.25, 0.93, -0.2, 0.17, 0.46, 0.18, police ? yellow : suit],
      [side * 0.28, 0.67, 0.05, 0.2, 0.13, 0.38, rubber],
    ]) {
      const q = new T.Mesh(new T.BoxGeometry(w, h, d), m);
      q.position.set(x, y, z);
      rider.add(q);
    }
  }
  const flash = new T.MeshBasicMaterial({ color: 0x3189ff });
  const lamps = [
    box(flash, -0.26, 1.25, 0.96, 0.12, 0.1, 0.08),
    box(
      new T.MeshBasicMaterial({ color: 0xff3344 }),
      0.26,
      1.25,
      0.96,
      0.12,
      0.1,
      0.08,
    ),
  ];
  const result = {
    group,
    rider,
    update(c, time) {
      group.position.set(c.x, 0, c.z);
      group.rotation.y = c.heading;
      group.visible = c.visible !== false;
      rider.visible = !police || c.stage !== "ready";
      wheels.forEach((q) => (q.rotation.x = c.z * 2));
      lamps.forEach(
        (q, i) =>
          (q.visible = police && c.lights && Math.floor(time * 6) % 2 === i),
      );
    },
  };
  return police ? upgradePoliceVehicle(result, "motorcycle") : result;
}
