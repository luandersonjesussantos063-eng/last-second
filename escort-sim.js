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
export function createEscort() {
  return {
    stage: "idle",
    boarded: [],
    backup: {
      stage: "idle", since: 0, nextAvailable: 0,
      vehicle: { x: 0, z: 0, heading: 0, speed: 0, lights: false, plate: "PRF-REFORÇO" },
    },
  };
}
export function startEscort(s) {
  if (s.escort.stage !== "idle") return;
  s.escort.stage = "boarding";
  s.escort.boarded = [];
  for (const id of ESCORT_IDS) {
    const a = agent(s,id);
    a.task = "escort"; a.visible = true; a.action = "walk";
    a.status = "Embarcando com o comandante";
  }
}
export function stopEscort(s) {
  if (s.escort.stage === "idle") return;
  s.escort.stage = "idle";
  s.escort.boarded = [];
  ESCORT_IDS.forEach((id,i) => {
    const a = agent(s,id), p = point(s.car, ...DOORS[i]);
    Object.assign(a, { x:p.x, z:p.z, heading:s.car.heading, visible:true,
      moving:false, action:"watch", task:"routine", status:"Acompanhando comandante" });
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
export function updateEscort(s,dt) {
  const e=s.escort, car=s.car;
  if (e.stage === "boarding") {
    for (let i=0;i<ESCORT_IDS.length;i++) {
      const a=agent(s,ESCORT_IDS[i]);
      if (e.boarded.includes(a.id)) continue;
      const p=point(car,...DOORS[i]), dx=p.x-a.x, dz=p.z-a.z;
      const d=Math.hypot(dx,dz);
      if (d<0.22) { e.boarded.push(a.id); a.status="Embarcado na viatura"; }
      else {
        const step=Math.min(d,2.6*dt);
        a.x+=dx/d*step; a.z+=dz/d*step; a.heading=Math.atan2(dx,dz);
        a.action="walk"; a.moving=true;
      }
    }
    if (e.boarded.length===3) e.stage="aboard";
  }
  if (e.stage === "boarding" || e.stage === "aboard") {
    ESCORT_IDS.forEach((id,i) => {
      if(!e.boarded.includes(id)) return;
      const a=agent(s,id), p=point(car,...SEATS[i]);
      Object.assign(a,{x:p.x,z:p.z,heading:car.heading,visible:true,moving:false,
        action:"seated",status:"Em patrulha com o comandante"});
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
    v.x-=Math.sin(v.heading)*20*dt;v.z-=Math.cos(v.heading)*20*dt;
    v.speed=20;
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
