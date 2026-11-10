import { usingRadio } from "./radio-prop.js?v=2.15.1";
import { createFirstPersonArms } from "./first-person-arms.js?v=2.15.1";
import * as T from "./vendor/engine.js?v=2.15.1";
import { floorHeight } from "./base-life.js?v=2.15.1";
export function avatarAnimation(s) {
  if (s.reception.seated) return "Seated";
  if (s.inspection || (s.player.gestureUntil ?? 0) > s.time) return "Documents";
  if (
    s.mission.stage === "stopped" &&
    s.driver.visible &&
    !s.player.moving &&
    Math.hypot(s.player.x - s.driver.x, s.player.z - s.driver.z) < 4
  )
    return "Signal";
  if (s.radar || usingRadio(s)) return "Documents";
  if (s.player.rifleEquipped !== false) {
    if (s.player.moving) return s.player.running ? "RifleRun" : "RifleWalk";
    return "RifleIdle";
  }
  if (s.player.moving) return s.player.running ? "Run" : "Walk";
  return "Idle";
}
function dispose(root) {
  const materials = new Set(),
    textures = new Set();
  root.traverse((o) => {
    if (o.isMesh) {
      o.geometry.dispose();
      for (const m of [].concat(o.material)) materials.add(m);
    }
  });
  for (const m of materials) {
    for (const v of Object.values(m)) if (v?.isTexture) textures.add(v);
    m.dispose();
  }
  for (const t of textures) {
    t.dispose();
    t.image?.close?.();
  }
}
export function createPlayerAvatar(
  scene,
  { mobile = false, prepare = async () => {}, camera = null } = {},
) {
  const group = new T.Group();
  group.name = "Player detailed avatar";
  scene.add(group);
  const state = {
    group,
    status: "loading",
    error: null,
    animation: "Idle",
    mixer: null,
    actions: {},
    stats: null,
    rifle: { held: [], slung: [] },
  };
  let active = null,
    lastDistance = 0;
  state.ready = (async () => {
    const abort = new AbortController(),
      timeout = setTimeout(() => abort.abort(), 15000);
    let model = null;
    try {
      const url = new URL(
        "./assets/models/prf-agent.glb?v=2.6.0",
        import.meta.url,
      );
      const response = await fetch(url, { signal: abort.signal });
      if (!response.ok) throw Error(`GLB HTTP ${response.status}`);
      const data = await response.arrayBuffer();
      clearTimeout(timeout);
      if (data.byteLength > 5 * 1024 * 1024)
        throw Error("GLB acima do orçamento de 5 MB");
      const gltf = await new T.GLTFLoader().parseAsync(
        data,
        new URL(".", url).href,
      );
      model = gltf.scene;
      const mixer = new T.AnimationMixer(model),
        actions = {};
      for (const clip of gltf.animations)
        actions[clip.name] = mixer.clipAction(clip);
      for (const name of [
        "Idle",
        "Walk",
        "Run",
        "Documents",
        "Seated",
        "Signal",
        "RifleIdle",
        "RifleWalk",
        "RifleRun",
      ])
        if (!actions[name]) throw Error("Animação ausente: " + name);
      actions.Idle.play();
      mixer.update(0);
      model.updateMatrixWorld(true);
      const bounds = new T.Box3().setFromObject(
          model.getObjectByName("PRF_Commander") ?? model,
        ),
        size = bounds.getSize(new T.Vector3());
      if (size.y < 1 || size.y > 3) throw Error("Escala inválida do esqueleto");
      const scale = 1.86 / size.y;
      model.scale.multiplyScalar(scale);
      model.position.set(
        -(bounds.min.x + bounds.max.x) * 0.5 * scale,
        -bounds.min.y * scale,
        -(bounds.min.z + bounds.max.z) * 0.5 * scale,
      );
      let triangles = 0,
        skinned = 0,
        bones = 0;
      model.traverse((o) => {
        if (o.name.startsWith("HeldRifle")) state.rifle.held.push(o);
        if (o.name.startsWith("SlungRifle")) state.rifle.slung.push(o);
        if (o.isMesh) {
          o.castShadow = !mobile;
          o.receiveShadow = true;
          o.frustumCulled = false;
          triangles +=
            (o.geometry.index?.count ?? o.geometry.attributes.position.count) /
            3;
          if (o.isSkinnedMesh) {
            skinned++;
            bones = Math.max(bones, o.skeleton.bones.length);
          }
          for (const m of [].concat(o.material)) {
            if (m.map) m.map.anisotropy = mobile ? 2 : 4;
          }
        }
      });
      await prepare(model);
      group.add(model);
      if (camera)
        state.viewArms = createFirstPersonArms(model, gltf.animations, camera);
      state.mixer = mixer;
      state.actions = actions;
      active = actions.Idle;
      state.stats = {
        triangles,
        skinned,
        bones,
        height: 1.86,
        bytes: data.byteLength,
      };
      state.status = "ready";
    } catch (error) {
      state.status = "fallback";
      state.error =
        error.name === "AbortError"
          ? "Tempo limite ao carregar o agente"
          : error.message;
      if (model) dispose(model);
      console.warn(
        "Agente GLB indisponível; usando personagem leve:",
        state.error,
      );
    } finally {
      clearTimeout(timeout);
    }
    return state.status;
  })();
  state.update = (s, dt, firstPerson) => {
    group.visible =
      state.status === "ready" && s.mode === "foot" && !firstPerson;
    group.position.set(
      s.player.x,
      floorHeight(s.player.x, s.player.z),
      s.player.z,
    );
    group.rotation.y = s.player.yaw + Math.PI;
    if (state.status !== "ready") return;
    const name = avatarAnimation(s),
      next = state.actions[name];
    if (next !== active) {
      next.reset().setEffectiveWeight(1).setEffectiveTimeScale(1).play();
      active.crossFadeTo(next, 0.18, false);
      active = next;
      state.animation = name;
    }
    const delta = s.player.distance - lastDistance;
    lastDistance = s.player.distance;
    const held = name.startsWith("Rifle");
    for (const o of state.rifle.held) o.visible = held;
    for (const o of state.rifle.slung) o.visible = !held;
    if ((name.endsWith("Walk") || name.endsWith("Run")) && dt > 0) {
      const speed = Math.abs(delta / dt);
      active.timeScale = Math.max(
        0.5,
        Math.min(2, name.endsWith("Run") ? speed / 4.5 : speed / 1.7),
      );
    }
    if (group.visible) state.mixer.update(Math.min(dt, 0.05));
    state.viewArms?.update(
      name,
      dt,
      s.mode === "foot" &&
        firstPerson &&
        held &&
        !s.reception.seated &&
        !s.inspection,
      active.timeScale,
    );
  };
  return state;
}
