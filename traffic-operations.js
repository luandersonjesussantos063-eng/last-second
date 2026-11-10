// Local fictional freight data. Existing traffic IDs and mission assignments stay stable.
export const FREIGHT_SPECS = {
 semi:{label:'Carreta',length:18,width:2.55,axles:6,massKg:51600,limitKg:48500},
 boxTruck:{label:'Caminhão-baú',length:9,width:2.5,axles:3,massKg:21400,limitKg:23000},
 bitrem:{label:'Bitrem',length:28,width:2.55,axles:9,massKg:71000,limitKg:74000},
 bus:{label:'Ônibus',length:12,width:2.5,axles:3,massKg:18100,limitKg:23000},
};
export const PASSING_SECTION={from:450,to:900,outerX:7.7};
export function decorateTraffic(traffic){
 for(const t of traffic){
  const type={4:'semi',9:'boxTruck',12:'bitrem',10:'bus'}[t.id];
  if(type){Object.assign(t,FREIGHT_SPECS[type],{freightType:type});if(type==='bus')t.cruise=18;}
  t.length??=t.kind==='motorcycle'?2.2:4.8;t.width??=t.kind==='motorcycle'?.8:1.9;
  t.baseCruise??=t.cruise;t.passing=false;t.indicator=false;
 }
 return traffic;
}
const near=(a,b)=>Math.hypot(a.x-b.x,a.z-b.z);
function freeLane(s,t,x){return [...s.traffic,s.car].every(o=>o===t||Math.abs(o.x-x)>2.8||Math.abs(o.z-t.z)>(t.length+o.length)/2+28);}
export function updateFreightTraffic(s,dt){
 if(s.paused||s.inspection)return;
 for(const t of s.traffic){
  if(!t.freightType||t.stopped||t.evading||t.id===s.checkpoint?.vehicleId||t.id===s.mission.targetId&&['pullingOver','stopped','releasing'].includes(s.mission.stage))continue;
  const inSection=t.z>PASSING_SECTION.from+50&&t.z<PASSING_SECTION.to-50;
  const normal=t.direction>0?-3.4:3.4,outer=-t.direction*PASSING_SECTION.outerX;
  let desiredX=inSection&&!t.passing?outer:normal;
  const leader=s.traffic.filter(o=>o!==t&&Math.abs(o.x-t.x)<2.8&&(o.z-t.z)*t.direction>0).sort((a,b)=>(a.z-b.z)*t.direction)[0];
  if(inSection&&!t.passing&&Math.abs(t.x-outer)<.6&&leader&&leader.direction===t.direction&&leader.speed+2<t.cruise&&(leader.z-t.z)*t.direction<65&&freeLane(s,t,normal)){t.passing=true;t.passId=leader.id;desiredX=normal;}
  const target=s.traffic.find(o=>o.id===t.passId);
  if(t.passing&&(!inSection||!target||(t.z-target.z)*t.direction>(t.length+target.length)/2+16)){
   if(!inSection||freeLane(s,t,outer)){t.passing=false;desiredX=inSection?outer:normal;}
  }
  if(s.car.siren&&near(s.car,t)<90){desiredX=-t.direction*8.6;t.passing=false;}
  t.indicator=Math.abs(desiredX-t.x)>.25;
  const maxMove=Math.max(0,Math.min(.05,dt))*.7;
  t.x+=Math.sign(desiredX-t.x)*Math.min(Math.abs(desiredX-t.x),maxMove);
 }
}
export function trafficVehicleSpeed(s,t,desired){
 const hour=(s.clock?.minute??720)/60;
 const factor=hour<6||hour>=20?.86:hour>=7&&hour<9||hour>=17&&hour<19?.92:1;
 if(t.freightType&&s.car.siren&&near(s.car,t)<90)return Math.min(desired,6);
 return Math.min(desired,t.baseCruise??t.cruise)*factor;
}
export function freightCollision(x,z,radius,c){
 const dx=x-c.x,dz=z-c.z,sin=Math.sin(c.heading??0),cos=Math.cos(c.heading??0);
 return Math.abs(dx*cos-dz*sin)<(c.width??1.9)/2+radius&&Math.abs(dx*sin+dz*cos)<(c.length??4.8)/2+radius;
}
