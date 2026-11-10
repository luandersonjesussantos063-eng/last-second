import * as T from "./vendor/engine.js?v=2.23.1";
import { searchedVehicle } from "./blitz-search.js?v=2.23.1";
export function createSearchVisual(scene) {
  const group = new T.Group(),
    doorMat = new T.MeshStandardMaterial({ color: 0x37434b, roughness: 0.6 }),
    crateMat = new T.MeshStandardMaterial({ color: 0x927855, roughness: 0.9 });
  const hatch = new T.Mesh(new T.BoxGeometry(1.4, 0.06, 0.9), doorMat);
  hatch.rotation.x = -0.8;
  group.add(hatch);
  const cargo = new T.Mesh(new T.BoxGeometry(0.8, 0.45, 0.6), crateMat);
  group.add(cargo);
  scene.add(group);
  group.name = "Compartimento aberto durante a conferência";
  return {
    group,
    update(s) {
      const t = searchedVehicle(s);
      group.visible = !!t && s.blitzSearch.checks.includes("cargo");
      if (!group.visible) return;
      const truck = t.kind === "truck" || t.freightType;
      group.position.set(t.x, truck ? 1.3 : 0.65, t.z);
      group.rotation.y = t.heading;
      const back = -(t.length ?? 4.8) / 2 + 0.4;
      hatch.position.set(0, truck ? 1.1 : 0.7, back);
      cargo.position.set(0, 0.2, back + 0.4);
    },
  };
}
