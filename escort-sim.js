// Equipe embarcada e reforço policial para o simulador local.
export const ESCORT_IDS = [18, 19, 20];
export const BACKUP_IDS = [21, 22];
const SEATS = [[-0.64, 0.55], [-0.64, -0.74], [0.64, -0.74]];
const DOORS = [[-2.0, 0.65], [-2.0, -1.0], [2.0, -1.0]];
const agent = (s, id) => s.command.agents.find(a => a.id === id);
const point = (car, right, front) => ({
  x: car.x + right * Math.cos(car.heading) + front * Math.sin(car.heading),
  z: car.z - right * Math.sin(car.heading) + front * Math.cos(car.heading),
});
// A equipe de prontidão permanece dentro da unidade quando não está em patrulha.
// Os caminhos passam pela saída de pedestres e contornam a viatura estacionada.
export const ESCORT_BASE_POSITIONS = [
  [39.7, 27.2],
  [40.7, 27.2],
  [41.7, 27.2],
];
const EXIT_ROUTE = [
  [40.5, 24.6], [39.2, 20.7], [38, 16.2],
  [35, 11.8], [35, 9], [32, 6], [26.5, 4], [26.5, -4],
];
const VEHICLE_APPROACH = [
  [[22, -4], [16, -4], [16, -7.35]],
  [[22, -4], [16, -4], [16, -9]],
  [[25, -6], [24, -9]],
];
export const ESCORT_WALKOUT_ROUTES = ESCORT_BASE_POSITIONS.map((_,i) => [
  ...EXIT_ROUTE.map(p=>[...p]), ...VEHICLE_APPROACH[i].map(p=>[...p]),
]);
export function createEscort() {
  return {
    stage: "idle",
    boarded: [],
    returned: [],
    backup: {
      stage: "idle", since: 0, nextAvailable: 0,
      vehicle: { x: 0, z: 0, heading: 0, speed: 0, lights: false, plate: "PRF-REFORÇO" },
    },
  };
}
const atHeadquarters = car =>
  car.x >= 12 && car.x <= 46 && car.z >= -34 && car.z <= 39;
