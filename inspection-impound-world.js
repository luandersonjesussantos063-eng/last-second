import * as T from "./vendor/engine.js?v=2.23.1";
export function createImpoundWorld(scene, createVehicle) {
  const navy = new T.MeshStandardMaterial({ color: 0x233542, roughness: 0.7 }),
    gold = new T.MeshBasicMaterial({ color: 0xffb63c });
  const teams = Array.from({ length: 3 }, (_, n) => {
    const tow = createVehicle({
        kind: "pickup",
        color: 0xe2aa43,
        plate: "GUINCHO-" + (n + 1),
      }),
      load = createVehicle({
        kind: "sedan",
        color: 0x6e8593,
        plate: "RECOLHIDO",
      });
    scene.add(tow.group, load.group);
    const bed = new T.Mesh(new T.BoxGeometry(2.2, 0.17, 4.5), navy);
    bed.position.set(0, 1.35, -1.1);
    tow.group.add(bed);
    const beacon = new T.Mesh(new T.BoxGeometry(0.7, 0.18, 0.3), gold);
    beacon.position.set(0, 2.1, 0.5);
    tow.group.add(beacon);
    tow.group.visible = load.group.visible = false;
    return { tow, load, beacon };
  });
  return {
    teams,
    update(s) {
      const jobs = s.operations?.impound?.jobs ?? [];
      for (const [n, m] of teams.entries()) {
        const j = jobs[n];
        m.tow.group.visible = !!j?.visible;
        m.load.group.visible = !!j && (j.load || j.stage === "stored");
        if (!j) continue;
        if (j.visible) {
          m.tow.update(j, s.time);
          m.beacon.visible = Math.floor(s.time * 5) % 2 === 0;
        }
        if (j.stage === "stored") {
          m.load.update(
            { x: j.loadX, z: j.loadZ, heading: 0, speed: 0 },
            s.time,
          );
        } else if (j.load) {
          m.load.update(
            {
              x: j.x - Math.sin(j.heading) * 1.3,
              z: j.z - Math.cos(j.heading) * 1.3,
              heading: j.heading,
              speed: 0,
            },
            s.time,
          );
          m.load.group.position.y = 1.4;
        }
      }
    },
  };
}
