import * as T from "./vendor/engine.js?v=2.8.0";
export const usingRadio = (s) =>
  s.player.usingRadio || (s.player.radioUntil ?? 0) > s.time;
export function createRadioProp(scene, camera) {
  const body = new T.MeshStandardMaterial({ color: 0x182126, roughness: 0.65 });
  const screen = new T.MeshBasicMaterial({
    color: 0x76caa5,
    toneMapped: false,
  });
  const radio = new T.Group();
  radio.name = "Rádio do Comando Geral";
  function box(material, x, y, z, w, h, d) {
    const m = new T.Mesh(new T.BoxGeometry(w, h, d), material);
    m.position.set(x, y, z);
    radio.add(m);
  }
  box(body, 0, 0, 0, 0.075, 0.16, 0.045);
  box(body, -0.02, 0.15, 0, 0.009, 0.17, 0.009);
  box(screen, 0, 0.025, 0.025, 0.05, 0.035, 0.003);
  for (let y = -0.02; y > -0.06; y -= 0.012)
    box(screen, 0, y, 0.026, 0.045, 0.003, 0.002);
  scene.add(radio);
  const view = radio.clone();
  view.name = "Rádio em primeira pessoa";
  view.position.set(0.32, -0.22, -0.5);
  view.rotation.set(0.1, -0.2, -0.1);
  camera.add(view);
  return {
    group: radio,
    view,
    update(s, firstPerson, avatar) {
      const active = s.mode === "foot" && !s.reception.seated && usingRadio(s);
      radio.visible = active && !firstPerson;
      view.visible = active && firstPerson;
      if (!radio.visible) return;
      const hand = avatar.group.getObjectByName("Bip01_R_Hand");
      if (hand && avatar.status === "ready") {
        avatar.group.updateMatrixWorld(true);
        hand.getWorldPosition(radio.position);
        hand.getWorldQuaternion(radio.quaternion);
      } else {
        radio.position.set(s.player.x, 1.2, s.player.z);
        radio.rotation.set(0, s.player.yaw, 0);
      }
    },
  };
}
