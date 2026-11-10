import * as T from './vendor/engine.js?v=2.17.0';
import {TOWNS,URBAN_BUILDINGS,signalPhase} from './urban-layout.js?v=2.17.0';
// Shared materials, merged static town geometry and bounded commuters.
export function createUrbanWorld(scene,{createVehicle,mobile=false}={}){
 const fixed=new T.Group();fixed.name='Cidades conectadas';scene.add(fixed);
 const road=new T.MeshStandardMaterial({color:0x3e4b52,roughness:.94}),concrete=new T.MeshStandardMaterial({color:0xaeb7b1,roughness:.9}),white=new T.MeshStandardMaterial({color:0xd8ddd6,roughness:.8}),metal=new T.MeshStandardMaterial({color:0x263744,metalness:.3,roughness:.6}),glass=new T.MeshStandardMaterial({color:0x375d73,metalness:.3,roughness:.25}),warm=new T.MeshBasicMaterial({color:0xffdfaa});
 const colors=new Map(),color=c=>{if(!colors.has(c))colors.set(c,new T.MeshStandardMaterial({color:c,roughness:.8}));return colors.get(c);};
 function box(mat,x,y,z,w,h,d){const m=new T.Mesh(new T.BoxGeometry(w,h,d),mat);m.position.set(x,y,z);m.receiveShadow=true;m.castShadow=true;fixed.add(m);return m;}
 function label(text,x,y,z,width,rotation=0){const c=document.createElement('canvas');c.width=512;c.height=96;const g=c.getContext('2d');g.fillStyle='#163243';g.fillRect(0,0,512,96);g.fillStyle='#f7d579';g.font='bold 34px Arial';g.textAlign='center';g.textBaseline='middle';g.fillText(text,256,48,490);const map=new T.CanvasTexture(c);map.colorSpace=T.SRGBColorSpace;const mesh=new T.Mesh(new T.PlaneGeometry(width,.85),new T.MeshBasicMaterial({map}));mesh.position.set(x,y,z);mesh.rotation.y=rotation;scene.add(mesh);return mesh;}
 const nightLights=[],signals=[];
 for(const t of TOWNS){
  box(concrete,170,-.04,t.z,160,.12,132);box(road,116,.04,t.z,244,.08,15);
  for(const x of [100,165,230])box(road,x,.05,t.z,15,.08,116);
  for(const z of [t.z-50,t.z+50])box(road,165,.05,z,146,.08,15);
  // Forecourts and driveways remain open; pumps have matching collision boxes.
  box(road,130,.055,t.z-25,50,.08,32);box(road,124,.055,t.z-12,14,.08,32);
  box(road,185,.055,t.z+25,42,.08,24);box(road,165,.055,t.z+13,14,.08,36);
  for(const z of [t.z-50,t.z,t.z+50])for(let x=14;x<235;x+=12)box(white,x,.105,z,5,.015,.15);
  for(const x of [100,165,230])for(let z=t.z-50;z<t.z+52;z+=12)box(white,x,.105,z,.15,.015,5);
  for(const x of [119,129]){box(white,x,.9,t.z-25,2.1,1.8,1);box(glass,x,1.35,t.z-25.52,1.4,.6,.05);}
  box(color(0x386d8f),124,4.1,t.z-25,23,.35,17);for(const x of [114,134])box(metal,x,2,t.z-30,.15,4,.15);
  label('POSTO · COMBUSTÍVEL',124,4,t.z-15.8,16);
  for(const x of [174,181,188,195])for(const z of [t.z+17,t.z+33])box(white,x,.12,z,.12,.025,7);
  label(t.name,65,3.6,t.z-8,17,Math.PI);for(const x of [57,73])box(metal,x,1.8,t.z-8,.15,3.6,.15);
  for(const sx of [100,165,230])for(const sz of [t.z-50,t.z,t.z+50]){
   const root=new T.Group();root.position.set(sx+7.7,0,sz+7.7);scene.add(root);
   const pole=new T.Mesh(new T.CylinderGeometry(.07,.1,4,6),metal);pole.position.y=2;root.add(pole);
   const housing=new T.Mesh(new T.BoxGeometry(.65,1.6,.5),metal);housing.position.y=3.5;root.add(housing);
   const lamps=[];for(const [i,c] of [0xdd442e,0xe5c241,0x58be6d].entries()){const m=new T.Mesh(new T.SphereGeometry(.18,8,6),new T.MeshBasicMaterial({color:c}));m.position.set(0,4-i*.5,-.28);root.add(m);lamps.push(m);}
   signals.push({lamps,town:t.id});
  }
  for(const x of [95,235]){box(metal,x,3.1,t.z-60,.12,6.2,.12);box(warm,x,6.3,t.z-60,1.5,.1,.5);}
  const light=new T.PointLight(0xffe1ac,0,110,2);light.position.set(165,10,t.z);scene.add(light);nightLights.push({light,town:t});
 }
 for(const b of URBAN_BUILDINGS){box(color(b.color),b.x,b.height/2,b.z,b.hx*2,b.height,b.hz*2);box(metal,b.x,b.height+.15,b.z,b.hx*2+.5,.3,b.hz*2+.5);
  const front=b.z>TOWNS.find(t=>Math.abs(b.z-t.z)<90).z?-1:1;const z=b.z+front*(b.hz+.025);
  for(let x=b.x-b.hx+3;x<b.x+b.hx-2;x+=5)box(glass,x,2.5,z,3,2.5,.05);
  label(b.title,b.x,b.height-.6,z+front*.03,Math.min(26,b.hx*1.8),front<0?Math.PI:0);
 }
 // Merge once per material; original geometries can then be released.
 const merged=new Map();for(const m of [...fixed.children]){m.updateMatrix();const g=m.geometry.toNonIndexed();g.applyMatrix4(m.matrix);if(!merged.has(m.material))merged.set(m.material,[]);merged.get(m.material).push(g);fixed.remove(m);m.geometry.dispose();}
 for(const [mat,parts]of merged){const m=new T.Mesh(T.mergeGeometries(parts),mat);m.receiveShadow=true;m.castShadow=true;fixed.add(m);parts.forEach(g=>g.dispose());}
 const traffic=Array.from({length:4},(_,i)=>{const m=createVehicle?.({color:[0x816a51,0x7792aa][i%2],plate:'URB-'+(300+i),kind:i%2?'hatchback':'sedan'});if(m)scene.add(m.group);return m;});
 const skin=new T.MeshStandardMaterial({color:0xb99179}),cloth=new T.MeshStandardMaterial({color:0x537081}),pants=new T.MeshStandardMaterial({color:0x263946});
 const heads=new T.InstancedMesh(new T.SphereGeometry(.16,8,6),skin,8),bodies=new T.InstancedMesh(new T.CapsuleGeometry(.2,.42,3,6),cloth,8),legs=new T.InstancedMesh(new T.CapsuleGeometry(.08,.46,3,6),pants,16);for(const m of [heads,bodies,legs]){m.frustumCulled=false;scene.add(m);}const d=new T.Object3D();
 return {root:fixed,traffic,nightLights,update(s,dt){if(!s.urban)return;const observer=s.mode==='drive'?s.car:s.player;
  s.urban.cars.forEach((c,i)=>{const m=traffic[i];if(!m)return;m.group.visible=Math.hypot(c.x-observer.x,c.z-observer.z)<300;if(m.group.visible)m.update(c,s.time);});
  s.urban.pedestrians.forEach((p,i)=>{const visible=Math.hypot(p.x-observer.x,p.z-observer.z)<(mobile?180:280);for(const [mesh,y,offset,index] of [[heads,1.65,0,i],[bodies,1.1,0,i],[legs,.45,-.11,i*2],[legs,.45,.11,i*2+1]]){d.position.set(p.x+Math.cos(p.heading)*offset,y+(mesh===legs?Math.sin(p.phase+(offset<0?0:Math.PI))*.035:0),p.z-Math.sin(p.heading)*offset);d.rotation.set(mesh===legs?Math.sin(p.phase+(offset<0?0:Math.PI))*.22:0,p.heading,0);d.scale.setScalar(visible?1:0);d.updateMatrix();mesh.setMatrixAt(index,d.matrix);}});
  heads.instanceMatrix.needsUpdate=bodies.instanceMatrix.needsUpdate=legs.instanceMatrix.needsUpdate=true;
  signals.forEach(item=>{const phase=signalPhase(s.time,item.town==='serra'?0:4),on=phase==='eastWest'?2:phase==='clear'?1:0;item.lamps.forEach((l,i)=>l.visible=i===on);});
  const night=s.clock.minute<360||s.clock.minute>=1080;for(const {light,town}of nightLights)light.intensity=night&&Math.hypot(observer.x-town.x,observer.z-town.z)<300?300:0;
 }};
}
