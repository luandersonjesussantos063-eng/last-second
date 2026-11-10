// Cenário 3D do atendimento COPOM: objetos e agentes reais no mundo.
// Construído com geometrias locais; sem textura remota nem asset pesado.
import * as T from "./vendor/engine.js?v=2.18.0";
const mesh=(parent,g,m,x=0,y=0,z=0)=>{
 const o=new T.Mesh(g,m);o.position.set(x,y,z);o.receiveShadow=true;parent.add(o);return o;
};
const mat=(color,metalness=0)=>new T.MeshStandardMaterial({color,roughness:.74,metalness});
const orange=mat(0xf16d21),white=mat(0xf0eeea),red=mat(0xda3928);
const yellow=mat(0xe6c443),dark=mat(0x202b32),blue=mat(0x1b3552),skin=mat(0xb48b6f);
function cube(parent,m,x,y,z,w,h,d) {
 return mesh(parent,new T.BoxGeometry(w,h,d),m,x,y,z);
}
function makeCone(parent,x,z){
 const g=new T.Group();g.position.set(x,0,z);parent.add(g);
 cube(g,dark,0,.045,0,.6,.09,.6);
 mesh(g,new T.ConeGeometry(.25,.8,8),orange,0,.49,0);
 const rings=[.31,.56];
 for(const y of rings)mesh(g,new T.CylinderGeometry(.245*(1-y/.95),.27*(1-y/.95),.09,8),white,0,y,0);
 return g;
}
function createActor(parent,police){
 const g=new T.Group();parent.add(g);
 const coat=mat(police?0x182c4e:0x906957),trousers=mat(police?0x1c2434:0x465c71);
 const body=mesh(g,new T.CapsuleGeometry(.24,.53,4,8),coat,0,1.11,0);
 const head=mesh(g,new T.SphereGeometry(.18,10,8),skin,0,1.78,0);
 const hat=police?mesh(g,new T.CylinderGeometry(.21,.23,.1,10),dark,0,1.97,0):null;
 const left=mesh(g,new T.CapsuleGeometry(.085,.36,3,6),coat,-.32,1.13,0);
 const right=mesh(g,new T.CapsuleGeometry(.085,.36,3,6),coat,.32,1.13,0);
 for(const x of [-.13,.13]){
  mesh(g,new T.CapsuleGeometry(.095,.46,3,6),trousers,x,.49,0);
  cube(g,dark,x,.08,.1,.19,.15,.4);
 }
 if(police){
  cube(g,yellow,0,1.36,.24,.34,.13,.035);
  mesh(g,new T.PlaneGeometry(.25,.13),mat(0xf5d06d),0,1.54,.25);
 }
 return {g,left,right,body,head,hat};
}
function label(text,colors={bg:"#112d40",fg:"#f8da62"}){
 const c=document.createElement("canvas");c.width=512;c.height=128;
 const x=c.getContext("2d");x.fillStyle=colors.bg;x.fillRect(0,0,512,128);
 x.fillStyle=colors.fg;x.textAlign="center";x.textBaseline="middle";
 x.font="bold 46px Arial";x.fillText(text,256,64,485);
 const texture=new T.CanvasTexture(c);texture.colorSpace=T.SRGBColorSpace;
 return new T.MeshBasicMaterial({map:texture,side:T.DoubleSide,depthWrite:false});
}
export function createIncidentWorld(scene,createVehicle,camera,mobile){
 const root=new T.Group();scene.add(root);root.visible=false;
 const cones=new T.Group();root.add(cones);
 // Isolamento diagonal e duas barreiras de advertência na borda do acostamento.
 for(let n=0;n<7;n++)makeCone(cones,-.1+Math.sin(n*.65)*1.05,-20+n*5.4);
 const barricade=new T.Group();cones.add(barricade);barricade.position.set(-1.3,.25,-21);
 cube(barricade,yellow,0,.8,0,1.8,.42,.09);
 for(const x of [-.62,0,.62]){const stripe=cube(barricade,dark,x,.8,.056,.21,.42,.025);stripe.rotation.z=-.52;}
 for(const x of [-.66,.66])cube(barricade,dark,x,.34,0,.09,.7,.11);
 const labelPlane=mesh(root,new T.PlaneGeometry(6,1.5),label("OCORRÊNCIA COPOM"),0,4.6,-20);
 const skid=mesh(root,new T.PlaneGeometry(1.6,6).rotateX(-Math.PI/2),new T.MeshBasicMaterial({color:0x1b2022,transparent:true,opacity:.55,depthWrite:false}),0,.08,0);
 const impact=mesh(root,new T.BoxGeometry(1.8,.16,2.2),mat(0x5e5144),1.1,.07,0);
 const debris=new T.Group();root.add(debris);
 for(let n=0;n<4;n++){
  const o=cube(debris,n%2?dark:mat(0x848c8c),.4+n*.27,.2,(n-2)*.6,.45,.38,.39);
  o.rotation.y=n*.77;
 }
 const driver=createActor(root,false);
 const officers=[createActor(root,true),createActor(root,true)];
 const stranded=createVehicle({kind:"hatchback",color:0x9b4e4b,plate:"CIV-PANE"});
 scene.add(stranded.group);
 const support=createVehicle({police:true,plate:"PRF-COPOM"});
 scene.add(support.group);
 const tow=createVehicle({kind:"pickup",color:0xe7a329,plate:"SIM-GUINCHO"});
 scene.add(tow.group);
 // Lança de serviço e plataforma tornam a pickup uma silhueta de guincho reconhecível.
 cube(tow.group,dark,0,1.6,-1.38,1.74,.23,2.1);
 const boom=cube(tow.group,yellow,0,2.1,-1.1,.17,.19,3.4);
 boom.rotation.x=-.18;
 cube(tow.group,dark,0,1.31,-2.5,.55,.16,.7);
 const amber=new T.MeshBasicMaterial({color:0xffb52f});
 const beacon=cube(tow.group,amber,0,2.1,.5,.7,.19,.3);
 const smoke=[];
 if(!mobile)for(let n=0;n<5;n++){
  const m=new T.MeshBasicMaterial({color:0x9e9f9f,transparent:true,opacity:.18,depthWrite:false});
  const puff=mesh(root,new T.SphereGeometry(.45,7,5),m,-.6,1.5+n*.4,.6);
  smoke.push(puff);
 }
 return {group:root,officers,update(s,dt){
  const i=s.incident,observer=s.mode==="drive"?s.car:s.player;
  const visible=!!i?.active && Math.abs(observer.z-i.site.z)<680;
  root.visible=visible;
  stranded.group.visible=visible&&i.vehicle.visible;
  support.group.visible=visible&&i.support.stage!=="idle";
  tow.group.visible=visible&&i.tow.visible;
  if(!visible)return;
  root.position.set(i.site.x,0,i.site.z);
  cones.visible=["secured","surveyed","towCalled","towReady","recovering","clearing","resolved"].includes(i.stage);
  impact.visible=i.kind==="vehicle"&&i.vehicle.visible;
  skid.visible=i.kind==="vehicle"&&i.vehicle.visible;
  debris.visible=i.kind==="debris"&&i.debris.visible;
  labelPlane.visible=i.stage!=="resolved";
  labelPlane.quaternion.copy(camera.quaternion);
  smoke.forEach((p,n)=>{
   p.visible=i.kind==="vehicle" && i.vehicle.visible && i.stage!=="recovering";
   p.position.y=1.7+n*.39+Math.sin(s.time*.6+n)*.1;
   p.material.opacity=.11+.06*Math.sin(s.time+n);
  });
  driver.g.visible=i.kind==="vehicle"&&i.driver.visible;
  if(driver.g.visible){
   driver.g.position.set(i.driver.x-i.site.x,0,i.driver.z-i.site.z);
   driver.g.rotation.y= i.driver.action==="talk" ? Math.PI*.45:Math.PI;
   driver.right.rotation.z=i.driver.action==="talk"?Math.sin(s.time*3)*.4:0;
  }
  for(const [n,a] of i.agents.entries()){
   const actor=officers[n];actor.g.visible=a.visible;
   if(!a.visible)continue;
   actor.g.position.set(a.x-i.site.x,0,a.z-i.site.z);actor.g.rotation.y=a.heading;
   actor.left.rotation.z=a.action==="signal"?-1.3:Math.sin(s.time*7+n)*.15;
   actor.right.rotation.z=a.action==="documents"?-.65:0;
   actor.body.rotation.z=a.moving?Math.sin(s.time*5+n)*.04:0;
  }
  stranded.update(i.vehicle,s.time);
  support.update(i.support,s.time);
  tow.update(i.tow,s.time);
  beacon.visible=i.tow.visible&&Math.floor(s.time*5)%2===0;
 }};
}
