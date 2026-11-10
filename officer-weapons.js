import * as T from "./vendor/engine.js?v=2.23.0";
const steel = new T.MeshStandardMaterial({
    color: 0x1d2428,
    metalness: 0.7,
    roughness: 0.5,
  }),
  polymer = new T.MeshStandardMaterial({ color: 0x292f29, roughness: 0.85 });
let template;
export function createOfficerWeapon() {
  if (!template) {
    template = new T.Group();
    template.name = "Fuzil de serviço";
    const box = (m, x, y, z, w, h, d) => {
      const o = new T.Mesh(new T.BoxGeometry(w, h, d), m);
      o.position.set(x, y, z);
      template.add(o);
    };
    box(steel, 0, 0, 0, 0.07, 0.25, 0.08);
    box(polymer, 0, -0.25, 0, 0.07, 0.26, 0.09);
    box(polymer, 0, -0.05, 0.08, 0.045, 0.12, 0.04);
    box(steel, 0, 0.28, 0, 0.025, 0.35, 0.025);
    box(polymer, 0, 0.12, 0, 0.07, 0.16, 0.07);
    box(steel, 0, -0.08, 0.07, 0.04, 0.18, 0.04);
  }
  const group = template.clone();
  group.position.set(0.12, 1.15, -0.25);
  group.rotation.z = -0.35;
  return group;
}
