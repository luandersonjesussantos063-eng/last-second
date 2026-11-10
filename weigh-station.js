import * as T from "./vendor/engine.js?v=2.17.0";

// Objetos originais de baixo custo: nenhum GLB, textura ou marca externa.
const mat=(color,metalness=0)=>new T.MeshStandardMaterial({color,metalness,roughness:0.78});
const steel=mat(0x71838a,0.45),tire=mat(0x1d2329),asphalt=mat(0x39464b),white=mat(0xd9e1df),yellow=mat(0xe6c953);
function cube(g,m,x,y,z,w,h,d){
 const o=new T.Mesh(new T.BoxGeometry(w,h,d),m);o.position.set(x,y,z);g.add(o);return o;
}
function sign(text,width=512,height=128){
 const canvas=document.createElement("canvas");canvas.width=width;canvas.height=height;
 const ctx=canvas.getContext("2d");ctx.fillStyle="#102b3b";ctx.fillRect(0,0,width,height);
 ctx.fillStyle="#f4d66b";ctx.font="bold 36px Arial";ctx.textAlign="center";ctx.textBaseline="middle";
 ctx.fillText(text,width/2,height/2,width-18);
 const tex=new T.CanvasTexture(canvas);tex.colorSpace=T.SRGBColorSpace;
 return new T.MeshBasicMaterial({map:tex,toneMapped:false});
}
export const WEIGH_SITE=Object.freeze({x:32,z:-520});
export function nearestWeighTruck(traffic){
 let best=null,dist=Infinity;
 for(const c of traffic){
  if(c.kind!=="truck")continue;
  const d=Math.hypot(c.x-WEIGH_SITE.x,c.z-WEIGH_SITE.z);
  if(d<dist){best=c;dist=d;}
 }
 return best&&dist<180?{plate:best.plate,speedKmh:Math.round(Math.abs(best.speed)*3.6),
  grossKg:Math.round((15600+best.id*920+Math.abs(best.speed)*31)/10)*10,distance:Math.round(dist)}:null;
}
export function createLightTruck({color=0x8b9d9f}={}){
 const group=new T.Group(),paint=mat(color,0.12),glass=mat(0x284d60,0.1);
 cube(group,steel,0,0.7,0,2.1,0.28,7.8);
 cube(group,paint,0,2.1,-1.15,2.38,2.65,5.3);
 cube(group,white,0,3.46,-1.15,2.4,0.12,5.3);
 cube(group,paint,0,1.45,2.55,2.12,2.15,2.35);
 cube(group,glass,0,1.93,3.75,1.8,0.83,0.08);
 for(const side of [-1,1]){
  cube(group,glass,side*1.07,1.95,2.58,0.04,0.7,1.2);
  cube(group,white,side*0.85,1.15,3.77,0.32,0.15,0.08);
  cube(group,steel,side*1.07,0.78,3.86,0.2,0.24,0.18);
  for(const z of [-2.95,-1.25,2.55]){
   const wheel=new T.Mesh(new T.CylinderGeometry(0.49,0.49,0.23,10),tire);
   wheel.rotation.z=Math.PI/2;wheel.position.set(side*1.15,0.48,z);group.add(wheel);
  }
 }
 cube(group,steel,0,0.75,3.84,1.9,0.16,0.15);
 const shadow=new T.Mesh(new T.PlaneGeometry(2.8,8.5),new T.MeshBasicMaterial({color:0x14202a,transparent:true,opacity:0.18,depthWrite:false}));
 shadow.rotation.x=-Math.PI/2;shadow.position.y=0.03;group.add(shadow);
 return {group,update(c){group.position.set(c.x,0,c.z);group.rotation.y=c.heading;}};
}
export function createWeighStation(scene){
 const root=new T.Group();root.name="Balança rodoviária 3D original";scene.add(root);
 const {x,z}=WEIGH_SITE;
 // Desvio lateral independente: nunca ocupa a pista principal ou os caminhos da sede.
 cube(root,asphalt,x,0.025,z,12,0.08,90);
 cube(root,steel,x,0.08,z,4.8,0.12,17);
 for(const side of [-1,1]){
  cube(root,yellow,x+side*2.5,0.15,z,0.16,0.06,17);
  for(const zz of [-30,-17,17,30])cube(root,white,x+side*5.6,0.08,z+zz,0.15,0.025,5);
 }
 cube(root,steel,x-7,2.5,z-2,0.22,5,0.22);
 cube(root,steel,x+7,2.5,z-2,0.22,5,0.22);
 cube(root,steel,x,4.95,z-2,14.4,0.35,0.45);
 const banner=new T.Mesh(new T.PlaneGeometry(9,1.25),sign("BALANÇA • FISCALIZAÇÃO"));
 banner.position.set(x,4.35,z-2.26);banner.rotation.y=Math.PI;root.add(banner);
 // Cabine e monitor eletrônico com atualização periódica dos dados simulados.
 cube(root,white,x+10,1.65,z+10,5,3.3,6);
 cube(root,glass,x+10,2.15,z+6.94,3.8,1.15,0.1);
 cube(root,steel,x+10,3.4,z+10,5.6,0.3,6.5);
 cube(root,steel,x-6,2.3,z+8,0.24,4.6,0.24);
 const canvas=document.createElement("canvas");canvas.width=512;canvas.height=256;
 const texture=new T.CanvasTexture(canvas);texture.colorSpace=T.SRGBColorSpace;
 const monitor=new T.Mesh(new T.PlaneGeometry(4.5,2.3),new T.MeshBasicMaterial({map:texture,toneMapped:false}));
 monitor.position.set(x-6,3.9,z+8);monitor.rotation.y=Math.PI/2;root.add(monitor);
 let last="",elapsed=1;
 function update(s,dt){
  elapsed+=dt;if(elapsed<0.3)return;elapsed=0;
  const truck=nearestWeighTruck(s.traffic);
  const lines=truck?["BALANÇA • SIMULAÇÃO",truck.plate,
   "PESO: "+truck.grossKg.toLocaleString("pt-BR")+" kg",
   "VELOC.: "+truck.speedKmh+" km/h"] : ["BALANÇA • SIMULAÇÃO","AGUARDANDO CARRETA","PESO: -- kg","VELOC.: -- km/h"];
  const value=lines.join("|");if(value===last)return;last=value;
  const ctx=canvas.getContext("2d");ctx.fillStyle="#102b3b";ctx.fillRect(0,0,512,256);
  ctx.fillStyle="#f0cf67";ctx.textAlign="center";ctx.font="bold 27px Arial";
  lines.forEach((line,i)=>ctx.fillText(line,256,44+i*59,485));texture.needsUpdate=true;
 }
 return {root,monitor,update};
}
