import * as T from './vendor/engine.js?v=2.14.0';
import {WEATHER} from './operations-sim.js?v=2.14.0';
export function createWeatherWorld(scene,camera,mobile){
 const count=mobile?90:170,dummy=new T.Object3D(),rain=new T.InstancedMesh(new T.CylinderGeometry(.008,.008,.65,3),new T.MeshBasicMaterial({color:0xa6c5de,transparent:true,opacity:.45,depthWrite:false}),count);
 rain.frustumCulled=false;rain.name='Chuva localizada';scene.add(rain);
 return {rain,update(s,dt){const w=WEATHER[s.operations.weather.kind];rain.visible=w.rain>0;scene.fog.far=w.fog;scene.fog.near=w.fog<200?18:110;
  if(w.rain){scene.fog.color.lerp(new T.Color(0x647b8e),.35);for(let i=0;i<count;i++){dummy.position.set(camera.position.x+((i*17.19)%30)-15,camera.position.y+((i*.71-s.time*14)%16+16)%16,camera.position.z+((i*13.61)%30)-15);dummy.rotation.z=.12;dummy.updateMatrix();rain.setMatrixAt(i,dummy.matrix);}rain.instanceMatrix.needsUpdate=true;}
 }};
}
