import * as T from "./vendor/engine.js?v=2.18.0";
import { clockReading } from "./shift-clock.js?v=2.18.0";
export function createDayNight(scene, mobile) {
  const hemisphere = new T.HemisphereLight(0xcbdce6, 0x8b7856, 1.65);
  const sun = new T.DirectionalLight(0xffd4a3, 2.7);
  sun.target.position.set(4, 0, 10);
  sun.shadow.mapSize.set(1024, 1024);
  Object.assign(sun.shadow.camera, {
    left: -75,
    right: 75,
    top: 65,
    bottom: -65,
    near: 1,
    far: 220,
  });
  sun.shadow.bias = -0.0003;
  sun.shadow.normalBias = 0.035;
  scene.add(hemisphere, sun, sun.target);
  const canvas = document.createElement("canvas");
  canvas.width = 512;
  canvas.height = 256;
  const texture = new T.CanvasTexture(canvas);
  texture.colorSpace = T.SRGBColorSpace;
  const sky = new T.Mesh(
    new T.SphereGeometry(2600, mobile ? 24 : 32, 12),
    new T.MeshBasicMaterial({
      map: texture,
      side: T.BackSide,
      depthWrite: false,
      fog: false,
      toneMapped: false,
    }),
  );
  sky.name = "Céu do turno";
  scene.add(sky);
  const disc = new T.Mesh(
    new T.SphereGeometry(14, 12, 8),
    new T.MeshBasicMaterial({ color: 0xffdcaa, fog: false, toneMapped: false }),
  );
  scene.add(disc);
  const moon = new T.Mesh(
    new T.SphereGeometry(9, 10, 8),
    new T.MeshBasicMaterial({ color: 0xc5dcf6, fog: false, toneMapped: false }),
  );
  scene.add(moon);
  const lightMaterial = new T.MeshBasicMaterial({
    color: 0xffffff,
    toneMapped: false,
  });
  const fixtures = [],
    lights = [];
  const metal = new T.MeshStandardMaterial({
    color: 0x243846,
    roughness: 0.6,
    metalness: 0.4,
  });
  function fixture(x, y, z, w, d) {
    const m = new T.Mesh(new T.BoxGeometry(w, 0.07, d), lightMaterial);
    m.position.set(x, y, z);
    m.name = "Luminária noturna";
    scene.add(m);
    fixtures.push(m);
  }
  // Fixed, shadowless lights: no shader recompilation or shadow-map cost at sunset.
  for (const [x, y, z, power, distance] of [
    [-6, 7.3, 9, 220, 34],
    [15, 7.3, 17, 220, 34],
    [35, 3.8, 20, 100, 22],
    [38, 6, -15, 170, 35],
  ]) {
    const l = new T.PointLight(0xffebcd, 0, distance, 2);
    l.position.set(x, y, z);
    scene.add(l);
    lights.push({ light: l, power });
  }
  for (const x of [-10, 0, 10, 20]) fixture(x, 7.6, 12, 0.22, 8);
  for (const z of [16, 25]) fixture(35, 4.61, z, 9, 0.26);
  for (const x of [27, 49]) {
    const pole = new T.Mesh(new T.CylinderGeometry(0.09, 0.13, 6, 8), metal);
    pole.position.set(x, 3, -17);
    scene.add(pole);
    fixture(x, 6, -17, 1.4, 0.6);
  }
  const dayTop = new T.Color(0x5994cc),
    dayHorizon = new T.Color(0xc9dce5),
    nightTop = new T.Color(0x040b20),
    nightHorizon = new T.Color(0x192940),
    warm = new T.Color(0xeda175);
  let skyKey = "";
  const temp = new T.Color(),
    fog = new T.Color();
  const state = { sun, lights, fixtures, night: 0, sky, hemisphere };
  state.update = (s) => {
    const r = clockReading(s.clock),
      hour = s.clock.minute / 60,
      angle = ((hour - 6) / 12) * Math.PI;
    const elevation = Math.sin(angle),
      twilight = Math.max(0, 1 - Math.abs(elevation) * 4) * r.daylight;
    state.night = r.lamps;
    sun.position.set(
      4 + Math.cos(angle) * 90,
      Math.max(12, Math.abs(elevation) * 95),
      10 - 45 * Math.cos(angle),
    );
    sun.intensity = 0.2 + r.daylight * 2.4;
    sun.color.set(0xffedda).lerp(warm, twilight * 0.7);
    hemisphere.intensity = 0.38 + r.daylight * 1.27;
    hemisphere.color.set(0x6f94cf).lerp(new T.Color(0xcbdce6), r.daylight);
    hemisphere.groundColor
      .set(0x263248)
      .lerp(new T.Color(0x8b7856), r.daylight);
    lights.forEach(({ light, power }) => (light.intensity = power * r.lamps));
    lightMaterial.color.setScalar(0.25 + 0.75 * r.lamps);
    disc.visible = elevation > -0.1;
    disc.position.set(Math.cos(angle) * 650, elevation * 650, 320);
    moon.visible = elevation < 0.1;
    moon.position.set(-Math.cos(angle) * 650, -elevation * 650, -320);
    fog
      .copy(nightHorizon)
      .lerp(dayHorizon, r.daylight)
      .lerp(warm, twilight * 0.3);
    scene.fog.color.copy(fog);
    scene.background.copy(fog);
    const key = Math.floor(s.clock.minute / 5);
    if (key === skyKey) return;
    skyKey = key;
    const c = canvas.getContext("2d"),
      g = c.createLinearGradient(0, 0, 0, 256);
    temp.copy(nightTop).lerp(dayTop, r.daylight);
    g.addColorStop(0, "#" + temp.getHexString());
    g.addColorStop(0.5, "#" + fog.getHexString());
    g.addColorStop(1, "#" + fog.getHexString());
    c.fillStyle = g;
    c.fillRect(0, 0, 512, 256);
    if (r.daylight < 0.4) {
      c.globalAlpha = 1 - r.daylight / 0.4;
      c.fillStyle = "#d8e8ff";
      for (let i = 0; i < 90; i++)
        c.fillRect(
          (i * 137.51) % 512,
          (i * 37.71) % 112,
          i % 9 === 0 ? 1.6 : 1,
          1,
        );
      c.globalAlpha = 1;
    }
    texture.needsUpdate = true;
  };
  return state;
}
