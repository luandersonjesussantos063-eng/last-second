import * as T from './vendor/engine.js?v=2.17.0';
import { FREIGHT_SPECS, PASSING_SECTION } from './traffic-operations.js?v=2.17.0';
const cache=new Map(),unitBox=new T.BoxGeometry(1,1,1);
function merge(root){const byMat=new Map();for(const m of [...root.children]){if(!m.isMesh)continue;m.updateMatrix();const g=m.geometry.index?m.geometry.toNonIndexed():m.geometry.clone();g.applyMatrix4(m.matrix);if(!byMat.has(m.material))byMat.set(m.material,[]);byMat.get(m.material).push(g);root.remove(m);}for(const [material,gs]of byMat){root.add(new T.Mesh(T.mergeGeometries(gs),material));gs.forEach(g=>g.dispose());}}
function build(type,color){
 const key=type+':'+color;if(cache.has(key))return cache.get(key);
 const spec=FREIGHT_SPECS[type]??FREIGHT_SPECS.semi,root=new T.Group();root.name=spec.label;
 const mat=(c,metalness=0)=>new T.MeshStandardMaterial({color:c,roughness:.58,metalness});
 const paint=mat(color,.25),white=mat(0xdce0d8,.2),steel=mat(0x8e9aa3,.65),black=mat(0x182229,.15),glass=mat(0x305468,.45),tire=mat(0x151a1e);
 const lamp=new T.MeshBasicMaterial({color:0xffebc1}),stripe=new T.MeshBasicMaterial({color:0xe5bf54}),tail=new T.MeshBasicMaterial({color:0xb52e2e});
 function box(m,x,y,z,w,h,d){const o=new T.Mesh(unitBox,m);o.position.set(x,y,z);o.scale.set(w,h,d);root.add(o);return o;}
 const front=spec.length/2;
 box(black,0,.8,0,2.3,.34,spec.length-.3);
 if(type==='bus'){
  box(paint,0,1.85,0,2.5,2.8,11.8);box(white,0,3.28,0,2.54,.17,11.9);box(glass,0,2.35,5.96,2.2,1.25,.06);
  for(const side of [-1,1])for(let z=-4.5;z<4.6;z+=1.5)box(glass,side*1.26,2.5,z,.045,.9,1.3);
  for(const side of [-1,1])box(stripe,side*1.27,1.26,0,.05,.2,10.6);
 }else{
  const cabZ=front-1.7;
  box(paint,0,1.9,cabZ,2.48,2.4,3.3);box(paint,0,3.18,cabZ,2.54,.22,3.4);box(glass,0,2.35,front-.02,2.15,.94,.06);box(steel,0,1.05,front,2.4,.34,.2);
  for(const side of [-1,1]){box(glass,side*1.255,2.4,cabZ+.1,.05,.9,1.9);box(black,side*1.42,2.3,front-.75,.15,.35,.3);}
  const trailers=type==='bitrem'?2:1;
  const cargoLength=type==='bitrem'?10.2:type==='boxTruck'?5:13.5;
  for(let i=0;i<trailers;i++){
   const z=front-3.7-cargoLength/2-i*(cargoLength+.9);
   box(white,0,2.35,z,2.55,3.2,cargoLength);box(steel,0,3.99,z,2.58,.12,cargoLength+.04);
   for(const side of [-1,1]){box(stripe,side*1.285,1.2,z,.04,.12,cargoLength-.4);for(let seam=-cargoLength/2+.6;seam<cargoLength/2;seam+=1.5)box(steel,side*1.286,2.5,z+seam,.025,2.7,.025);}
  }
 }
 for(const x of [-.85,.85]){box(lamp,x,1.4,front+.04,.5,.22,.05);box(tail,x,1,-front-.04,.5,.18,.05);}
 merge(root);
 const axleZ=type==='bus'?[4.1,-3.3,-4.6]:type==='boxTruck'?[3,-2.4,-3.4]:type==='bitrem'?[12,10.6,8.9,1.5,.2,-1.1,-10.2,-11.5,-12.8]:[7.2,5.8,-5,-6.4,-7.8,-3.6];
 const tyreGeo=new T.CylinderGeometry(.52,.52,.3,10).rotateZ(Math.PI/2),hubGeo=new T.CylinderGeometry(.28,.28,.32,10).rotateZ(Math.PI/2);
 for(let i=0;i<axleZ.length;i++)for(const side of [-1,1]){const w=new T.Group();w.name='FreightWheel'+i+':'+side;w.position.set(side*1.26,.53,axleZ[i]);w.add(new T.Mesh(tyreGeo,tire),new T.Mesh(hubGeo,steel));root.add(w);}
 root.traverse(o=>{if(o.isMesh){o.castShadow=true;o.receiveShadow=true;}});cache.set(key,root);return root;
}
export function createFreightTruck(color=0x447b9a,type='semi'){
 if(!Object.hasOwn(FREIGHT_SPECS,type))type='semi';const root=build(type,color).clone(true),wheels=[];root.traverse(o=>{if(o.name.startsWith('FreightWheel'))wheels.push(o);});
 return {group:root,length:FREIGHT_SPECS[type].length,type,update(c){root.position.set(c.x,0,c.z);root.rotation.y=c.heading??0;for(const w of wheels)w.rotation.x=-(c.wheelSpin??c.z/.52);}};
}
export function createFreightRoadDetails(scene){
 const root=new T.Group(),asphalt=new T.MeshStandardMaterial({color:0x434b4c,roughness:.92}),mark=new T.MeshBasicMaterial({color:0xe1dfc9});
 const length=PASSING_SECTION.to-PASSING_SECTION.from,z=(PASSING_SECTION.to+PASSING_SECTION.from)/2;
 for(const side of [-1,1]){const road=new T.Mesh(new T.BoxGeometry(4.8,.05,length),asphalt);road.position.set(side*8,.01,z);root.add(road);for(let p=PASSING_SECTION.from;p<PASSING_SECTION.to;p+=16){const line=new T.Mesh(new T.BoxGeometry(.1,.02,7),mark);line.position.set(side*5.5,.055,p);root.add(line);}}
 merge(root);scene.add(root);return root;
}
