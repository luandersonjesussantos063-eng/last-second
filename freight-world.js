import * as T from "./vendor/engine.js?v=2.18.0";
// Carretas com cabine, baú articulado, eixos, faixas refletivas e rodas reais no cenário.
export function createFreightTruck(color=0x447b9a) {
 const root=new T.Group();
 const material=(c,metalness=0)=>new T.MeshStandardMaterial({color:c,roughness:.68,metalness});
 const cab=material(color,.28),trailer=material(0xd0d5d2,.14),chassis=material(0x202832,.3),
   glass=material(0x244b60,.25),rubber=material(0x181c20),silver=material(0xb6c0c4,.65),
   stripe=new T.MeshBasicMaterial({color:0xe7b844}),tail=new T.MeshBasicMaterial({color:0xd14e3a});
 const box=(m,x,y,z,w,h,d)=>{
  const mesh=new T.Mesh(new T.BoxGeometry(w,h,d),m);
  mesh.position.set(x,y,z);mesh.castShadow=true;mesh.receiveShadow=true;root.add(mesh);return mesh;
 };
 box(chassis,0,.85,-1.65,2.36,.33,13.3);
 // Cabine na dianteira (+Z), trailer para trás (-Z).
 box(cab,0,1.9,4.1,2.46,2.5,3.4);
 box(glass,0,2.45,5.86,2.15,.95,.07);
 box(cab,0,3.28,4.15,2.48,.25,3.45);
 box(silver,0,1.3,5.89,2.45,.42,.21);
 box(chassis,0,.94,5.96,2.36,.3,.18);
 box(trailer,0,2.36,-3.2,2.54,3.35,8.9);
 box(silver,0,4.04,-3.2,2.59,.13,8.99);
 // Faixas refletores e logomarca fictícia do transportador.
 for(const side of [-1,1]){
  box(stripe,side*1.3,1.2,-3.4,.04,.13,7.9);
  box(silver,side*1.29,2,-3.3,.045,.18,1.1);
  box(glass,side*1.252,2.55,4.22,.07,.82,1.32);
  box(silver,side*1.27,1.2,5.1,.08,.17,.4);
 }
 for(const x of [-.9,.9]){
  box(tail,x,1.15,-7.68,.52,.22,.1);
  box(new T.MeshBasicMaterial({color:0xfff5d8}),x,1.9,5.83,.54,.18,.08);
 }
 const wheelset=[];
 for(const z of [4.8,3.2,-3.8,-5.6,-6.85])for(const x of [-1.28,1.28]){
  const axle=new T.Group();axle.position.set(x,.52,z);
  const tyre=new T.Mesh(new T.CylinderGeometry(.56,.56,.32,12).rotateZ(Math.PI/2),rubber);
  const hub=new T.Mesh(new T.CylinderGeometry(.3,.3,.33,12).rotateZ(Math.PI/2),silver);
  axle.add(tyre,hub);root.add(axle);wheelset.push(axle);
 }
 const label=new T.MeshBasicMaterial({color:0x244c6b});
 box(label,0,2.6,-7.72,1.7,.55,.035);
 return {
  group:root,length:15,
  update(c,time){
   root.position.set(c.x,0,c.z);root.rotation.y=c.heading;
   for(const wheel of wheelset)wheel.rotation.x=-(c.wheelSpin??c.z/.56);
  }
 };
}
