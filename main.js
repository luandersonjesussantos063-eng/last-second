import { nearestAgent } from "./command-sim.js?v=2.13.0";
import { requestBackup } from "./escort-sim.js?v=2.13.0";
import { createCommandUI } from "./command-ui.js?v=2.13.0";
import { createDayNight } from "./day-night.js?v=2.13.0";
import { floorHeight } from "./base-life.js?v=2.13.0";
import {
  nearComputer,
  sitAtComputer,
  leaveComputer,
  callCitizen,
  currentReport,
  registerReport,
} from "./reception-sim.js?v=2.13.0";
import * as T from "./vendor/engine.js?v=2.13.0";
import { frameStep, AdaptiveResolution } from "./game-utils.js?v=2.13.0";
import { createRoadWorld } from "./road-world.js?v=2.13.0";
import {
  createSimulation,
  stepSimulation,
  walkInput,
  driveInput,
  interactVehicle,
  interactMission,
  finishInspection,
  targetVehicle,
  distanceTo,
  actionLabel,
  missionText,
  radarReading,
  circleBlocked,
  notify,
} from "./road-sim.js?v=2.13.0";
import { RoadAudio } from "./road-audio.js?v=2.13.0";

const $ = (id) => document.getElementById(id);
const mobile = matchMedia("(pointer:coarse)").matches;
let sim = createSimulation(),
  started = false,
  ready = false,
  previous = null,
  hudTime = 0,
  lookPitch = -0.03,
  cameraSnap = true;
const keys = new Set(),
  stick = { x: 0, y: 0 },
  audio = new RoadAudio();
let economy = false;
try {
  economy = localStorage.getItem("prf-quality") === "economy";
} catch {}
let renderer, world, scene, camera, sun, environment;
const commandUI = createCommandUI({
  getSim: () => sim,
  release,
  audio,
  refresh: updateHUD,
});
const resolution = new AdaptiveResolution(
  Math.min(devicePixelRatio, mobile ? 1.1 : 1.5),
);
function applyQuality() {
  if (renderer && sun) {
    renderer.shadowMap.enabled = !mobile && !economy;
    sun.castShadow = !mobile && !economy;
    renderer.shadowMap.needsUpdate = true;
  }
  renderer?.setPixelRatio(
    economy ? resolution.maximum * 0.7 : resolution.ratio,
  );
  resolution.reset();
  const label = "GRÁFICOS: " + (economy ? "ECONÔMICO" : "AUTOMÁTICO");
  $("qualityBtn").textContent = $("qualityInGame").textContent = label;
}
function toggleQuality() {
  economy = !economy;
  try {
    localStorage.setItem("prf-quality", economy ? "economy" : "auto");
  } catch {}
  applyQuality();
}
$("qualityBtn").onclick = $("qualityInGame").onclick = toggleQuality;
function audioUI() {
  const text = audio.muted ? "SOM: DESLIGADO" : "SOM: LIGADO";
  $("soundBtn").textContent = $("soundInGame").textContent = text;
  $("volumeRange").value = Math.round(audio.volume * 100);
  $("volumeValue").textContent = Math.round(audio.volume * 100) + "%";
}
$("soundBtn").onclick = $("soundInGame").onclick = () => {
  void audio.unlock(sim.paused || sim.inspection);
  audio.toggle();
  audioUI();
};
$("volumeRange").oninput = (e) => {
  audio.setVolume(Number(e.target.value) / 100);
  audioUI();
};
audioUI();
$("helpBtn").onclick = () => $("helpDialog").showModal();
$("closeHelp").onclick = () => $("helpDialog").close();
let movePointer = null,
  lookPointer = null,
  lookX = 0,
  lookY = 0;
