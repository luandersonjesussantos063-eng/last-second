import {decorateTraffic,updateFreightTraffic,trafficVehicleSpeed} from "./traffic-operations.js?v=2.17.0";
import {createUrbanState,updateUrbanState,urbanDriveableArea,urbanWalkableArea,URBAN_OBSTACLES} from './urban-layout.js?v=2.17.0';
import {incidentObstacles} from './incident-sim.js?v=2.17.0';
import {createOperations,updateOperations,WEATHER,inspectionDetails,recordInspection} from './operations-sim.js?v=2.17.0';
import { createShiftClock, updateShiftClock } from "./shift-clock.js?v=2.17.0";
import {createIncident,updateIncident,incidentActionLabel,incidentInteract,incidentTrafficMultiplier} from "./incident-sim.js?v=2.17.0";
import {createWeighbridge,updateWeighbridge,weighbridgeActionLabel,interactWeighbridge} from "./weighbridge-sim.js?v=2.17.0";
import { createNpcMind, updateNpcMinds } from "./npc-intelligence.js?v=2.17.0";
import { createCopom, updateCopom, canCompleteCopom, completeCopom } from "./copom-sim.js?v=2.17.0";
import { createCommand, updateCommand } from "./command-sim.js?v=2.17.0";
import { createEscort, startEscort, stopEscort, updateEscort } from "./escort-sim.js?v=2.17.0";
import {
  floorHeight,
  createBaseLife,
  updateBaseLife,
} from "./base-life.js?v=2.17.0";
import {
  createReception,
  updateReception,
  leaveComputer,
} from "./reception-sim.js?v=2.17.0";
import {
  BASE_COLUMNS,
  BLITZ_UNITS,
  BLITZ_CONES,
} from "./base-layout.js?v=2.17.0";
import {
  createCheckpoint,
  updateCheckpoint,
  checkpointControlled,
  checkpointSpeed,
} from "./blitz-sim.js?v=2.17.0";
// Metres, seconds, and radians. Vehicle heading 0 points along +Z.
export const ROAD_LIMIT = 1490;
export const POST = { x: 35, z: 20 };
// With +Z forward, the driver's right is -X (right-handed Y-up scene).
export function laneX(direction) {
  return direction > 0 ? -3.4 : 3.4;
}
export function shoulderX(direction) {
  return direction > 0 ? -9 : 9;
}
export const STATIC_OBSTACLES = [
  ...BASE_COLUMNS,
  { x: 33, z: 12.2, hx: 0.13, hz: 2.2 },
  { x: 33, z: 20.3, hx: 0.13, hz: 2.3 },
  { x: 29.5, z: 20.8, hx: 3.5, hz: 0.13 },
  { x: 29.9, z: 16, hx: 0.55, hz: 1.5 },
  ...[[-1550,-590],[-470,1550]].map(([a,b])=>({x:-12,z:(a+b)/2,hx:.15,hz:(b-a)/2})),
  ...[[-1550,-512],[-488,-135],[135,488],[512,1550]].map(([a,b])=>({x:12,z:(a+b)/2,hx:.15,hz:(b-a)/2})),
  ...URBAN_OBSTACLES,
  {x:50,z:-35,hx:.5,hz:.35},
  { x: 26, z: 20, hx: 0.35, hz: 10 },
  { x: 44, z: 20, hx: 0.35, hz: 10 },
  { x: 35, z: 30, hx: 9.3, hz: 0.35 },
  { x: 29.7, z: 10, hx: 3.7, hz: 0.35 },
  { x: 40.3, z: 10, hx: 3.7, hz: 0.35 },
  { x: 35, z: 24, hx: 3.5, hz: 1.1 },
  { x: 41, z: 17, hx: 1, hz: 2 },
  { x: 49, z: -23, hx: 1.2, hz: 2 },
  { x: 58, z: 0, hx: 0.2, hz: 45 },
];
const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const approach = (value, target, step) =>
  value < target
    ? Math.min(target, value + step)
    : Math.max(target, value - step);