function prepareWalk(a, points, status) {
  a.path = points.map(p=>[...p]);
  a.waypoint = 0;
  a.visible = true;
  a.moving = false;
  a.action = "walk";
  a.task = "escort";
  a.status = status;
}
function walkPath(a, dt, speed = 3) {
  const goal=a.path[a.waypoint];
  if (!goal) { a.moving=false; return true; }
  const dx=goal[0]-a.x,dz=goal[1]-a.z;
  const distance=Math.hypot(dx,dz);
  if (distance <= 0.12) {
    a.waypoint++;
    if (a.waypoint >= a.path.length) {
      a.path=[];a.waypoint=0;a.moving=false;return true;
    }
    return false;
  }
  const step=Math.min(distance,speed*dt);
  a.x+=dx/distance*step;
  a.z+=dz/distance*step;
  a.heading=Math.atan2(dx,dz);
  a.visible=true;
  a.moving=true;
  a.action="walk";
  return false;
}
export function startEscort(s) {
  const e=s.escort;
  if (e.stage === "boarding" || e.stage === "aboard") return;
  const wasReturning=e.stage === "returning";
  e.stage = "boarding";
  e.boarded = [];
  e.returned = [];
  ESCORT_IDS.forEach((id,i) => {
    const a=agent(s,id);
    const route=wasReturning ? [] : ESCORT_WALKOUT_ROUTES[i];
    prepareWalk(a,[...route, point(s.car,...DOORS[i])],
      "Saindo da unidade para embarcar com o comandante");
  });
}
export function stopEscort(s) {
  const e=s.escort;
  if (e.stage === "idle" || e.stage === "returning") return;
  if (!atHeadquarters(s.car)) {
    // O comandante pode sair durante uma abordagem distante: a equipe aguarda
    // na viatura e não atravessa quilômetros para voltar à unidade.
    e.stage = "aboard";
    return;
  }
  e.stage = "returning";
  e.returned = [];
  e.boarded = [];
  ESCORT_IDS.forEach((id,i) => {
    const a=agent(s,id);
    const back=[
      point(s.car,...DOORS[i]),
      ...VEHICLE_APPROACH[i].slice().reverse().map(p=>[...p]),
      ...EXIT_ROUTE.slice().reverse().map(p=>[...p]),
      [...ESCORT_BASE_POSITIONS[i]],
    ];
    // A primeira posição é a porta, não uma teleportação.
    prepareWalk(a,back,"Desembarcando e retornando para dentro da unidade");
  });
}
export function updateEscort(s,dt) {
  const e=s.escort, car=s.car;
  if (e.stage === "boarding") {
    for (let i=0;i<ESCORT_IDS.length;i++) {
      const a=agent(s,ESCORT_IDS[i]);
      if (e.boarded.includes(a.id)) continue;
      if (walkPath(a,dt)) {
        e.boarded.push(a.id);
        a.status="Embarcado na viatura";
      }
    }
    if (e.boarded.length===3) e.stage="aboard";
  } else if (e.stage === "returning") {
    for (let i=0;i<ESCORT_IDS.length;i++) {
      const a=agent(s,ESCORT_IDS[i]);
      if (e.returned.includes(a.id)) continue;
      if (walkPath(a,dt)) {
        e.returned.push(a.id);
        a.task="routine";
        a.action="watch";
        a.status="Em prontidão dentro da unidade";
      }
    }
    if (e.returned.length===3) {
      e.stage="idle";
      e.returned=[];
    }
  }
  if (e.stage === "aboard" || e.stage === "boarding") {
    ESCORT_IDS.forEach((id,i) => {
      if(!e.boarded.includes(id)) return;
      const a=agent(s,id),p=point(car,...SEATS[i]);
      Object.assign(a,{x:p.x,z:p.z,heading:car.heading,visible:true,moving:false,
        action:"seated",status:s.mode === "drive"
          ? "Em patrulha com o comandante" : "Aguardando comandante na viatura"});
    });
  }
  const b=e.backup,v=b.vehicle;
  if(b.stage==="idle") {
    for(const id of BACKUP_IDS) agent(s,id).visible=false;
    return;
  }
  const ref=s.mode==="drive"?s.car:s.player;
  if(b.stage==="enroute") {
    const h=s.mode==="drive"?car.heading:s.player.yaw+Math.PI;
    const dx=ref.x-Math.sin(h)*10-v.x, dz=ref.z-Math.cos(h)*10-v.z;
    const d=Math.hypot(dx,dz);
    if(d<5 || s.time-b.since>30) {
      b.stage="onScene";b.since=s.time;v.speed=0;
    } else {
      const step=Math.min(d,Math.min(40,Math.max(22,Math.abs(car.speed)+9))*dt);
      v.x+=dx/d*step;v.z+=dz/d*step;v.heading=Math.atan2(dx,dz);
      v.speed=step/dt;
    }
  } else if (b.stage==="onScene") {
    v.speed=0;
    if(s.time-b.since>38) {b.stage="returning";b.since=s.time;}
  } else if (b.stage==="returning") {
    v.x-=Math.sin(v.heading)*20*dt;
    v.z-=Math.cos(v.heading)*20*dt;v.speed=20;
    if(s.time-b.since>4) {
      b.stage="idle";v.speed=0;v.lights=false;b.nextAvailable=s.time+85;
    }
  }
  BACKUP_IDS.forEach((id,i)=>{
    const a=agent(s,id);
    a.visible=b.stage==="onScene";
    if(!a.visible)return;
    const p=point(v,i===0?-2.2:2.2,-0.5);
    Object.assign(a,{x:p.x,z:p.z,heading:v.heading,action:"watch",moving:false,
      status:"Prestando reforço ao comandante"});
  });
}
export function requestBackup(s) {
  const b = s.escort.backup;
  if (s.paused || s.inspection)
    return { ok:false, message:"Comando indisponível durante a pausa." };
  if (b.stage !== "idle")
    return { ok:false, message:"O reforço já está a caminho ou em atendimento." };
  if (s.time < b.nextAvailable)
    return { ok:false, message:"Reforço reorganizando equipe. Aguarde novo chamado." };
  const ref = s.mode === "drive" ? s.car : s.player;
  const heading = s.mode === "drive" ? s.car.heading : s.player.yaw + Math.PI;
  b.vehicle.x = ref.x - Math.sin(heading) * 65;
  b.vehicle.z = ref.z - Math.cos(heading) * 65;
  b.vehicle.heading = heading;
  b.vehicle.lights = true;
  b.stage = "enroute"; b.since = s.time;
  return { ok:true, message:"COPOM recebido. Viatura de reforço a caminho!" };
}
