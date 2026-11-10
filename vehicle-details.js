import * as T from './vendor/engine.js?v=2.23.0';
// Immutable, cached conversion of the authored SUV shell into actual hinged doors.
const cache=new WeakMap();
export const DOOR_REGIONS=[
 {name:'LF',side:-1,min:[-1.4,.63,-.475],max:[-.8,1.985,.78],hinge:[-.99,.95,.78]},
 {name:'RF',side:1,min:[.8,.63,-.475],max:[1.4,1.985,.78],hinge:[.99,.95,.78]},
 {name:'LR',side:-1,min:[-1.4,.63,-1.65],max:[-.8,1.985,-.555],hinge:[-.99,.95,-.555]},
 {name:'RR',side:1,min:[.8,.63,-1.65],max:[1.4,1.985,-.555],hinge:[.99,.95,-.555]},
];
function mix(a,b,t){return a.map((value,i)=>value+(b[i]-value)*t);}
function plane(poly,axis,bound,sign){
 const inside=[],outside=[];
 for(let i=0;i<poly.length;i++){
  const a=poly[i],b=poly[(i+1)%poly.length],da=(a[axis]-bound)*sign,db=(b[axis]-bound)*sign;
  if(da>=-1e-8)inside.push(a);if(da<=1e-8)outside.push(a);
  if((da>1e-8&&db< -1e-8)||(da< -1e-8&&db>1e-8)){
   const p=mix(a,b,da/(da-db));inside.push(p);outside.push(p);
  }
 }
 return {inside,outside};
}
export function splitDoorPolygon(poly,region){
 let inside=poly;const outside=[];
 for(let axis=0;axis<3;axis++)for(const [bound,sign]of [[region.min[axis],1],[region.max[axis],-1]]){
  if(inside.length<3)return {inside:[],outside};
  const split=plane(inside,axis,bound,sign);if(split.outside.length>=3)outside.push(split.outside);inside=split.inside;
 }
 return {inside:inside.length>=3?inside:[],outside};
}
function appendTriangles(target,poly){for(let i=1;i<poly.length-1;i++)target.push(poly[0],poly[i],poly[i+1]);}
function geometryFrom(source,vertices,offset=[0,0,0]){
 if(!vertices.length)return null;
 const g=source.clone();g.setIndex(null);g.clearGroups();
 let cursor=0;
 for(const [name,attribute]of Object.entries(source.attributes)){
  const values=new Float32Array(vertices.length*attribute.itemSize);
  vertices.forEach((v,index)=>{for(let k=0;k<attribute.itemSize;k++)values[index*attribute.itemSize+k]=v[cursor+k]-(name==='position'?(offset[k]??0):0);});
  // GLB vehicle attributes are ordinary Float32 BufferAttributes. Preserve their type.
  g.setAttribute(name,new attribute.constructor(values,attribute.itemSize,attribute.normalized));cursor+=attribute.itemSize;
 }
 g.computeBoundingBox();g.computeBoundingSphere();return g;
}
const shared={
 bodyGeometry:new T.CapsuleGeometry(.15,.28,3,7),headGeometry:new T.SphereGeometry(.12,8,6),capGeometry:new T.CylinderGeometry(.135,.14,.06,8),
 navy:new T.MeshStandardMaterial({color:0x1b3049,roughness:.8}),skin:new T.MeshStandardMaterial({color:0xbb9276,roughness:.85}),
 dark:new T.MeshStandardMaterial({color:0x152129,roughness:.8}),white:new T.MeshBasicMaterial({color:0xfff3c9}),red:new T.MeshBasicMaterial({color:0xff3d28}),
};
function addBox(parent,name,material,x,y,z,w,h,d){const o=new T.Mesh(new T.BoxGeometry(w,h,d),material);o.name=name;o.position.set(x,y,z);parent.add(o);return o;}
export function prepareVehicleTemplate(source){
 if(cache.has(source))return cache.get(source);
 const root=source.clone(true);root.updateMatrixWorld(true);
 const inverse=root.matrixWorld.clone().invert(),bodies=[];root.traverse(o=>{if(o.isMesh&&o.name.startsWith('Body_'))bodies.push(o);});
 const sprung=new T.Group();sprung.name='VehicleSuspensionBody';root.add(sprung);
 const doors=DOOR_REGIONS.map(r=>{const g=new T.Group();g.name='VehicleDoor'+r.name;g.position.set(...r.hinge);sprung.add(g);return g;});
 let extracted=0,originalTriangles=0;
 for(const mesh of bodies){
  const matrix=inverse.clone().multiply(mesh.matrixWorld),sourceGeometry=mesh.geometry.clone().applyMatrix4(matrix),attrs=Object.entries(sourceGeometry.attributes),stride=attrs.reduce((n,[,a])=>n+a.itemSize,0),indices=sourceGeometry.index,count=indices?.count??sourceGeometry.attributes.position.count;
  const rest=[],parts=doors.map(()=>[]);
  function vertex(id){const out=[];for(const [,a]of attrs)for(let k=0;k<a.itemSize;k++)out.push(a.getComponent(id,k));return out;}
  for(let i=0;i<count;i+=3){
   const poly=[0,1,2].map(k=>vertex(indices?indices.getX(i+k):i+k));originalTriangles++;
   // The front windshield and rear glass remain fixed. Only side glazing belongs to doors.
   const a=new T.Vector3(...poly[0].slice(0,3)),b=new T.Vector3(...poly[1].slice(0,3)),c=new T.Vector3(...poly[2].slice(0,3));
   const normal=b.sub(a).cross(c.sub(a)).normalize();
   if(mesh.name.includes('glass')&&Math.abs(normal.x)<.75){appendTriangles(rest,poly);continue;}
   let remaining=[poly];
   DOOR_REGIONS.forEach((region,door)=>{const next=[];for(const p of remaining){const split=splitDoorPolygon(p,region);if(split.inside.length){appendTriangles(parts[door],split.inside);extracted++;}next.push(...split.outside);}remaining=next;});
   remaining.forEach(p=>appendTriangles(rest,p));
  }
  const fixedGeometry=geometryFrom(sourceGeometry,rest);
  if(fixedGeometry){const fixed=new T.Mesh(fixedGeometry,mesh.material);fixed.name=mesh.name;fixed.castShadow=true;fixed.receiveShadow=true;sprung.add(fixed);}
  parts.forEach((vertices,index)=>{const geometry=geometryFrom(sourceGeometry,vertices,DOOR_REGIONS[index].hinge);if(!geometry)return;const p=new T.Mesh(geometry,mesh.material);p.name='DoorPanel'+DOOR_REGIONS[index].name+'_'+mesh.name;p.castShadow=true;p.receiveShadow=true;doors[index].add(p);});
  mesh.removeFromParent();sourceGeometry.dispose();
 }
 const occupants=new T.Group();occupants.name='VehicleOccupants';sprung.add(occupants);
 const seats=[[-.45,.12],[.45,.12],[-.45,-.8],[.45,-.8]];
 seats.forEach(([x,z],i)=>{const g=new T.Group();g.name='VehicleOccupant'+i;g.position.set(x,0,z);const torso=new T.Mesh(shared.bodyGeometry,shared.navy);torso.position.y=1.27;const head=new T.Mesh(shared.headGeometry,shared.skin);head.position.set(0,1.64,-.09);const cap=new T.Mesh(shared.capGeometry,shared.navy);cap.position.set(0,1.755,-.09);g.add(torso,head,cap);occupants.add(g);});
 const headlights=new T.Group();headlights.name='VehicleHeadlightGlow';sprung.add(headlights);
 const brake=new T.Group();brake.name='VehicleBrakeGlow';sprung.add(brake);
 for(const x of [-.72,.72])addBox(headlights,'HeadlightLens',shared.white,x,1.0,2.235,.35,.15,.012);
 for(const x of [-.82,.82])addBox(brake,'BrakeLens',shared.red,x,1.05,-2.226,.16,.34,.012);
 const damage=new T.Group();damage.name='VehicleDamage';sprung.add(damage);
 for(const side of [-1,1]){const m=addBox(damage,'DamageDent'+side,shared.dark,side*1.022,.88,.3,.025,.15,.52);m.rotation.x=.14;}
 root.userData.vehicleDetails={extracted,originalTriangles,doors:4};
 cache.set(source,root);return root;
}
export function bindVehicleDetails(model){
 const body=model.getObjectByName('VehicleSuspensionBody'),doors=DOOR_REGIONS.map(r=>model.getObjectByName('VehicleDoor'+r.name)),occupants=[0,1,2,3].map(i=>model.getObjectByName('VehicleOccupant'+i));
 return {body,doors,occupants,update(c,time){
  const speed=Math.abs(c.speed??0),requested=Array.isArray(c.doorOpen)?c.doorOpen:doors.map(()=>c.doorOpen??0);
  doors.forEach((door,i)=>{if(door){const amount=speed>1?0:Math.max(0,Math.min(1,requested[i]??0));door.rotation.y=amount?amount*(-DOOR_REGIONS[i].side)*1.08:0;}});
  const count=Math.max(0,Math.min(4,Math.floor(c.occupants??0)));occupants.forEach((o,i)=>{if(o)o.visible=i<count;});
  model.getObjectByName('VehicleHeadlightGlow').visible=!!c.headlights;
  model.getObjectByName('VehicleBrakeGlow').visible=!!c.braking;
  model.getObjectByName('VehicleDamage').visible=(c.condition??100)<70;
  if(body){body.position.y=Math.sin(time*(4+speed*.4))*.018*Math.min(1,speed/5);body.rotation.z=-(c.steering??0)*Math.min(.06,speed*.002);body.rotation.x=(c.braking?-.015:0);}
 }};
}
