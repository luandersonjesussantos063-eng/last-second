import * as T from "./vendor/engine.js?v=2.21.0";
import { loadModel } from "./model-library.js?v=2.21.0";
import { floorHeight } from "./base-life.js?v=2.21.0";
export const POLICE_ROLES = [0, 1, 5, 6, 7, 8, 16, 17, 18, 19, 20, 21, 22];
const names = {
  0: "Recepção",
  1: "Operações",
  5: "Sinalização",
  6: "Conferência",
  7: "Rádio",
  8: "Vigilância",
  16: "Motopatrulha 1",
  17: "Motopatrulha 2",
  18: "Ferreira",
  19: "Mendes",
  20: "Nogueira",
  21: "Barros",
  22: "Teixeira",
};
export function createPoliceCrew(scene, mobile) {
  const bottleGeometry = new T.CylinderGeometry(0.047, 0.048, 0.19, 8),
    capGeometry = new T.CylinderGeometry(0.03, 0.03, 0.04, 8);
  const bottleMaterial = new T.MeshStandardMaterial({
    color: 0x90cce7,
    transparent: true,
    opacity: 0.88,
  });
  const capMaterial = new T.MeshStandardMaterial({ color: 0xeeeeee });
  const chairMaterial = new T.MeshStandardMaterial({
    color: 0x1b3045,
    roughness: 0.8,
  });
  const seatGeometry = new T.BoxGeometry(0.56, 0.09, 0.52),
    backGeometry = new T.BoxGeometry(0.56, 0.55, 0.07);
  const bottlePose = new T.Object3D();
  const actors = new Map(
    POLICE_ROLES.map((id) => {
      const group = new T.Group();
      group.name = "PRF " + names[id];
      const bottle = new T.Group();
      const body = new T.Mesh(bottleGeometry, bottleMaterial);
      const cap = new T.Mesh(capGeometry, capMaterial);
      cap.position.y = 0.115;
      bottle.add(body, cap);
      bottle.visible = false;
      group.add(bottle);
      const chair = new T.Group();
      if (id === 0 || id === 1) {
        const seat = new T.Mesh(seatGeometry, chairMaterial),
          back = new T.Mesh(backGeometry, chairMaterial);
        seat.position.y = 0.46;
        back.position.set(0, 0.78, -0.23);
        chair.add(seat, back);
        group.add(chair);
      }
      chair.visible = false;
      group.visible = false;
      scene.add(group);
      return [
        id,
        {
          id,
          group,
          status: "loading",
          animation: "Idle",
          clock: 0,
          last: null,
          parts: { vest: [], helmet: [], radio: [] },
          bottle,
          chair,
        },
      ];
    }),
  );
  const state = { actors, count: actors.size, status: "loading", error: null };
  state.ready = loadModel("prf-officer.glb", 3 * 1024 * 1024)
    .then(async (source) => {
      const template = T.cloneRig(source.scene),
        m = new T.AnimationMixer(template);
      m.clipAction(source.animations.find((a) => a.name === "Idle")).play();
      m.update(0);
      template.updateMatrixWorld(true);
      const body = template.getObjectByName("PRF_Officer");
      if (!body) throw Error("Malha policial ausente");
      const bounds = new T.Box3().setFromObject(body),
        height = bounds.max.y - bounds.min.y;
      if (height < 1 || height > 3) throw Error("Escala policial inválida");
      const scale = 1.82 / height;
      template.scale.multiplyScalar(scale);
      template.position.set(
        -(bounds.min.x + bounds.max.x) * 0.5 * scale,
        -bounds.min.y * scale,
        -(bounds.min.z + bounds.max.z) * 0.5 * scale,
      );
      for (const actor of actors.values()) {
        const model = T.cloneRig(template);
        actor.group.add(model);
        actor.model = model;
        actor.mixer = new T.AnimationMixer(model);
        actor.actions = {};
        for (const clip of source.animations)
          actor.actions[clip.name] = actor.mixer.clipAction(clip);
        actor.active = actor.actions.Idle;
        actor.active.play();
        actor.mixer.update(actor.id * 0.37);
        model.traverse((o) => {
          if (o.name.startsWith("SafetyVest")) actor.parts.vest.push(o);
          if (o.name.startsWith("MotoHelmet")) actor.parts.helmet.push(o);
          if (o.name.startsWith("HandRadio")) actor.parts.radio.push(o);
          if (o.isMesh) {
            o.castShadow = !mobile;
            o.receiveShadow = true;
            o.frustumCulled = false;
          }
        });
        actor.status = "ready";
        await new Promise((r) => setTimeout(r, 0));
      }
      state.status = "ready";
      return "ready";
    })
    .catch((error) => {
      state.status = "fallback";
      state.error = error.message;
      for (const a of actors.values()) {
        a.status = "fallback";
        a.group.visible = false;
      }
      console.warn("Equipe leve ativa:", error.message);
      return "fallback";
    });
  state.update = (s, dt, people) => {
    const detailed = new Set(),
      observer = s.mode === "drive" ? s.car : s.player;
    for (const actor of actors.values()) {
      let p = people[actor.id],
        riding = false;
      if (actor.id === 16 || actor.id === 17) {
        const bike = s.life.bikes[actor.id - 16];
        riding = bike.stage !== "ready";
        if (riding)
          p = {
            x: bike.x - Math.sin(bike.heading) * 0.08,
            z: bike.z - Math.cos(bike.heading) * 0.08,
            heading: bike.heading,
            visible: true,
            action: "riding",
          };
      }
      actor.bottle.visible = p.action === "drink";
      actor.chair.visible = p.action === "seated" && actor.id < 2;
      const distance = Math.hypot(observer.x - p.x, observer.z - p.z),
        visible =
          actor.status === "ready" &&
          p.visible &&
          distance < (mobile ? 90 : 160);
      actor.group.visible = visible;
      if (!visible) continue;
      detailed.add(actor.id);
      actor.group.position.set(
        p.x,
        floorHeight(p.x, p.z) +
          (riding ? 0.55 : p.action === "seated" && actor.id >= 18 ? 0.35 : 0),
        p.z,
      );
      actor.group.rotation.y = p.heading;
      const name =
        p.action === "seated"
          ? "Seated"
          : riding
            ? "Riding"
            : p.action === "walk"
              ? "Walk"
              : p.action === "signal"
                ? "Signal"
                : p.action === "radio" || p.action === "drink"
                  ? "Radio"
                  : ["documents", "typing"].includes(p.action)
                    ? "Documents"
                    : "Idle";
      if (actor.animation !== name) {
        const next = actor.actions[name];
        next.reset().setEffectiveWeight(1).play();
        actor.active.crossFadeTo(next, 0.2, false);
        actor.active = next;
        actor.animation = name;
      }
      for (const o of actor.parts.vest)
        o.visible = actor.id === 5 || actor.id === 6;
      for (const o of actor.parts.helmet)
        o.visible = actor.id === 16 || actor.id === 17;
      for (const o of actor.parts.radio)
        o.visible = name === "Radio" && p.action !== "drink";
      actor.clock += dt;
      const tick = mobile ? (distance > 35 ? 1 / 8 : 1 / 20) : 1 / 30;
      if (actor.clock >= tick) {
        actor.mixer.update(Math.min(0.25, actor.clock));
        actor.clock = 0;
      }
      if (actor.bottle.visible) {
        actor.group.updateMatrixWorld(true);
        const hand = actor.model.getObjectByName("Bip01_R_Hand");
        if (hand) {
          hand.getWorldPosition(actor.bottle.position);
          actor.group.worldToLocal(actor.bottle.position);
          hand.getWorldQuaternion(bottlePose.quaternion);
          actor.bottle.quaternion
            .copy(actor.group.quaternion)
            .invert()
            .multiply(bottlePose.quaternion);
        }
      }
    }
    return detailed;
  };
  return state;
}