export function circleBlocked(x, z, radius, obstacles = STATIC_OBSTACLES) {
  return obstacles.some((o) => {
    const dx = Math.max(Math.abs(x - o.x) - o.hx, 0),
      dz = Math.max(Math.abs(z - o.z) - o.hz, 0);
    return dx * dx + dz * dz < radius * radius;
  });
}
export function vehicleBlocked(x, z, heading, obstacles = STATIC_OBSTACLES) {
  // Three circles cover the SUV, including nose and tail, at every swept substep.
  return (
    (x > 25 && x < 45 && z > 8 && z < 31) ||
    [-1.35, 0, 1.35].some((offset) =>
      circleBlocked(
        x + Math.sin(heading) * offset,
        z + Math.cos(heading) * offset,
        0.94,
        obstacles,
      ),
    )
  );
}
export function walkInput(keys, stick = { x: 0, y: 0 }) {
  return {
    sprint: keys.has("ShiftLeft") || keys.has("ShiftRight"),
    forward:
      Number(keys.has("KeyW") || keys.has("ArrowUp")) -
      Number(keys.has("KeyS") || keys.has("ArrowDown")) -
      stick.y,
    turn:
      Number(keys.has("KeyA") || keys.has("ArrowLeft")) -
      Number(keys.has("KeyD") || keys.has("ArrowRight")) -
      stick.x,
  };
}
export function driveInput(keys, stick = { x: 0, y: 0 }) {
  return {
    throttle: clamp(
      Number(keys.has("KeyW") || keys.has("ArrowUp")) -
        Number(keys.has("KeyS") || keys.has("ArrowDown")) -
        stick.y,
      -1,
      1,
    ),
    steer: clamp(
      Number(keys.has("KeyA") || keys.has("ArrowLeft")) -
        Number(keys.has("KeyD") || keys.has("ArrowRight")) -
        stick.x,
      -1,
      1,
    ),
    handbrake: keys.has("Space"),
  };
}
export function createSimulation() {
  const traffic = Array.from({ length: 14 }, (_, i) => ({
    id: i,
    plate: `SIM-${2100 + i}`,
    x: laneX(i % 2 ? -1 : 1),
    z: i >= 8 ? [-330, -400, -750, 280, -1120, -880][i - 8]
      : i === 0 ? 55 : i === 2 ? -38 : -410 + i * 108,
    heading: i % 2 ? Math.PI : 0,
    direction: i % 2 ? -1 : 1,
    speed: 0,
    cruise: [4,9,12].includes(i) ? 10.5+(i%4) : i === 0 ? 13 : 14 + i * 0.8,
    kind: [4,9,12].includes(i) ? "truck" : [
      "sedan",
      "hatchback",
      "van",
      "motorcycle",
      "sedan",
      "pickup",
      "hatchback",
      "motorcycle",
    ][i % 8],
    color: [
      0x397caa, 0xd3d6d3, 0x8c5040, 0xc6ae76, 0x5c7466, 0xd8dfe2, 0x767d8e,
      0x823b47,
    ][i % 8],
    stopped: false,
    mind: createNpcMind("driver", i),
  }));
  decorateTraffic(traffic);
  return {
    time: 0,
    nextNpcThoughtAt: 0,
    clock: createShiftClock(),
    command: createCommand(),
    copom: createCopom(),
    operations:createOperations(),
    urban:createUrbanState(),
    incident: createIncident(),
    weighbridge: createWeighbridge(),
    escort: createEscort(),
    mode: "foot",
    paused: false,
    inspection: false,
    firstPerson: false,
    radar: false,
    player: {
      rifleEquipped: true,
      x: 27,
      z: 0,
      yaw: 2.55,
      turnVelocity: 0,
      distance: 0,
    },
    car: {
      x: 20,
      z: -8,
      heading: 0,
      speed: 0,
      steering: 0,
      wheelSpin: 0,
      condition: 100,
      fuel:100,doorOpen:0,
      lights: false,
      siren: false,
      interior: false,
    },
    traffic,
    support: BLITZ_UNITS.map((u, i) => ({
      ...u,
      x: i === 0 ? 16 : u.x,
      z: i === 0 ? 43 : i === 1 ? 36 : u.z,
      lights: i < 2 ? false : u.lights,
      speed: 0,
      steering: 0,
      wheelSpin: 0,
    })),
    checkpoint: createCheckpoint(),
    reception: createReception(),
    door: 0,
    roomDoor: 0,
    life: createBaseLife(),
    completed: 0,
    mission: {
      stage: "briefing",
      targetId: 0,
      title: "Fiscalização preventiva",
      report: null,
    },
    driver: { x: 0, z: 0, visible: false, phase: 0, walking: false },
    notice: "",
    noticeUntil: 0,
    lastImpact: -10,
    impactSerial: 0,
  };
}
export function notify(s, text, seconds = 3) {
  s.notice = text;
  s.noticeUntil = s.time + seconds;
}
export function targetVehicle(s) {
  return s.traffic[s.mission.targetId];
}
export function distanceTo(a, b) {
  return Math.hypot(a.x - b.x, a.z - b.z);
}
export function radarReading(s) {
  if (!s.radar || s.mode !== "foot") return null;
  const forward = { x: -Math.sin(s.player.yaw), z: -Math.cos(s.player.yaw) };
  return (
    s.traffic
      .map((t) => ({ vehicle: t, distance: distanceTo(s.player, t) }))
      .filter(
        ({ vehicle: t, distance: d }) =>
          d < 220 &&
          d > 1 &&
          ((t.x - s.player.x) * forward.x + (t.z - s.player.z) * forward.z) /
            d >
            0.96,
      )
      .sort((a, b) => a.distance - b.distance)[0] ?? null
  );
}
export function walkingObstacles(s) {
  const items = [
    ...STATIC_OBSTACLES,
    ...BLITZ_CONES.slice(0, s.checkpoint?.conesPlaced ?? 0).map(c => ({ x: c.x, z: c.z, hx: 0.16, hz: 0.16 })),
  ];
  if (s.roomDoor < 0.82) items.push({ x: 33, z: 16, hx: 0.15, hz: 1.8 });
  if (s.door < 0.82) items.push({ x: 35, z: 10, hx: 1.6, hz: 0.25 });
  return items;
}
export function canWalk(s, x, z) {
  if(Math.abs(z)>ROAD_LIMIT||!((x>=-12&&x<=57.4)||urbanWalkableArea(x,z)||(x>=-40&&x<=-12&&z>=-590&&z<=-470)))return false;
  if(circleBlocked(x,z,.32,incidentObstacles(s)))return false;
  if (circleBlocked(x, z, 0.32, walkingObstacles(s))) return false;
  const vehicles = [
    s.car,
    ...s.traffic,
    ...s.urban.cars,
    ...s.support,
    s.life.patrol,
    ...s.life.bikes,
    ...s.reception.visitors.filter((v) => v.car.visible).map((v) => v.car),
  ];
  return !vehicles.some((c) => {
    const dx = x - c.x,
      dz = z - c.z,
      sin = Math.sin(c.heading),
      cos = Math.cos(c.heading);
    return (
      Math.abs(dx * cos - dz * sin) < 1.25 &&
      Math.abs(dx * sin + dz * cos) < 2.65
    );
  });
}
export function interactVehicle(s) {
  if (s.inspection || s.paused) return false;
  if (s.reception.seated) return leaveComputer(s);
  if (s.mode === "foot") {
    if (distanceTo(s.player, s.car) > 3.8) {
      notify(s, "Aproxime-se da porta da viatura.");
      return false;
    }
    s.car.doorOpen=1;
    s.mode = "drive";
    startEscort(s);
    s.player.turnVelocity = 0;
    if (s.mission.stage === "briefing") s.mission.stage = "patrol";
    notify(s, "W/S: acelerar e frear · A/D: direção · G: giroflex · H: sirene");
    return true;
  }
  if (Math.abs(s.car.speed) > 1.2) {
    notify(s, "Pare a viatura antes de desembarcar.");
    return false;
  }
  for (const side of [-1, 1]) {
    const x = s.car.x + side * Math.cos(s.car.heading) * 1.9,
      z = s.car.z - side * Math.sin(s.car.heading) * 1.9;
    if (canWalk(s, x, z)) {
      s.car.doorOpen=1;
      s.mode = "foot";
      stopEscort(s);
      s.player.x = x;
      s.player.z = z;
      s.player.yaw = Math.PI + s.car.heading;
      s.car.speed = 0;
      notify(s, "A pé: W/S andar · A/D virar · E embarcar · F interagir");
      return true;
    }
  }
  notify(s, "Portas bloqueadas. Afaste a viatura do obstáculo.");
  return false;
}
export function canRequestStop(s) {
  const t = targetVehicle(s);
  return (
    s.mode === "drive" &&
    s.mission.stage === "patrol" &&
    s.car.lights &&
    distanceTo(s.car, t) < 45 &&
    Math.cos(s.car.heading - t.heading) > 0.4
  );
}
export function actionLabel(s) {
  if (canCompleteCopom(s)) return "TRANSMITIR RELATÓRIO E CONCLUIR COPOM [F]";
  const incidentAction=incidentActionLabel(s);
  if(incidentAction)return incidentAction;
  const weighAction=weighbridgeActionLabel(s);
  if(weighAction)return weighAction;
  if (canRequestStop(s)) return "SOLICITAR PARADA [F]";
  if (
    s.mode === "foot" &&
    s.driver.visible &&
    s.mission.stage === "stopped" &&
    distanceTo(s.player, s.driver) < 3
  )
    return "CONFERIR DOCUMENTOS [F]";
  if (
    s.mode === "foot" &&
    s.mission.stage === "complete" &&
    distanceTo(s.player, POST) < 11
  )
    return "NOVA FISCALIZAÇÃO [F]";
  return "";
}
export function interactMission(s) {
  if (completeCopom(s)) return "copom";
  if (incidentInteract(s)) return "incident";
  if (interactWeighbridge(s)) return "weigh";
  const t = targetVehicle(s);
  if (canRequestStop(s)) {
    s.car.siren = false;
    s.mission.stage = "pullingOver";
    s.mission.start = s.time;
    s.mission.from = { x: t.x, z: t.z, speed: t.speed };
    notify(
      s,
      "Parada solicitada. Aguarde no acostamento e mantenha distância.",
      5,
    );
    return "stop";
  }
  if (
    s.mode === "foot" &&
    s.driver.visible &&
    s.mission.stage === "stopped" &&
    distanceTo(s.player, s.driver) < 3
  ) {
    s.inspection = true;
    s.mission.report=inspectionDetails(t);
    return "inspect";
  }
  if (
    s.mode === "foot" &&
    s.mission.stage === "complete" &&
    distanceTo(s.player, POST) < 11
  ) {
    let next = (s.mission.targetId + 2) % s.traffic.length;
    for (let i = 0; i < s.traffic.length; i++) {
      if (
        next !== s.checkpoint?.vehicleId &&
        next !== s.life.evasion.vehicleId &&
        !s.traffic[next].evading
      )
        break;
      next = (next + 2) % s.traffic.length;
    }
    s.mission = {
      stage: "patrol",
      targetId: next,
      title: "Fiscalização preventiva",
      report: null,
    };
    notify(
      s,
      "Nova fiscalização atribuída. Embarque e localize o veículo marcado.",
      5,
    );
    return "new";
  }
  return "";
}
export function finishInspection(s) {
  if (!s.inspection || s.mission.stage !== "stopped") return false;
  recordInspection(s);
  s.inspection = false;
  s.mission.stage = "releasing";
  s.player.gestureUntil = s.time + 2;
  s.mission.start = s.time;
  s.completed++;
  notify(s, "Fiscalização concluída. Condutor liberado com orientação.", 5);
  return true;
}
function impact(s) {
  s.car.speed *= -0.12;
  if (s.time - s.lastImpact > 0.7) {
    s.car.condition = Math.max(0, s.car.condition - 12);
    s.lastImpact = s.time;
    s.impactSerial++;
    notify(s, "Colisão. Reduza a velocidade. R retorna ao posto.");
  }
}
function updateCar(s, dt, input) {
  const c = s.car;
  if (s.escort.stage === "boarding") { c.speed = 0; return; }
  const
    asphalt = Math.abs(c.x) < 11 || (c.x > 7 && c.x < 57 && Math.abs(c.z) < 45) || urbanDriveableArea(c.x,c.z) || (c.x>-40&&c.x< -12&&c.z>-590&&c.z< -470);
  const grip=WEATHER[s.operations.weather.kind].grip;
  c.braking=!!input.handbrake||input.throttle<0;
  let throttle = c.condition > 0 && c.fuel>0 ? input.throttle : 0;
  if (input.handbrake) c.speed = approach(c.speed, 0, 14 * grip * dt);
  else if (
    throttle &&
    Math.sign(throttle) !== Math.sign(c.speed) &&
    Math.abs(c.speed) > 0.4
  )
    c.speed = approach(c.speed, 0, 9 * grip * dt);
  else if (throttle) c.speed += throttle * (throttle > 0 ? 4.5 : 3.2) * dt;
  else c.speed = approach(c.speed, 0, (asphalt ? 0.9 : 2.8) * dt);
  c.speed = clamp(c.speed, -7.5, asphalt ? 36 : 14);
  c.speed = approach(
    c.speed,
    0,
    Math.abs(c.speed) * (asphalt ? 0.018 : 0.14) * dt,
  );
  const desired = (input.steer * 0.52) / (1 + Math.abs(c.speed) / 18);
  c.steering += (desired - c.steering) * (1 - Math.exp(-7 * dt));
  const nextHeading = c.heading + ((Math.tan(c.steering) * c.speed) / 2.8) * dt;
  const dx = Math.sin(nextHeading) * c.speed * dt,
    dz = Math.cos(nextHeading) * c.speed * dt;
  const steps = Math.max(1, Math.ceil(Math.hypot(dx, dz) / 0.3));
  for (let i = 0; i < steps; i++) {
    const x = c.x + dx / steps,
      z = c.z + dz / steps;
    const other = [
      ...s.traffic,
      ...s.urban.cars,
      ...s.support,
      ...s.life.bikes,
      ...(s.escort.backup.stage !== "idle" ? [s.escort.backup.vehicle] : []),
      ...s.reception.visitors.filter((v) => v.car.visible).map((v) => v.car),
      ...(s.weighbridge.truck.visible ? [{...s.weighbridge.truck,kind:"truck"}] : []),
      ...(s.incident.active&&s.incident.vehicle.visible?[s.incident.vehicle]:[]),
      ...(s.incident.active&&s.incident.tow.visible?[s.incident.tow]:[]),
      ...(s.incident.active&&s.incident.support.stage!=="idle"?[s.incident.support]:[]),
    ].some((t) => Math.abs(x - t.x) < 2.3 && Math.abs(z-t.z) < (t.length??5)/2+2.2);
    if (
      (!(x>=-11.5&&x<=57)&&!urbanDriveableArea(x,z)&&!(x>=-40&&x<=-12&&z>=-590&&z<=-470)) ||
      Math.abs(z) > ROAD_LIMIT ||
      vehicleBlocked(x, z, nextHeading, walkingObstacles(s)) ||
      other
    ) {
      impact(s);
      break;
    }
    c.x = x;
    c.z = z;
    c.heading = nextHeading;
  }
  c.wheelSpin += (c.speed * dt) / 0.4;
}
function updateWalker(s, dt, input) {
  const p = s.player;
  p.turnVelocity +=
    (input.turn * 1.7 - p.turnVelocity) * (1 - Math.exp(-9 * dt));
  p.yaw += p.turnVelocity * dt;
  const dx = -Math.sin(p.yaw) * input.forward * (input.sprint ? 5.5 : 3) * dt,
    dz = -Math.cos(p.yaw) * input.forward * (input.sprint ? 5.5 : 3) * dt;
  const oldX = p.x,
    oldZ = p.z,
    steps = Math.max(1, Math.ceil(Math.hypot(dx, dz) / 0.12));
  for (let i = 0; i < steps; i++) {
    if (
      Math.abs(floorHeight(p.x + dx / steps, p.z) - floorHeight(p.x, p.z)) <
        0.25 &&
      canWalk(s, p.x + dx / steps, p.z)
    )
      p.x += dx / steps;
    if (
      Math.abs(floorHeight(p.x, p.z + dz / steps) - floorHeight(p.x, p.z)) <
        0.25 &&
      canWalk(s, p.x, p.z + dz / steps)
    )
      p.z += dz / steps;
  }
  const distance = Math.hypot(p.x - oldX, p.z - oldZ);
  p.distance += distance;
  p.moving = distance > 0.0001;
  p.running = !!input.sprint && p.moving;
}
function updateTraffic(s, dt) {
  const target = targetVehicle(s);
  for (const t of s.traffic) {
    if (
      checkpointControlled(s, t) ||
      t.evading ||
      (s.life.evasion.vehicleId === t.id && s.life.evasion.stage === "detained")
    )
      continue;
    if (
      t === target &&
      ["pullingOver", "stopped", "releasing"].includes(s.mission.stage)
    )
      continue;
    let desired = t.stopped ? 0 : checkpointSpeed(s,t,t.cruise*(t.mind?.pace??1));
    desired *= incidentTrafficMultiplier(s,t);
    desired=trafficVehicleSpeed(s,t,desired);
    if (
      t === target &&
      s.mission.stage === "complete" &&
      Math.abs(target.x - laneX(target.direction)) > 0.01 &&
      s.mode === "foot" &&
      distanceTo(s.player, target) < 7
    )
      desired = 0;
    for (const lead of [
      ...s.traffic,
      s.car,
      ...s.support,
      ...(s.weighbridge.retained??[]),
      s.life.patrol,
      ...s.life.bikes,
      ...(s.escort.backup.stage !== "idle" ? [s.escort.backup.vehicle] : []),
    ]) {
      if (lead === t) continue;
      const ahead = (lead.z - t.z) * t.direction;
      const maxDistance = (t.kind==="truck"||lead.kind==="truck") ? 40:25;
      const clearance=lead.kind==="truck"?16:t.kind==="truck"?10:7;
      if (Math.abs(lead.x - t.x) < 2.7 && ahead > 0 && ahead < maxDistance)
        desired = Math.min(desired, Math.max(0,(ahead-clearance)*0.8));
    }
    if (s.mode === "foot" && Math.abs(s.player.x - t.x) < 2.6) {
      const ahead = (s.player.z - t.z) * t.direction;
      if (ahead > 0 && ahead < 30)
        desired = Math.min(desired, Math.max(0, (ahead - 5) * 0.7));
    }
    t.speed = approach(t.speed, desired, (desired < t.speed ? 10 : 2.5) * dt);
    t.z += t.speed * t.direction * dt;
    if (t.z * t.direction > ROAD_LIMIT + 40) t.z = -(ROAD_LIMIT + 40) * t.direction;
  }
  if (s.mission.stage === "pullingOver") {
    const p = clamp((s.time - s.mission.start) / 5, 0, 1),
      smooth = p * p * (3 - 2 * p);
    target.x =
      s.mission.from.x +
      (shoulderX(target.direction) - s.mission.from.x) * smooth;
    target.z = s.mission.from.z + 35 * target.direction * smooth;
    target.speed = s.mission.from.speed * (1 - p);
    if (p === 1) {
      target.speed = 0;
      target.stopped = true;
      s.mission.stage = "stopped";
      s.driver.visible = true;
      s.driver.x =
        shoulderX(target.direction) +
        Math.sign(shoulderX(target.direction)) * 2;
      s.driver.z = target.z;
      s.driver.walking = false;
      notify(
        s,
        "Veículo no acostamento. Estacione, desembarque e aproxime-se do condutor.",
        6,
      );
    }
  } else if (s.mission.stage === "releasing") {
    const p = clamp((s.time - s.mission.start) / 3, 0, 1);
    s.driver.walking = true;
    s.driver.x =
      shoulderX(target.direction) +
      Math.sign(shoulderX(target.direction)) * (2 - 1.3 * p);
    s.driver.z = target.z;
    s.driver.phase += dt * 7;
    if (p === 1) {
      s.driver.visible = false;
      s.driver.walking = false;
      target.stopped = false;
      s.mission.stage = "complete";
      target.x = shoulderX(target.direction);
    }
  } else if (
    s.mission.stage === "complete" &&
    Math.abs(target.x - laneX(target.direction)) > 0.01
  ) {
    if (s.mode !== "foot" || distanceTo(s.player, target) > 5) {
      target.x = approach(target.x, laneX(target.direction), dt * 0.7);
    } else target.speed = 0;
  }
}
export function stepSimulation(
  s,
  seconds,
  input = { forward: 0, turn: 0, throttle: 0, steer: 0, handbrake: false },
) {
  if (s.paused || s.inspection) return;
  const dt = clamp(seconds, 0, 0.05);
  s.time += dt;
  updateShiftClock(s.clock, dt);
  updateOperations(s,dt);
  updateFreightTraffic(s,dt);
  updateUrbanState(s,dt);
  if (s.mode === "drive") updateCar(s, dt, input);
  else if (!s.reception.seated) updateWalker(s, dt, input);
  updateReception(s, dt);
  updateCheckpoint(s, dt);
  const fraction = s.checkpoint.deployFraction;
  for (let i = 0; i < 2; i++) {
    const car = s.support[i], home = BLITZ_UNITS[i];
    const originX = i === 0 ? 16 : home.x;
    const originZ = i === 0 ? 43 : 36;
    car.x = originX + (home.x - originX) * fraction;
    car.z = originZ + (home.z - originZ) * fraction;
    car.heading = home.heading;
    car.lights = s.checkpoint.phase === "active";
  }
  updateTraffic(s, dt);
  updateBaseLife(s, dt);
  updateCommand(s, dt);
  updateEscort(s, dt);
  updateCopom(s);
  updateIncident(s,dt);
  updateWeighbridge(s,dt);
  updateNpcMinds(s);
  const roomNear =
    (s.mode === "foot" && Math.hypot(s.player.x - 33, s.player.z - 16) < 3.4) ||
    s.reception.visitors.some(
      (v) =>
        ["called", "exit", "player"].includes(v.state) &&
        Math.hypot(v.x - 33, v.z - 16) < 4,
    ) ||
    s.command.agents.some((a) =>
      a.visible && Math.hypot(a.x - 33, a.z - 16) < 3.2,
    );
  s.roomDoor += (Number(roomNear) - s.roomDoor) * (1 - Math.exp(-5 * dt));
  const nearby =
    s.command.agents.some(
      (a) => a.visible && Math.hypot(a.x - 35, a.z - 10) < 4,
    ) ||
    (s.mode === "foot" && Math.hypot(s.player.x - 35, s.player.z - 10) < 4) ||
    s.reception.visitors.some(
      (v) => v.state !== "away" && Math.hypot(v.x - 35, v.z - 10) < 4,
    );
  s.door += (Number(nearby) - s.door) * (1 - Math.exp(-5 * dt));
}
export function missionText(s) {
  return {
    briefing: "Aproxime-se da viatura e pressione E para embarcar.",
    patrol:
      "Localize o veículo marcado. Ligue o giroflex (G), aproxime-se e solicite parada (F).",
    pullingOver:
      "Aguarde a parada no acostamento. Mantenha distância do veículo.",
    stopped: "Estacione, desembarque (E) e fale com o condutor (F).",
    releasing:
      "Documentação conferida. Aguarde o condutor retornar ao veículo.",
    complete:
      "Fiscalização concluída. Volte ao posto para receber outra ocorrência.",
  }[s.mission.stage];
}
