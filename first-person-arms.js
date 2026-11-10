import * as T from "./vendor/engine.js?v=2.15.0";
// Keep only triangles weighted to the upper arms, forearms and hands.
// This uses the same skinned mesh, textures and carry animations as the world avatar.
export function createFirstPersonArms(model, clips, camera) {
  const group = new T.Group();
  group.name = "First person rifle and arms";
  group.visible = false;
  camera.add(group);
  const root = T.cloneRig(model);
  const bodyRoot = root.getObjectByName("PRF_Commander");
  const inBody = (object) => {
    for (let p = object; p; p = p.parent) if (p === bodyRoot) return true;
    return false;
  };
  let armTriangles = 0;
  root.traverse((o) => {
    if (!o.isMesh) return;
    o.castShadow = false;
    o.frustumCulled = false;
    if (o.name.startsWith("HeldRifle")) {
      o.visible = true;
      return;
    }
    if (!o.isSkinnedMesh || !inBody(o)) {
      o.visible = false;
      return;
    }
    const g = o.geometry,
      indices = g.index,
      skin = g.attributes.skinIndex,
      weight = g.attributes.skinWeight,
      keep = [];
    const selected = new Set(
      o.skeleton.bones.map((b, i) =>
        /UpperArm|Forearm|Hand|Finger/.test(b.name) ? i : -1,
      ),
    );
    const member = (index) => {
      let sum = 0;
      for (let k = 0; k < 4; k++)
        if (selected.has(skin.getComponent(index, k)))
          sum += weight.getComponent(index, k);
      return sum > 0.5;
    };
    for (
      let i = 0;
      i < (indices?.count ?? g.attributes.position.count);
      i += 3
    ) {
      const a = indices ? indices.getX(i) : i,
        b = indices ? indices.getX(i + 1) : i + 1,
        c = indices ? indices.getX(i + 2) : i + 2;
      if (Number(member(a)) + Number(member(b)) + Number(member(c)) >= 2)
        keep.push(a, b, c);
    }
    if (!keep.length) {
      o.visible = false;
      return;
    }
    armTriangles += keep.length / 3;
    o.geometry = g.clone();
    o.geometry.setIndex(keep);
    o.geometry.clearGroups();
    o.visible = true;
  });
  group.add(root);
  group.position.set(-0.25, -1.5, -0.25);
  group.rotation.y = Math.PI - 0.65;
  const mixer = new T.AnimationMixer(root),
    actions = {};
  for (const clip of clips)
    if (clip.name.startsWith("Rifle"))
      actions[clip.name] = mixer.clipAction(clip);
  let active = actions.RifleIdle;
  active.play();
  return {
    group,
    armTriangles,
    update(name, dt, visible, timeScale = 1) {
      group.visible = visible;
      if (!visible) return;
      const next = actions[name] ?? actions.RifleIdle;
      if (next !== active) {
        next.reset().play();
        active.crossFadeTo(next, 0.18, false);
        active = next;
      }
      active.timeScale = timeScale;
      mixer.update(Math.min(dt, 0.05));
      // FPS-only shoulder placement: keep the wrists/grip fixed and let the sleeves
      // enter from below the frame, rather than exposing a cut shoulder surface.
      camera.updateMatrixWorld(true);
      for (const side of ["L", "R"]) {
        const upper = root.getObjectByName("Bip01_" + side + "_UpperArm");
        const forearm = root.getObjectByName("Bip01_" + side + "_Forearm");
        if (!upper || !forearm) continue;
        const wristFrame = forearm.matrixWorld.clone();
        const shoulder = camera.localToWorld(
          new T.Vector3(side === "L" ? -0.55 : 0.55, -0.8, -0.15),
        );
        upper.position.copy(upper.parent.worldToLocal(shoulder));
        upper.updateMatrixWorld(true);
        upper.matrixWorld
          .clone()
          .invert()
          .multiply(wristFrame)
          .decompose(forearm.position, forearm.quaternion, forearm.scale);
        forearm.updateMatrixWorld(true);
      }
    },
  };
}
