import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as T from '../vendor/engine.js';
import {prepareVehicleTemplate,bindVehicleDetails,DOOR_REGIONS,splitDoorPolygon} from '../vehicle-details.js';
const buffer=readFileSync('assets/models/prf-suv.glb');
const parsed=new T.GLTFLoader().parseAsync(buffer.buffer.slice(buffer.byteOffset,buffer.byteOffset+buffer.byteLength),'');
function polygonArea(poly){let sum=0;for(let i=1;i<poly.length-1;i++){const a=new T.Vector3(...poly[0].slice(0,3)),b=new T.Vector3(...poly[i].slice(0,3)),c=new T.Vector3(...poly[i+1].slice(0,3));sum+=b.sub(a).cross(c.sub(a)).length()/2;}return sum;}
function meshArea(mesh){const g=mesh.geometry,index=g.index,p=g.attributes.position;let sum=0;for(let i=0;i<(index?.count??p.count);i+=3){const poly=[0,1,2].map(k=>{const n=index?index.getX(i+k):i+k;return new T.Vector3(p.getX(n),p.getY(n),p.getZ(n)).applyMatrix4(mesh.matrixWorld).toArray();});sum+=polygonArea(poly);}return sum;}
test('door clipping preserves polygon area and the outer shell has genuine separated door openings',async()=>{
 const source=(await parsed).scene;source.updateMatrixWorld(true);let original=0;source.traverse(o=>{if(o.isMesh&&o.name.startsWith('Body_'))original+=meshArea(o);});
 const prepared=prepareVehicleTemplate(source);prepared.updateMatrixWorld(true);const body=prepared.getObjectByName('VehicleSuspensionBody');let split=0;body.traverse(o=>{if(o.isMesh&&(o.name.startsWith('Body_')||o.name.startsWith('DoorPanel')))split+=meshArea(o);});
 assert(Math.abs(split-original)<.001,`clipping changed shell area ${original} / ${split}`);
 assert.equal(prepared.userData.vehicleDetails.doors,4);assert(prepared.userData.vehicleDetails.extracted>20);
 for(const region of DOOR_REGIONS)assert(prepared.getObjectByName('VehicleDoor'+region.name).children.length>=3);
 assert.equal(source.getObjectByName('VehicleDoorLF'),undefined,'source cache remains immutable');
 assert.equal(prepareVehicleTemplate(source),prepared,'door buffers are prepared once');
 const poly=[[0,0,0],[2,0,0],[0,2,0]],r={min:[0,0,-1],max:[1,1,1]},cut=splitDoorPolygon(poly,r);assert(Math.abs(polygonArea(cut.inside)+cut.outside.reduce((s,p)=>s+polygonArea(p),0)-2)<1e-9);
});
test('door state, occupant count, headlamps, braking and visible damage remain independent per cloned vehicle',async()=>{
 const template=prepareVehicleTemplate((await parsed).scene),car=template.clone(true),other=template.clone(true),detail=bindVehicleDetails(car),unchanged=bindVehicleDetails(other);
 detail.update({speed:0,doorOpen:[1,0,1,.5],occupants:4,headlights:true,braking:true,condition:30},2);unchanged.update({speed:0,doorOpen:0,occupants:0,headlights:false,condition:100},2);
 assert(detail.doors[0].rotation.y>.9);assert.equal(detail.doors[1].rotation.y,0);assert(detail.doors[2].rotation.y>.9);assert(detail.occupants.every(o=>o.visible));
 assert(unchanged.doors.every(o=>o.rotation.y===0));assert(unchanged.occupants.every(o=>!o.visible));
 assert(car.getObjectByName('VehicleHeadlightGlow').visible);assert(car.getObjectByName('VehicleBrakeGlow').visible);assert(car.getObjectByName('VehicleDamage').visible);assert(!other.getObjectByName('VehicleDamage').visible);
 detail.update({speed:12,steering:.2,doorOpen:1,occupants:1,condition:100},2.5);assert(detail.doors.every(o=>o.rotation.y===0));assert.equal(detail.occupants.filter(o=>o.visible).length,1);assert(Math.abs(detail.body.rotation.z)>0);
});
test('cloned police vehicles share prepared geometry while keeping movable hinges independent',async()=>{const template=prepareVehicleTemplate((await parsed).scene),a=template.clone(true),b=template.clone(true);const da=a.getObjectByName('VehicleDoorLF'),db=b.getObjectByName('VehicleDoorLF');assert.notEqual(da,db);assert.equal(da.children[0].geometry,db.children[0].geometry);assert.equal(da.children[0].material,db.children[0].material);});
