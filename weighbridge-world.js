import * as T from "./vendor/engine.js?v=2.18.0";
import {createFreightTruck} from "./freight-world.js?v=2.18.0";
export function createWeighbridgeWorld(scene){
 const root=new T.Group();scene.add(root);
 const steel=new T.MeshStandardMaterial({color:0x42515b,metalness:.6,roughness:.45}),
   road=new T.MeshStandardMaterial({color:0x39434a,roughness:.83}),
   gold=new T.MeshBasicMaterial({color:0xffd054}),
   border=new T.MeshStandardMaterial({color:0xd9d5c1,roughness:.7});
 function box(parent,m,x,y,z,w,h,d){
  const obj=new T.Mesh(new T.BoxGeometry(w,h,d),m);
  obj.position.set(x,y,z);obj.receiveShadow=true;parent.add(obj);return obj;
 }
 // Desvio lateral e plataforma metálica aparente.
 box(root,road,0,.08,0,5,.16,32);
 box(root,steel,0,.18,0,3.5,.18,19);
 for(const x of [-1.7,1.7])box(root,gold,x,.31,0,.13,.03,18);
 for(const z of [-9,9])box(root,steel,0,.35,z,4.1,.16,.24);
 box(root,border,2.7,1.05,5,1.9,2.1,1.5); // cabine de conferência
 box(root,steel,2.7,2.17,5,2.3,.24,1.9);
 box(root,steel,1.7,3.05,-8,.18,6.1,.18);
 box(root,steel,3.25,3.05,-8,.18,6.1,.18);
 box(root,steel,2.47,6.02,-8,1.9,.17,.22);
 const canvas=document.createElement("canvas");canvas.width=512;canvas.height=256;
 const texture=new T.CanvasTexture(canvas);texture.colorSpace=T.SRGBColorSpace;
 const sign=new T.Mesh(new T.PlaneGeometry(4.2,2.1),
  new T.MeshBasicMaterial({map:texture,side:T.DoubleSide}));
 sign.position.set(1.5,4.6,-8);root.add(sign);
 const truck=createFreightTruck(0x2e7382);scene.add(truck.group);
 let key="";
 function display(w){
  const next=w.stage+"|"+w.grossKg+"|"+w.completed;
  if(next===key)return;
  key=next;
  const x=canvas.getContext("2d");
  x.fillStyle="#102b35";x.fillRect(0,0,512,256);
  x.strokeStyle="#f3bf40";x.lineWidth=10;x.strokeRect(5,5,502,246);
  x.fillStyle="#f5e4a8";x.textAlign="center";
  x.font="bold 34px Arial";x.fillText("BALANÇA RODOVIÁRIA",256,52);
  x.fillStyle=w.stage==="weighed"?"#f9b043":"#a6ebc5";
  x.font="bold 68px monospace";
  x.fillText(w.grossKg.toLocaleString("pt-BR")+" KG",256,141,495);
  x.font="bold 25px Arial";x.fillStyle="#e4ebeb";
  x.fillText(w.stage==="ready"?"AGUARDANDO PESAGEM":
   w.stage==="weighed"?"REGISTRE O RESULTADO":"PESAGEM REGISTRADA",256,205);
  texture.needsUpdate=true;
 }
 return {group:root,truck,update(s){
  const w=s.weighbridge;
  root.position.set(w.x,0,w.z);
  display(w);truck.group.visible=w.truck.visible;
  if(w.truck.visible)truck.update(w.truck,s.time);
 }};
}