function release() {
  keys.clear();
  stick.x = stick.y = 0;
  movePointer = lookPointer = null;
  sim.player.turnVelocity = 0;
  $("walkNub").style.transform = "translate(-50%,-50%)";
  for (const b of [$("gasBtn"), $("brakeBtn"), $("runBtn")])
    b.classList.remove("pressed");
}
function setPaused(value) {
  if (!started || sim.inspection) return;
  sim.paused = value;
  release();
  previous = null;
  audio.pause(value);
  if (value) {
    if (!$("pauseDialog").open) $("pauseDialog").showModal();
  } else if ($("pauseDialog").open) $("pauseDialog").close();
}
$("pauseBtn").onclick = () => setPaused(true);
$("resumeBtn").onclick = () => setPaused(false);
$("pauseDialog").addEventListener("cancel", (e) => {
  e.preventDefault();
  setPaused(false);
});
$("restartBtn").onclick = () => reset();
$("fullscreenBtn").onclick = () => {
  document.documentElement.requestFullscreen?.().catch(() => {});
};
function reset() {
  if (commandUI.isOpen) commandUI.close();
  for (const id of ["pauseDialog", "inspectionDialog"])
    if ($(id).open) $(id).close();
  sim = createSimulation();
  audio.reset();
  release();
  previous = null;
  cameraSnap = true;
  void audio.unlock();
  updateHUD();
}
function start(mode) {
  if (!ready) return;
  started = true;
  $("menu").hidden = true;
  for (const id of ["hud", "toolbar", "interactions"]) $(id).hidden = false;
  $("mobileControls").hidden = !mobile;
  if (mode === "drive") {
    sim.player.x = 21.9;
    sim.player.z = -8;
    interactVehicle(sim);
  }
  release();
  void audio.unlock();
  cameraSnap = true;
  updateHUD();
}
$("startBtn").onclick = () => start("drive");
$("exploreBtn").onclick = () => start("foot");
function vehicleAction() {
  if (interactVehicle(sim)) {
    release();
    audio.emit("enter");
    cameraSnap = true;
  }
  updateHUD();
}
function missionAction() {
  if (sim.reception.seated) {
    callCitizen(sim);
    updateHUD();
    return;
  }
  if (nearComputer(sim)) {
    sitAtComputer(sim);
    release();
    cameraSnap = true;
    updateHUD();
    return;
  }
  if (!actionLabel(sim) && nearestAgent(sim)) {
    commandUI.open(true);
    return;
  }
  const result = interactMission(sim);
  if (result) {
    audio.emit("radio");
    release();
  }
  if (result === "stop") playSirenCommand("parada");
  if (result === "inspect") {
    const r = sim.mission.report;
    $("inspectionVehicle").textContent = "Veículo " + r.plate;
    $("inspectionChecks").replaceChildren(
      ...[r.license, r.registration, r.equipment, r.result].map((text) => {
        const p = document.createElement("div");
        p.textContent = "✓ " + text;
        return p;
      }),
    );
    $("inspectionDialog").showModal();
    audio.pause(true);
  }
  updateHUD();
}
function closeInspection(complete) {
  if (complete) finishInspection(sim);
  else sim.inspection = false;
  $("inspectionDialog").close();
  release();
  audio.pause(false);
  previous = null;
  updateHUD();
}
$("vehicleBtn").onclick = vehicleAction;
$("actionBtn").onclick = missionAction;
$("callCitizenBtn").onclick = () => {
  callCitizen(sim);
  updateHUD();
};
$("registerReportBtn").onclick = () => {
  if (registerReport(sim)) audio.emit("radio");
  updateHUD();
};
$("leaveDeskBtn").onclick = () => {
  leaveComputer(sim);
  release();
  cameraSnap = true;
  updateHUD();
};
$("finishInspectionBtn").onclick = () => closeInspection(true);
$("cancelInspectionBtn").onclick = () => closeInspection(false);
$("inspectionDialog").addEventListener("cancel", (e) => {
  e.preventDefault();
  closeInspection(false);
});
function toggleLights() {
  sim.car.lights = !sim.car.lights;
  audio.emit("ui");
  updateHUD();
}
function toggleSiren() {
  sim.car.siren = !sim.car.siren;
  if (sim.car.siren) playSirenCommand("perseguicao");
  else audio.stopCommand();
  audio.emit("ui");
  updateHUD();
}
function playSirenCommand(kind) {
  void audio
    .unlock(sim.paused || sim.inspection)
    .then(() =>
      kind === "perseguicao" && !sim.car.siren ? true : audio.command(kind),
    )
    .then((ok) => {
      if (!ok)
        notify(
          sim,
          "Não foi possível carregar o áudio da viatura. Recarregue a página.",
        );
    });
}
function requestPassage() {
  playSirenCommand("passagem");
  notify(sim, "Pedido de passagem emitido.");
}
function toggleRifle() {
  if (
    sim.mode !== "foot" ||
    sim.paused ||
    sim.inspection ||
    sim.reception.seated
  )
    return;
  sim.player.rifleEquipped = !sim.player.rifleEquipped;
  audio.emit("enter");
  notify(
    sim,
    sim.player.rifleEquipped
      ? "Fuzil em posição de porte."
      : "Fuzil guardado nas costas.",
  );
  updateHUD();
}
$("weaponBtn").onclick = toggleRifle;
function callBackup() {
  const response = requestBackup(sim);
  notify(sim, response.message, 5);
  if (response.ok) audio.emit("radio");
  updateHUD();
}
$("backupBtn").onclick = callBackup;
function toggleRadar() {
  if (sim.mode === "foot") {
    sim.radar = !sim.radar;
    audio.emit("ui");
    updateHUD();
  } else notify(sim, "Use o radar após desembarcar da viatura.");
}
function toggleCamera() {
  if (sim.mode === "drive") sim.car.interior = !sim.car.interior;
  else sim.firstPerson = !sim.firstPerson;
  cameraSnap = true;
  updateHUD();
}
$("lightsBtn").onclick = toggleLights;
$("sirenBtn").onclick = toggleSiren;
$("passageBtn").onclick = requestPassage;
$("radarBtn").onclick = toggleRadar;
$("cameraBtn").onclick = toggleCamera;
window.addEventListener("keydown", (e) => {
  if (!started) return;
  if (commandUI.isOpen) {
    if (e.code === "Escape" || e.code === "KeyT") {
      e.preventDefault();
      commandUI.close();
    }
    return;
  }
  if (e.code === "KeyP" || e.code === "Escape") {
    if (!e.repeat && !sim.inspection) {
      e.preventDefault();
      setPaused(!sim.paused);
    }
    return;
  }
  if (sim.paused || sim.inspection) return;
  if (
    [
      "KeyW",
      "KeyA",
      "KeyS",
      "KeyD",
      "ArrowUp",
      "ArrowDown",
      "ArrowLeft",
      "ArrowRight",
      "Space",
      "ShiftLeft",
      "ShiftRight",
    ].includes(e.code)
  ) {
    keys.add(e.code);
    e.preventDefault();
    return;
  }
  if (e.repeat) return;
  ({
    KeyE: vehicleAction,
    KeyF: missionAction,
    KeyG: toggleLights,
    KeyH: toggleSiren,
    KeyB: requestPassage,
    KeyC: toggleCamera,
    KeyJ: toggleRadar,
    KeyK: callBackup,
    KeyV: toggleRifle,
    KeyT: () => commandUI.open(),
    KeyR: reset,
  })[e.code]?.();
});
window.addEventListener("keyup", (e) => keys.delete(e.code));
window.addEventListener("blur", () => {
  release();
  if (started && !sim.inspection) setPaused(true);
  else if (sim.inspection) audio.pause(true);
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) {
    release();
    if (started && !sim.inspection) setPaused(true);
    audio.pause(true);
  }
  previous = null;
});
function bindPedal(id, key) {
  const b = $(id);
  let pointer = null;
  b.onpointerdown = (e) => {
    if (sim.paused || sim.inspection || pointer !== null) return;
    pointer = e.pointerId;
    try {
      b.setPointerCapture(pointer);
    } catch {}
    keys.add(key);
    b.classList.add("pressed");
    e.preventDefault();
  };
  const end = (e) => {
    if (e.pointerId !== pointer) return;
    pointer = null;
    keys.delete(key);
    b.classList.remove("pressed");
  };
  for (const type of ["pointerup", "pointercancel", "lostpointercapture"])
    b.addEventListener(type, end);
}
bindPedal("gasBtn", "KeyW");
bindPedal("brakeBtn", "KeyS");
bindPedal("runBtn", "ShiftLeft");
function updateStick(e) {
  if (e.pointerId !== movePointer) return;
  const r = $("walkPad").getBoundingClientRect(),
    dx = e.clientX - r.left - r.width / 2,
    dy = e.clientY - r.top - r.height / 2,
    length = Math.max(40, Math.hypot(dx, dy));
  stick.x = dx / length;
  stick.y = sim.mode === "foot" ? dy / length : 0;
  $("walkNub").style.transform =
    `translate(-50%,-50%) translate(${stick.x * 32}px,${(sim.mode === "foot" ? stick.y : dy / length) * 32}px)`;
}
$("walkPad").onpointerdown = (e) => {
  if (movePointer !== null || sim.paused || sim.inspection) return;
  movePointer = e.pointerId;
  try {
    $("walkPad").setPointerCapture(movePointer);
  } catch {}
  updateStick(e);
  e.preventDefault();
};
$("walkPad").onpointermove = updateStick;
for (const type of ["pointerup", "pointercancel", "lostpointercapture"])
  $("walkPad").addEventListener(type, (e) => {
    if (e.pointerId === movePointer) {
      movePointer = null;
      stick.x = stick.y = 0;
      $("walkNub").style.transform = "translate(-50%,-50%)";
    }
  });
