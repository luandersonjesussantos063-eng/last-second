import * as T from "./vendor/engine.js?v=2.8.0";
import { loadModel } from "./model-library.js?v=2.8.0";
export function upgradePoliceVehicle(legacy, kind) {
  const fallback = [...legacy.group.children],
    oldUpdate = legacy.update;
  const state = (legacy.asset = { status: "loading", error: null });
  let model = null,
    wheels = [],
    steering = [],
    lamps = [];
  legacy.detailedRider = false;
  state.ready = loadModel(
    kind === "motorcycle" ? "prf-motorcycle.glb" : "prf-suv.glb",
    2 * 1024 * 1024,
  )
    .then((source) => {
      model = source.scene.clone(true);
      model.name = "Detailed PRF " + kind;
      model.traverse((o) => {
        if (
          o.name.startsWith("Wheel") &&
          !o.name.startsWith("WheelDetail") &&
          o.isObject3D &&
          !o.isMesh
        )
          wheels.push(o);
        if (o.name.startsWith("SteerF")) steering.push(o);
        if (o.name.startsWith("Flash")) lamps.push(o);
        if (o.isMesh) {
          o.castShadow = true;
          o.receiveShadow = true;
        }
      });
      legacy.group.add(model);
      state.status = "ready";
      state.bytes = source.bytes;
      state.wheels = wheels.length;
      return "ready";
    })
    .catch((error) => {
      state.status = "fallback";
      state.error = error.message;
      console.warn("Viatura leve ativa:", error.message);
      return "fallback";
    });
  legacy.update = (c, time) => {
    oldUpdate(c, time);
    if (state.status !== "ready") return;
    for (const child of fallback)
      child.visible =
        child === legacy.rider && c.stage !== "ready" && !legacy.detailedRider;
    for (const wheel of wheels) wheel.rotation.x = -(c.wheelSpin ?? c.z / 0.4);
    for (const wheel of steering) wheel.rotation.y = c.steering ?? 0;
    for (const lamp of lamps)
      lamp.visible =
        !!c.lights &&
        (lamp.name.startsWith("FlashRed")
          ? Math.floor(time * 6) % 2 === 0
          : Math.floor(time * 6) % 2 === 1);
  };
  return legacy;
}
