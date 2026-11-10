import * as T from "./vendor/engine.js?v=2.18.0";
// Bairro fictício em escala comprimida, construído com geometria própria.
export const URBAN_DISTRICT=Object.freeze({name:"VILA RODOVIA • FICTÍCIA",x:102,z:850,blocks:12});
export function districtPlan(){
 const houses=[];
 for(let row=0;row<3;row++)for(let col=0;col<4;col++)
  houses.push({x:67+col*22+(col>=2?2:0),z:[794,822,878][row],height:3.2+(row+col)%3*1.8});
 return houses;
}
export function urbanVehicles(){
 // Automóveis urbanos estacionados, originais e fora dos cruzamentos.
 return [
  {x:75,z:846,heading:0},{x:125,z:846,heading:Math.PI},
  {x:75,z:904,heading:0},{x:125,z:904,heading:Math.PI},
  {x:94,z:790,heading:Math.PI/2},{x:116,z:914,heading:-Math.PI/2}
 ];
}
export function createUrbanDistrict(scene){
 const root=new T.Group();root.name="Vila Rodovia - bairro estilizado";scene.add(root);
 const material=(c)=>new T.MeshStandardMaterial({color:c,roughness:.92});
 const road=material(0x41484c),sidewalk=material(0x9fa49c),line=material(0xe9dfbd),
 walls=[0xd8c8ac,0x9eaeaa,0xc0b6a8,0xd6c4b9].map(material),roof=material(0x985e4e),
 windows=material(0x35556a),green=material(0x577b45),trunk=material(0x705c45),door=material(0x65534a);
 function box(m,x,y,z,w,h,d){const o=new T.Mesh(new T.BoxGeometry(w,h,d),m);o.position.set(x,y,z);root.add(o);return o;}
 // Rua transversal conecta a rodovia ao bairro sem bloquear a faixa principal.
 box(road,54,.025,850,106,.08,10);
 box(road,102,.028,850,9,.08,164);
 for(const z of [780,808,836,864,892,920])box(road,102,.03,z,94,.08,8);
 for(let x=12;x<153;x+=12)box(line,x,.083,850,3,.025,.11);
 for(let z=774;z<928;z+=12)box(line,102,.09,z,.1,.025,3);
 for(const x of [64,86,108,130,152])for(const z of [788,816,844,872,900,928])
  box(sidewalk,x,.04,z,1.2,.09,18);
 // Frota urbana de baixo custo: geometrias e materiais compartilhados.
 const carBody=new T.BoxGeometry(1.75,.65,3.8);
 const carRoof=new T.BoxGeometry(1.5,.52,1.9);
 const carGlass=new T.BoxGeometry(1.38,.25,1.48);
 const carTire=new T.CylinderGeometry(.36,.36,.2,8);
 const carColors=[0xb4c0c6,0x304f64,0x9b4138,0x60715e].map(material);
 const tireMat=material(0x202529),glassMat=material(0x304650);
 const vehicles=urbanVehicles();
 vehicles.forEach((v,i)=>{
  const car=new T.Group();car.position.set(v.x,.49,v.z);car.rotation.y=v.heading;
  const body=new T.Mesh(carBody,carColors[i%carColors.length]);body.position.y=.4;car.add(body);
  const roofMesh=new T.Mesh(carRoof,carColors[i%carColors.length]);roofMesh.position.set(0,.93,-.25);car.add(roofMesh);
  const glass=new T.Mesh(carGlass,glassMat);glass.position.set(0,1.12,-.25);car.add(glass);
  for(const x of [-.91,.91])for(const z of [-1.15,1.15]){
   const wheel=new T.Mesh(carTire,tireMat);wheel.rotation.z=Math.PI/2;wheel.position.set(x,.28,z);car.add(wheel);
  }
  root.add(car);
 });
 const houses=districtPlan();
 houses.forEach((h,i)=>{
  box(walls[i%walls.length],h.x,h.height/2+.09,h.z,11,h.height,12);
  box(roof,h.x,h.height+.27,h.z,12,.48,13);
  box(windows,h.x-3.1,1.9,h.z+6.05,2,1.2,.08);
  box(windows,h.x+3.1,1.9,h.z+6.05,2,1.2,.08);
  box(door,h.x,1.15,h.z+6.1,1.8,2.3,.11);
 });
 // Pequena praça, vegetação e cruzamentos visíveis sem scripts de tráfego adicionais.
 box(sidewalk,147,.05,919,23,.12,21);
 for(const [x,z] of [[143,912],[152,922],[148,930],[59,777],[155,789]]){
  box(trunk,x,1.3,z,.36,2.6,.36);
  const crown=new T.Mesh(new T.IcosahedronGeometry(2.1,0),green);crown.position.set(x,3.3,z);root.add(crown);
 }
 // Letreiro inteiramente original, sem uso de nomes de cidades reais ou logotipos.
 const canvas=document.createElement("canvas");canvas.width=512;canvas.height=128;
 const ctx=canvas.getContext("2d");ctx.fillStyle="#1b4a55";ctx.fillRect(0,0,512,128);
 ctx.fillStyle="#f2e3b2";ctx.textAlign="center";ctx.font="bold 34px Arial";ctx.fillText("VILA RODOVIA",256,78);
 const tex=new T.CanvasTexture(canvas);tex.colorSpace=T.SRGBColorSpace;
 const sign=new T.Mesh(new T.PlaneGeometry(5.4,1.35),new T.MeshBasicMaterial({map:tex,toneMapped:false}));
 sign.position.set(16,3,845);sign.rotation.y=-Math.PI/2;root.add(sign);
 box(sidewalk,16,1.4,845,.15,2.8,.15);
 return {root,houses:houses.length,urbanVehicles:vehicles.length,drawObjects:root.children.length};
}