let effectiveFirst = false;
const cameraTarget = new T.Vector3(),
  lookTarget = new T.Vector3(),
  markerPoint = new T.Vector3();
function updateCamera(dt) {
  const c = sim.car,
    p = sim.player,
    sin = Math.sin(c.heading),
    cos = Math.cos(c.heading);
  if (sim.mode === "drive") {
    if (c.interior) {
      cameraTarget.set(c.x + sin * 0.4, 1.62, c.z + cos * 0.4);
      lookTarget.set(c.x + sin * 30, 1.5, c.z + cos * 30);
    } else {
      cameraTarget.set(c.x - sin * 8.5, 4.2, c.z - cos * 8.5);
      lookTarget.set(c.x + sin * 4, 1, c.z + cos * 4);
    }
    effectiveFirst = c.interior;
  } else {
    const x = p.x + Math.sin(p.yaw) * 3.6 + Math.cos(p.yaw) * 0.55,
      z = p.z + Math.cos(p.yaw) * 3.6 - Math.sin(p.yaw) * 0.55;
    effectiveFirst =
      sim.firstPerson ||
      circleBlocked(x, z, 0.3) ||
      (p.x > 26 && p.x < 44 && p.z > 10 && p.z < 30);
    if (effectiveFirst) {
      cameraTarget.set(p.x, sim.reception.seated ? 1.45 : 1.68, p.z);
      lookTarget.set(
        p.x - Math.sin(p.yaw) * 20,
        (sim.reception.seated ? 1.45 : 1.68) + Math.sin(lookPitch) * 20,
        p.z - Math.cos(p.yaw) * 20,
      );
    } else {
      cameraTarget.set(x, 2.65, z);
      lookTarget.set(
        p.x - Math.sin(p.yaw) * 4,
        1.35 + Math.sin(lookPitch) * 5,
        p.z - Math.cos(p.yaw) * 4,
      );
    }
  }
  if (sim.reception.seated && sim.reception.computerFocus) {
    const distance = Math.max(1, 1.3 / (1.27 * camera.aspect * 0.85));
    cameraTarget.set(29.93 - distance, 1.45, 16.85);
    lookTarget.set(29.93, 1.25, 16.85);
  }
  if (sim.mode === "foot") {
    const height = floorHeight(p.x, p.z);
    cameraTarget.y += height;
    lookTarget.y += height;
  }
  if (cameraSnap) {
    camera.position.copy(cameraTarget);
    cameraSnap = false;
  } else camera.position.lerp(cameraTarget, 1 - Math.exp(-10 * dt));
  camera.lookAt(lookTarget);
}
function updateHUD() {
  if (!started) return;
  $("hud").hidden = sim.reception.seated;
  const c = sim.car,
    target = targetVehicle(sim),
    who = sim.mode === "drive" ? c : sim.player;
  $("missionTitle").textContent = sim.mission.title;
  $("missionText").textContent = missionText(sim);
  $("missionDistance").textContent =
    `${target.plate} · ${Math.round(distanceTo(who, target))} m · ${sim.completed} fiscalização(ões) concluída(s)`;
  $("checkpointStatus").textContent =
    "BLITZ DA BASE: " +
    sim.checkpoint.status +
    " · " +
    sim.checkpoint.completed +
    " veículo(s) liberado(s)";
  $("speedValue").textContent = Math.round(Math.abs(c.speed) * 3.6);
  $("condition").textContent =
    `Viatura ${c.condition}% · ${sim.mode === "drive" ? "EM SERVIÇO" : "COMANDO GERAL"} · EQUIPE ${sim.escort.boarded.length}/3`;
  $("cameraMode").textContent =
    sim.mode === "drive"
      ? c.interior
        ? "CÂMERA INTERNA"
        : "CÂMERA DA VIATURA"
      : effectiveFirst
        ? "PRIMEIRA PESSOA"
        : "TERCEIRA PESSOA";
  $("lightsBtn").setAttribute("aria-pressed", String(c.lights));
  $("sirenBtn").setAttribute("aria-pressed", String(c.siren));
  $("radarBtn").setAttribute("aria-pressed", String(sim.radar));
  $("backupBtn").disabled = sim.escort.backup.stage !== "idle" ||
    sim.time < sim.escort.backup.nextAvailable;
  $("backupBtn").textContent = sim.escort.backup.stage === "enroute"
    ? "REFORÇO A CAMINHO" : sim.escort.backup.stage === "onScene"
    ? "REFORÇO NO LOCAL" : sim.escort.backup.stage === "returning"
    ? "REFORÇO RETORNANDO" : "PEDIR REFORÇO [K]";
  $("weaponBtn").setAttribute("aria-pressed", String(sim.player.rifleEquipped));
  $("weaponBtn").hidden = sim.mode !== "foot" || sim.reception.seated;
  $("vehicleBtn").hidden =
    sim.mode === "foot" &&
    !sim.reception.seated &&
    distanceTo(sim.player, c) > 3.8;
  $("vehicleBtn").disabled = sim.mode === "drive" && Math.abs(c.speed) > 1.2;
  $("vehicleBtn").textContent = sim.reception.seated
    ? "LEVANTAR [E]"
    : sim.mode === "drive"
      ? "DESEMBARCAR [E]"
      : "EMBARCAR [E]";
  const r = sim.reception,
    report = currentReport(sim);
  $("servicePanel").hidden = true;
  $("serviceQueue").textContent =
    `Fila: ${r.visitors.filter((v) => v.state === "queue").length} · Você: ${r.completed} registro(s) · Recepção: ${r.agentCompleted}`;
  $("serviceReport").textContent = report
    ? `Senha ${report.ticket} · ${report.name} — ${report.type}. ${report.description}`
    : r.active !== null
      ? "Cidadão a caminho da sala…"
      : "Chame a próxima pessoa para ouvir o relato.";
  $("serviceHistory").textContent = r.records
    .slice(0, 3)
    .map((v) => `#${v.number} · ${v.type}`)
    .join(" | ");
  $("callCitizenBtn").disabled =
    r.active !== null || !r.visitors.some((v) => v.state === "queue");
  $("registerReportBtn").disabled = !report;
  const label = r.seated
    ? "CHAMAR PRÓXIMO [F]"
    : nearComputer(sim)
      ? "SENTAR NO COMPUTADOR [F]"
      : actionLabel(sim) ||
        (nearestAgent(sim)
          ? "ORDENS: " + nearestAgent(sim).name.toUpperCase() + " [F]"
          : "");
  $("actionBtn").hidden = !label;
  $("actionBtn").textContent = label;
  $("pedals").hidden = sim.mode !== "drive";
  $("walkPad").hidden = sim.reception.seated;
  $("runBtn").hidden = sim.mode !== "foot" || sim.reception.seated;
  $("notice").hidden = sim.noticeUntil < sim.time || !sim.notice;
  $("notice").textContent = sim.notice;
  const reading = radarReading(sim);
  $("radarPanel").hidden = sim.mode !== "foot" || !sim.radar;
  $("crosshair").hidden = sim.mode !== "foot" || !sim.radar;
  $("radarValue").textContent = reading
    ? Math.round(reading.vehicle.speed * 3.6) + " km/h"
    : "BUSCANDO";
  $("radarDistance").textContent = reading
    ? `${Math.round(reading.distance)} m · ${reading.vehicle.plate}`
    : "Aponte para um veículo";
  const m = $("map").getContext("2d");
  m.fillStyle = "#152d3c";
  m.fillRect(0, 0, 180, 180);
  const scale = 0.8;
  const px = (x) => 90 - (x - who.x) * scale,
    pz = (z) => 90 - (z - who.z) * scale;
  m.fillStyle = "#536065";
  m.fillRect(px(7), 0, 14 * scale, 180);
  m.fillStyle = "#b8ab72";
  m.fillRect(px(57), pz(45), 50 * scale, 90 * scale);
  m.fillStyle = "#d9dfd7";
  m.fillRect(px(44), pz(30), 18 * scale, 20 * scale);
  for (const t of sim.traffic) {
    m.fillStyle = t === target ? "#f2cc60" : "#9baeb5";
    m.fillRect(px(t.x) - 2, pz(t.z) - 2, 4, 4);
  }
  m.fillStyle = "#82d6e7";
  m.beginPath();
  m.arc(90, 90, 4, 0, Math.PI * 2);
  m.fill();
  commandUI.update();
}
const crewSpeechPoint = new T.Vector3();
function updateCrewSpeech() {
  const balloon = $("crewSpeech");
  const conversation = sim.command.conversation;
  if (!started || !ready || sim.paused || sim.inspection ||
      !conversation || conversation.phase !== "talk") {
    balloon.hidden = true;
    return;
  }
  const agent = sim.command.agents.find(a => a.id === conversation.speaker);
  const observer = sim.mode === "drive" ? sim.car : sim.player;
  if (!agent?.visible || Math.hypot(agent.x - observer.x, agent.z - observer.z) > 42) {
    balloon.hidden = true;
    return;
  }
  crewSpeechPoint.set(
    agent.x,
    floorHeight(agent.x, agent.z) + 2.8,
    agent.z,
  ).project(camera);
  if (crewSpeechPoint.z < -1 || crewSpeechPoint.z > 1 ||
      Math.abs(crewSpeechPoint.x) > 0.87 || Math.abs(crewSpeechPoint.y) > 0.85) {
    balloon.hidden = true;
    return;
  }
  $("crewSpeaker").textContent = agent.name.toUpperCase() + " · PRF";
  $("crewWords").textContent = conversation.text;
  balloon.style.left = ((crewSpeechPoint.x + 1) * 50).toFixed(2) + "%";
  balloon.style.top = ((1 - crewSpeechPoint.y) * 50).toFixed(2) + "%";
  balloon.hidden = false;
}
function update(dt) {
  if (!started || sim.paused || sim.inspection) return;
  const input = commandUI.isOpen
    ? { forward: 0, turn: 0, throttle: 0, steer: 0, handbrake: false }
    : sim.mode === "drive"
      ? driveInput(keys, stick)
      : walkInput(keys, stick);
  stepSimulation(sim, dt, input);
  environment.update(sim);
  updateCamera(dt);
  world.update(sim, dt, radarReading(sim), effectiveFirst);
  updateCrewSpeech();
  audio.update(sim);
  hudTime += dt;
  if (hudTime > 0.1) {
    hudTime = 0;
    updateHUD();
  }
}
function frame(now) {
  requestAnimationFrame(frame);
  if (document.hidden || sim.paused) {
    $("crewSpeech").hidden = true;
    previous = null;
    return;
  }
  const elapsed = previous === null ? 0 : now - previous;
  previous = now;
  const dt = frameStep(elapsed);
  if (started) {
    if (!economy && resolution.sample(elapsed / 1000))
      renderer.setPixelRatio(resolution.ratio);
    if (sim.inspection)
      world.update(sim, dt, radarReading(sim), effectiveFirst);
    else update(dt);
  } else world.update(sim, 0, null, false);
  if (started) {
    markerPoint
      .set(targetVehicle(sim).x, 3.0, targetVehicle(sim).z)
      .project(camera);
    const visible =
      markerPoint.z > -1 &&
      markerPoint.z < 1 &&
      Math.abs(markerPoint.x) < 0.95 &&
      Math.abs(markerPoint.y) < 0.95 &&
      sim.mission.stage !== "complete" &&
      !sim.reception.seated &&
      sim.command.view === "patrol";
    $("targetMarker").hidden = !visible;
    if (visible) {
      $("targetMarker").style.left =
        (markerPoint.x * 0.5 + 0.5) * innerWidth + "px";
      $("targetMarker").style.top =
        (-markerPoint.y * 0.5 + 0.5) * innerHeight + "px";
    }
  }
  renderer.render(scene, camera);
}
try {
  scene = new T.Scene();
  scene.background = new T.Color(0xe4bb99);
  scene.fog = new T.Fog(0xe4bb99, 160, 680);

  camera = new T.PerspectiveCamera(65, innerWidth / innerHeight, 0.05, 1000);
  scene.add(camera);
  camera.position.set(-24, 5.5, -52);
  camera.lookAt(8, 3.8, 12);
  renderer = new T.WebGLRenderer({
    antialias: true,
    powerPreference: "high-performance",
  });
  renderer.setSize(innerWidth, innerHeight);
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.15;
  document.body.prepend(renderer.domElement);
  renderer.domElement.style.touchAction = "none";
  applyQuality();
  environment = createDayNight(scene, mobile);
  sun = environment.sun;
  environment.update(sim);
  applyQuality();
  world = createRoadWorld(scene, camera, sim, mobile, (root) =>
    renderer.compileAsync(root, camera, scene),
  );
  world.update(sim, 0, null, false);
  await renderer.compileAsync(scene, camera);
  ready = true;
  $("startBtn").disabled = $("exploreBtn").disabled = false;
  $("loadStatus").textContent = "Posto e viatura prontos. Bom turno.";
  renderer.domElement.addEventListener("pointerdown", (e) => {
    if (started && sim.reception.seated && !sim.paused) {
      const action = world.base.computer.hit(
        camera,
        e.clientX,
        e.clientY,
        innerWidth,
        innerHeight,
      );
      if (action) {
        if (action === "screen") {
          sim.reception.computerFocus = !sim.reception.computerFocus;
          cameraSnap = true;
        }
        if (action === "call") callCitizen(sim);
        if (action === "register" && registerReport(sim)) audio.emit("radio");
        if (action === "leave") {
          leaveComputer(sim);
          release();
          cameraSnap = true;
        }
        updateHUD();
        world.base.computer.update(sim);
        e.preventDefault();
        return;
      }
    }
    if (
      !started ||
      sim.paused ||
      sim.inspection ||
      sim.mode !== "foot" ||
      sim.reception.computerFocus ||
      commandUI.isOpen ||
      lookPointer !== null
    )
      return;
    lookPointer = e.pointerId;
    lookX = e.clientX;
    lookY = e.clientY;
    try {
      renderer.domElement.setPointerCapture(e.pointerId);
    } catch {}
    e.preventDefault();
  });
  renderer.domElement.addEventListener("pointermove", (e) => {
    if (e.pointerId !== lookPointer || sim.paused || sim.inspection) return;
    sim.player.yaw -= (e.clientX - lookX) * 0.004;
    lookPitch = T.MathUtils.clamp(
      lookPitch - (e.clientY - lookY) * 0.003,
      -0.75,
      0.75,
    );
    lookX = e.clientX;
    lookY = e.clientY;
  });
  for (const type of ["pointerup", "pointercancel", "lostpointercapture"])
    renderer.domElement.addEventListener(type, (e) => {
      if (e.pointerId === lookPointer) lookPointer = null;
    });
  renderer.domElement.addEventListener("webglcontextlost", (e) => {
    e.preventDefault();
    if (started) setPaused(true);
    $("loadStatus").textContent =
      "Gráficos interrompidos. Recarregue a página para continuar.";
  });
  void world.avatar.ready.then((status) => {
    if (!started)
      $("loadStatus").textContent =
        status === "ready"
          ? "Posto e agente 3D prontos. Bom turno."
          : "Posto pronto • agente leve ativo (GLB indisponível).";
  });
  // BROWSER_TEST_HOOK
  requestAnimationFrame(frame);
} catch (error) {
  $("loadStatus").textContent =
    "Não foi possível iniciar os gráficos: " + error.message;
  const retry = document.createElement("button");
  retry.className = "button";
  retry.textContent = "RECARREGAR JOGO";
  retry.onclick = () => location.reload();
  $("loadStatus").after(retry);
  console.error(error);
}
window.addEventListener("resize", () => {
  release();
  if (!renderer) return;
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  resolution.maximum = Math.min(devicePixelRatio, mobile ? 1.1 : 1.5);
  applyQuality();
  previous = null;
});
