(async()=>{
try{

const THREE=await import("https://esm.sh/three@0.186.0");
const {GLTFLoader}=await import("https://esm.sh/three@0.186.0/examples/jsm/loaders/GLTFLoader.js");
const {DRACOLoader}=await import("https://esm.sh/three@0.186.0/examples/jsm/loaders/DRACOLoader.js");

const $=id=>document.getElementById(id);

const speedText=$("speedText");
const hud=$("hud");
const menu=$("menu");
const startBtn=$("startBtn");
const howBtn=$("howBtn");
const howTo=$("howTo");
const closeHowBtn=$("closeHowBtn");

const mobileControls=$("mobileControls");
const mobileUp=$("mobileUp");
const mobileDown=$("mobileDown");
const mobileLeft=$("mobileLeft");
const mobileRight=$("mobileRight");
const mobileTurbo=$("mobileTurbo");


/* =========================================================
   CENA
========================================================= */

const scene=new THREE.Scene();

scene.background=new THREE.Color(0x01030a);

scene.fog=new THREE.FogExp2(
0x01030a,
0.0012
);

const camera=new THREE.PerspectiveCamera(
85,
innerWidth/innerHeight,
0.01,
7000
);

camera.rotation.order="YXZ";

const renderer=new THREE.WebGLRenderer({
antialias:true,
powerPreference:"high-performance"
});

renderer.setSize(
innerWidth,
innerHeight
);

renderer.setPixelRatio(
Math.min(
devicePixelRatio,
2
)
);

renderer.outputColorSpace=
THREE.SRGBColorSpace;

renderer.toneMapping=
THREE.ACESFilmicToneMapping;

renderer.toneMappingExposure=
1.18;

document.body.prepend(
renderer.domElement
);


/* =========================================================
   CABINE
========================================================= */

const COCKPIT_CAMERA={
x:-0.082,
y:-62.874,
z:27.989,
pitch:0,
yaw:Math.PI,
fov:85
};

const shipRig=
new THREE.Group();

shipRig.rotation.order=
"YXZ";

scene.add(
shipRig
);

camera.position.set(
0,
0,
0
);

camera.rotation.set(
COCKPIT_CAMERA.pitch,
COCKPIT_CAMERA.yaw,
0,
"YXZ"
);

camera.fov=
COCKPIT_CAMERA.fov;

camera.updateProjectionMatrix();

shipRig.add(
camera
);

const world=
new THREE.Group();

scene.add(
world
);


/* =========================================================
   LUZ
========================================================= */

scene.add(
new THREE.HemisphereLight(
0xbadfff,
0x05070c,
1.65
)
);

const cockpitLight=
new THREE.PointLight(
0x40d9ff,
10,
30
);

cockpitLight.position.set(
0,
2,
6
);

shipRig.add(
cockpitLight
);

const warmFill=
new THREE.PointLight(
0xff6a4d,
5,
22
);

warmFill.position.set(
4,
-1,
4
);

shipRig.add(
warmFill
);

const sunLight=
new THREE.DirectionalLight(
0xffffff,
3.2
);

sunLight.position.set(
-10,
14,
-8
);

scene.add(
sunLight
);

const random=(a,b)=>
a+
Math.random()*
(b-a);


/* =========================================================
   MOBILE TOUCH
========================================================= */

const cleanupStyle=
document.createElement(
"style"
);

cleanupStyle.textContent=`

.instructions,
#hudExtra,
#spaceRadar,
#cockpitPanel{
display:none!important;
}

@media
(max-width:900px),
(pointer:coarse){

.mobile-dpad{
display:none!important;
}

#mobileTurbo{
display:flex!important;
}

#touchHint{
display:block;
}

}

#touchHint{
display:none;
position:fixed;
left:50%;
bottom:18px;
transform:translateX(-50%);
z-index:36;
color:rgba(170,240,255,.72);
font:700 10px Arial,sans-serif;
letter-spacing:1.4px;
pointer-events:none;
text-shadow:0 0 8px rgba(50,220,255,.45);
transition:opacity .5s;
}

#touchStick{
display:none;
position:fixed;
width:86px;
height:86px;
border:1px solid rgba(92,230,255,.36);
border-radius:50%;
z-index:36;
pointer-events:none;
transform:translate(-50%,-50%);
background:
radial-gradient(
circle,
rgba(50,210,255,.08),
rgba(0,0,0,0) 70%
);
box-shadow:0 0 18px rgba(40,220,255,.12);
}

#touchStick::after{
content:"";
position:absolute;
width:24px;
height:24px;
border-radius:50%;
left:50%;
top:50%;
transform:translate(-50%,-50%);
border:1px solid rgba(120,240,255,.8);
background:rgba(70,220,255,.20);
box-shadow:0 0 12px rgba(70,220,255,.35);
}

#launchMessage{
position:fixed;
left:50%;
top:23%;
transform:translateX(-50%);
z-index:40;
color:#9cf3ff;
font:700 16px Arial,sans-serif;
letter-spacing:3px;
text-align:center;
text-shadow:0 0 18px rgba(70,220,255,.8);
pointer-events:none;
opacity:0;
transition:opacity .25s;
}
`;

document.head.appendChild(
cleanupStyle
);

const touchHint=
document.createElement(
"div"
);

touchHint.id=
"touchHint";

touchHint.textContent=
"ARRASTE O DEDO PARA PILOTAR";

document.body.appendChild(
touchHint
);

const touchStick=
document.createElement(
"div"
);

touchStick.id=
"touchStick";

document.body.appendChild(
touchStick
);

const launchMessage=
document.createElement(
"div"
);

launchMessage.id=
"launchMessage";

document.body.appendChild(
launchMessage
);


/* =========================================================
   COORDENADAS
========================================================= */

const compass=
document.createElement(
"div"
);

compass.style.cssText=
"position:fixed;right:18px;top:18px;z-index:20;color:#91eaff;font:11px/1.5 Consolas,monospace;text-align:right;pointer-events:none;opacity:0;transition:opacity .7s;text-shadow:0 0 9px rgba(80,220,255,.4)";

document.body.appendChild(
compass
);


/* =========================================================
   ALERTAS
========================================================= */

const warning=
document.createElement(
"div"
);

warning.style.cssText=
"position:fixed;left:50%;top:18%;transform:translateX(-50%);z-index:25;color:#ff5275;font:700 22px Arial,sans-serif;letter-spacing:3px;text-shadow:0 0 15px rgba(255,50,90,.65);opacity:0;transition:opacity .12s;pointer-events:none;text-align:center";

warning.textContent=
"COLISÃO";

document.body.appendChild(
warning
);

const discoveryBanner=
document.createElement(
"div"
);

discoveryBanner.style.cssText=
"position:fixed;left:50%;top:27%;transform:translateX(-50%);z-index:26;color:#8df3ff;font:700 16px Arial,sans-serif;letter-spacing:3px;text-align:center;text-shadow:0 0 16px rgba(64,220,255,.75);opacity:0;transition:opacity .3s;pointer-events:none";

document.body.appendChild(
discoveryBanner
);

const vignette=
document.createElement(
"div"
);

vignette.style.cssText=
"position:fixed;inset:0;z-index:18;pointer-events:none;opacity:0;background:radial-gradient(circle at center,transparent 45%,rgba(255,50,80,.08) 75%,rgba(255,30,60,.28) 100%)";

document.body.appendChild(
vignette
);

const turboFlash=
document.createElement(
"div"
);

turboFlash.style.cssText=
"position:fixed;inset:0;z-index:17;pointer-events:none;opacity:0;background:radial-gradient(circle at center,rgba(90,220,255,.02),rgba(60,170,255,.04) 55%,rgba(30,120,255,.12))";

document.body.appendChild(
turboFlash
);


/* =========================================================
   TELAS DA CABINE
========================================================= */

function makeScreenCanvas(
w=1024,
h=640
){

const canvas=
document.createElement(
"canvas"
);

canvas.width=w;
canvas.height=h;

return{
canvas,
ctx:canvas.getContext("2d")
};

}

const leftScreen=
makeScreenCanvas();

const midScreen=
makeScreenCanvas();

const rightScreen=
makeScreenCanvas();


function makeScreenTexture(
screen
){

const t=
new THREE.CanvasTexture(
screen.canvas
);

t.colorSpace=
THREE.SRGBColorSpace;

t.flipY=false;

t.minFilter=
THREE.LinearFilter;

t.magFilter=
THREE.LinearFilter;

t.generateMipmaps=false;

t.needsUpdate=true;

return t;

}


const leftTexture=
makeScreenTexture(
leftScreen
);

const midTexture=
makeScreenTexture(
midScreen
);

const rightTexture=
makeScreenTexture(
rightScreen
);

let screensReady=false;

let screenBootStart=0;

let screenBootDone=false;

let newTargetPulseUntil=0;

let lastTargetName="";


function applyScreenTexture(
mesh,
texture
){

mesh.material=
new THREE.MeshBasicMaterial({
map:texture,
toneMapped:false,
side:THREE.DoubleSide
});

mesh.material.needsUpdate=
true;

}


function drawScreenFrame(
ctx,
w,
h,
title,
alert=false
){

ctx.clearRect(
0,
0,
w,
h
);

const gradient=
ctx.createLinearGradient(
0,
0,
0,
h
);

gradient.addColorStop(
0,
alert
?
"#20070b"
:
"#02151d"
);

gradient.addColorStop(
1,
"#00070c"
);

ctx.fillStyle=
gradient;

ctx.fillRect(
0,
0,
w,
h
);

ctx.strokeStyle=
alert
?
"rgba(255,70,95,.95)"
:
"rgba(76,231,255,.8)";

ctx.lineWidth=5;

ctx.strokeRect(
8,
8,
w-16,
h-16
);

ctx.fillStyle=
alert
?
"#ff6a82"
:
"#77efff";

ctx.font=
"700 34px Consolas";

ctx.textAlign=
"left";

ctx.fillText(
title,
34,
52
);

ctx.strokeStyle=
alert
?
"rgba(255,70,95,.35)"
:
"rgba(76,231,255,.25)";

ctx.lineWidth=2;

ctx.beginPath();

ctx.moveTo(
30,
72
);

ctx.lineTo(
w-30,
72
);

ctx.stroke();

}


function bar(
ctx,
x,
y,
w,
h,
value,
color="#46efff"
){

ctx.strokeStyle=
"rgba(100,230,255,.35)";

ctx.lineWidth=2;

ctx.strokeRect(
x,
y,
w,
h
);

ctx.fillStyle=
color;

ctx.shadowColor=
color;

ctx.shadowBlur=12;

ctx.fillRect(
x+3,
y+3,
(w-6)*
THREE.MathUtils.clamp(
value/100,
0,
1
),
h-6
);

ctx.shadowBlur=0;

}


/* =========================================================
   BOOT DAS TELAS
========================================================= */

function drawBootScreen(
screen,
texture,
title,
progress
){

const ctx=
screen.ctx;

const w=
screen.canvas.width;

const h=
screen.canvas.height;

ctx.clearRect(
0,
0,
w,
h
);

ctx.fillStyle=
"#00070c";

ctx.fillRect(
0,
0,
w,
h
);

ctx.fillStyle=
"#72efff";

ctx.font=
"700 36px Consolas";

ctx.textAlign=
"center";

ctx.fillText(
"LAST SECOND",
w/2,
h/2-70
);

ctx.font=
"24px Consolas";

ctx.fillStyle=
"rgba(140,240,255,.85)";

ctx.fillText(
title,
w/2,
h/2-20
);

ctx.strokeStyle=
"rgba(100,230,255,.35)";

ctx.strokeRect(
w*0.18,
h/2+20,
w*0.64,
28
);

ctx.fillStyle=
"#55efff";

ctx.fillRect(
w*0.18+3,
h/2+23,
(w*0.64-6)*progress,
22
);

ctx.font=
"20px Consolas";

ctx.fillText(
`${Math.round(progress*100)}%`,
w/2,
h/2+90
);

texture.needsUpdate=
true;

}


/* =========================================================
   ESTRELAS
========================================================= */

const STAR_COUNT=
4200;

const STAR_BOX=
2200;

const HALF_STAR_BOX=
STAR_BOX/2;

const starGeometry=
new THREE.BufferGeometry();

const starPositions=
new Float32Array(
STAR_COUNT*3
);

for(
let i=0;
i<STAR_COUNT;
i++
){

const j=i*3;

starPositions[j]=
random(
-HALF_STAR_BOX,
HALF_STAR_BOX
);

starPositions[j+1]=
random(
-HALF_STAR_BOX,
HALF_STAR_BOX
);

starPositions[j+2]=
random(
-HALF_STAR_BOX,
HALF_STAR_BOX
);

}

starGeometry.setAttribute(
"position",
new THREE.BufferAttribute(
starPositions,
3
)
);

const stars=
new THREE.Points(
starGeometry,
new THREE.PointsMaterial({
color:0xffffff,
size:0.22,
transparent:true,
opacity:0.9,
sizeAttenuation:true
})
);

world.add(
stars
);


function updateInfiniteStars(){

const p=
starGeometry
.attributes
.position
.array;

const sx=
shipRig.position.x;

const sy=
shipRig.position.y;

const sz=
shipRig.position.z;

let changed=false;

for(
let i=0;
i<STAR_COUNT;
i++
){

const j=
i*3;

if(
p[j]-sx>
HALF_STAR_BOX
){

p[j]-=
STAR_BOX;

changed=true;

}

else if(
p[j]-sx<
-HALF_STAR_BOX
){

p[j]+=
STAR_BOX;

changed=true;

}

if(
p[j+1]-sy>
HALF_STAR_BOX
){

p[j+1]-=
STAR_BOX;

changed=true;

}

else if(
p[j+1]-sy<
-HALF_STAR_BOX
){

p[j+1]+=
STAR_BOX;

changed=true;

}

if(
p[j+2]-sz>
HALF_STAR_BOX
){

p[j+2]-=
STAR_BOX;

changed=true;

}

else if(
p[j+2]-sz<
-HALF_STAR_BOX
){

p[j+2]+=
STAR_BOX;

changed=true;

}

}

if(
changed
){

starGeometry
.attributes
.position
.needsUpdate=
true;

}

}


/* =========================================================
   RASTROS TURBO
========================================================= */

const STREAK_COUNT=
360;

const streakGeometry=
new THREE.BufferGeometry();

const streakPositions=
new Float32Array(
STREAK_COUNT*6
);

const streakData=[];

function resetStreak(
i,
first=false
){

streakData[i]={
x:random(-60,60),
y:random(-38,38),

z:random(
first
?
20
:
220,

first
?
260
:
320
)
};

}

for(
let i=0;
i<STREAK_COUNT;
i++
){

resetStreak(
i,
true
);

}

streakGeometry.setAttribute(
"position",
new THREE.BufferAttribute(
streakPositions,
3
)
);

const streakMaterial=
new THREE.LineBasicMaterial({
color:0xa7eeff,
transparent:true,
opacity:0,
blending:THREE.AdditiveBlending,
depthWrite:false
});

const streaks=
new THREE.LineSegments(
streakGeometry,
streakMaterial
);

shipRig.add(
streaks
);


function updateStreaks(
dt,
speedNow
){

const p=
streakGeometry
.attributes
.position
.array;

const factor=
THREE.MathUtils.clamp(
(speedNow-22)/38,
0,
1
);

const length=
2+
factor*
20;

const move=
speedNow*
dt*
(
2.2+
factor*
2.1
);

streakMaterial.opacity+=
(
factor*
0.8
-
streakMaterial.opacity
)
*
Math.min(
1,
dt*7
);

for(
let i=0;
i<STREAK_COUNT;
i++
){

const data=
streakData[i];

data.z-=
move;

if(
data.z<
1
){

resetStreak(
i,
false
);

}

const b=
i*6;

p[b]=data.x;

p[b+1]=data.y;

p[b+2]=data.z;

p[b+3]=data.x;

p[b+4]=data.y;

p[b+5]=
data.z+
length;

}

streakGeometry
.attributes
.position
.needsUpdate=
true;

}


/* =========================================================
   MUNDO
========================================================= */

const planet=
new THREE.Mesh(
new THREE.SphereGeometry(
42,
64,
48
),
new THREE.MeshStandardMaterial({
color:0x284d8c,
roughness:0.78,
metalness:0.06,
emissive:0x07152c,
emissiveIntensity:0.72
})
);

planet.position.set(
-120,
85,
720
);

world.add(
planet
);

const atmosphere=
new THREE.Mesh(
new THREE.SphereGeometry(
45,
64,
48
),
new THREE.MeshBasicMaterial({
color:0x4aa9ff,
transparent:true,
opacity:0.12,
side:THREE.BackSide,
blending:THREE.AdditiveBlending,
depthWrite:false
})
);

atmosphere.position.copy(
planet.position
);

world.add(
atmosphere
);

const planetGlow=
new THREE.PointLight(
0x4e7cff,
120,
450
);

planetGlow.position
.copy(
planet.position
)
.add(
new THREE.Vector3(
30,
20,
-20
)
);

world.add(
planetGlow
);

const moon=
new THREE.Mesh(
new THREE.SphereGeometry(
10,
36,
28
),
new THREE.MeshStandardMaterial({
color:0x8d929c,
roughness:1,
metalness:0
})
);

moon.position.set(
105,
-30,
520
);

world.add(
moon
);


/* =========================================================
   ESTAÇÃO
========================================================= */

const station=
new THREE.Group();

const stationCore=
new THREE.Mesh(
new THREE.CylinderGeometry(
5,
5,
22,
18
),
new THREE.MeshStandardMaterial({
color:0x76808c,
metalness:0.7,
roughness:0.35,
emissive:0x07141c,
emissiveIntensity:0.4
})
);

stationCore.rotation.z=
Math.PI/2;

station.add(
stationCore
);

const stationRing=
new THREE.Mesh(
new THREE.TorusGeometry(
14,
1.4,
12,
36
),
new THREE.MeshStandardMaterial({
color:0x9ab2c6,
metalness:0.72,
roughness:0.28,
emissive:0x0b3145,
emissiveIntensity:0.6
})
);

stationRing.rotation.y=
Math.PI/2;

station.add(
stationRing
);

station.position.set(
280,
35,
900
);

world.add(
station
);


/* =========================================================
   SINAL
========================================================= */

const beacon=
new THREE.Group();

const beaconPole=
new THREE.Mesh(
new THREE.CylinderGeometry(
1.2,
2.2,
18,
12
),
new THREE.MeshStandardMaterial({
color:0x5d6673,
metalness:0.75,
roughness:0.35
})
);

beacon.add(
beaconPole
);

const beaconOrb=
new THREE.Mesh(
new THREE.SphereGeometry(
3.2,
20,
16
),
new THREE.MeshBasicMaterial({
color:0x59eeff,
transparent:true,
opacity:0.9
})
);

beaconOrb.position.y=
11;

beacon.add(
beaconOrb
);

const beaconLight=
new THREE.PointLight(
0x4feaff,
70,
180
);

beaconLight.position.y=
11;

beacon.add(
beaconLight
);

beacon.position.set(
-480,
110,
1250
);

world.add(
beacon
);


/* =========================================================
   DESTROÇOS
========================================================= */

const wreck=
new THREE.Group();

const wreckMat=
new THREE.MeshStandardMaterial({
color:0x494f59,
metalness:0.7,
roughness:0.5,
emissive:0x130506,
emissiveIntensity:0.35
});

for(
let i=0;
i<9;
i++
){

const part=
new THREE.Mesh(
new THREE.BoxGeometry(
random(2,8),
random(1,4),
random(2,10)
),
wreckMat
);

part.position.set(
random(-16,16),
random(-10,10),
random(-14,14)
);

part.rotation.set(
random(0,Math.PI),
random(0,Math.PI),
random(0,Math.PI)
);

wreck.add(
part
);

}

wreck.position.set(
560,
-90,
1480
);

world.add(
wreck
);


/* =========================================================
   HANGAR DE DECOLAGEM — v1.9
========================================================= */

const hangar=
new THREE.Group();

world.add(
hangar
);

const hangarMetal=
new THREE.MeshStandardMaterial({
color:0x27313b,
metalness:0.72,
roughness:0.42,
emissive:0x03080c,
emissiveIntensity:0.35
});

const hangarDark=
new THREE.MeshStandardMaterial({
color:0x111820,
metalness:0.8,
roughness:0.35
});

const hangarGlow=
new THREE.MeshBasicMaterial({
color:0x54e8ff,
toneMapped:false
});

const hangarWarn=
new THREE.MeshBasicMaterial({
color:0xff9b3d,
toneMapped:false
});


function hangarBox(
x,
y,
z,
sx,
sy,
sz,
material=hangarMetal
){

const mesh=
new THREE.Mesh(
new THREE.BoxGeometry(
sx,
sy,
sz
),
material
);

mesh.position.set(
x,
y,
z
);

hangar.add(
mesh
);

return mesh;

}


/* PISO / TETO / PAREDES */

hangarBox(
0,
-5.8,
45,
34,
1.2,
120
);

hangarBox(
0,
12.5,
45,
34,
1,
120
);

hangarBox(
-17,
3.2,
45,
1.2,
18,
120
);

hangarBox(
17,
3.2,
45,
1.2,
18,
120
);

hangarBox(
0,
3.2,
-15,
34,
18,
1.2,
hangarDark
);


/* VIGAS */

for(
let z=-8;
z<=92;
z+=20
){

hangarBox(
-15.7,
3.2,
z,
1.1,
17,
1.5,
hangarDark
);

hangarBox(
15.7,
3.2,
z,
1.1,
17,
1.5,
hangarDark
);

hangarBox(
0,
11.4,
z,
31,
1.1,
1.5,
hangarDark
);

}


/* LUZES DE PISTA */

for(
let z=-5;
z<=90;
z+=8
){

hangarBox(
-7,
-5.05,
z,
1.1,
.12,
2.8,
hangarGlow
);

hangarBox(
7,
-5.05,
z,
1.1,
.12,
2.8,
hangarGlow
);

}


/* FAIXAS CENTRAIS */

for(
let z=-3;
z<=82;
z+=10
){

hangarBox(
0,
-5.03,
z,
.35,
.08,
4.5,
hangarWarn
);

}


/* PORTÃO */

const gateLeft=
hangarBox(
-8.5,
3.1,
96,
16.5,
17,
1.5,
hangarDark
);

const gateRight=
hangarBox(
8.5,
3.1,
96,
16.5,
17,
1.5,
hangarDark
);


/* MOLDURA DA SAÍDA */

hangarBox(
-17,
3.2,
96,
1.5,
19,
3,
hangarMetal
);

hangarBox(
17,
3.2,
96,
1.5,
19,
3,
hangarMetal
);

hangarBox(
0,
12.3,
96,
34,
1.5,
3,
hangarMetal
);


/* ILUMINAÇÃO DO HANGAR */

for(
const x
of
[-11,11]
){

for(
const z
of
[5,35,65,88]
){

const light=
new THREE.PointLight(
0x4adfff,
18,
32,
2
);

light.position.set(
x,
8,
z
);

hangar.add(
light
);

}

}

const rearLight=
new THREE.PointLight(
0xff8b45,
20,
35,
2
);

rearLight.position.set(
0,
4,
-8
);

hangar.add(
rearLight
);


/* =========================================================
   CARREGA COCKPIT
========================================================= */

const dracoLoader=
new DRACOLoader();

dracoLoader.setDecoderPath(
"https://www.gstatic.com/draco/versioned/decoders/1.5.7/"
);

const loader=
new GLTFLoader();

loader.setDRACOLoader(
dracoLoader
);

loader.load(
"./models/cockpit_scifi.glb",

gltf=>{

const cockpit=
gltf.scene;

cockpit.traverse(
child=>{

if(
!child.isMesh
){

return;

}

if(
child.name.includes(
"ScreenLeft"
)
){

applyScreenTexture(
child,
leftTexture
);

}

else if(
child.name.includes(
"ScreenMid"
)
){

applyScreenTexture(
child,
midTexture
);

}

else if(
child.name.includes(
"ScreenRight"
)
){

applyScreenTexture(
child,
rightTexture
);

}

else{

const materials=
Array.isArray(
child.material
)
?
child.material
:
[
child.material
];

materials.forEach(
material=>{

if(
material
){

material.needsUpdate=
true;

}

});

}

});

const box=
new THREE.Box3()
.setFromObject(
cockpit
);

const size=
new THREE.Vector3();

const center=
new THREE.Vector3();

box.getSize(
size
);

box.getCenter(
center
);

cockpit.position.sub(
center
);

cockpit.scale.setScalar(
12/
(
Math.max(
size.x,
size.y,
size.z
)
||
1
)
);

cockpit.position.x-=
COCKPIT_CAMERA.x;

cockpit.position.y-=
COCKPIT_CAMERA.y;

cockpit.position.z-=
COCKPIT_CAMERA.z;

shipRig.add(
cockpit
);

screensReady=true;

screenBootStart=
performance.now();

},

undefined,

error=>{

console.error(
"Erro cockpit:",
error
);

}

);


/* =========================================================
   ASTEROIDES
========================================================= */

function createAsteroidGeometry(
seed=0
){

const geometry=
new THREE.IcosahedronGeometry(
1,
2
);

const position=
geometry
.attributes
.position;

const vector=
new THREE.Vector3();

for(
let i=0;
i<position.count;
i++
){

vector.fromBufferAttribute(
position,
i
);

const wobble=
0.78
+
Math.sin(
i*12.9898+
seed*9.7
)
*
0.12
+
Math.cos(
i*4.123+
seed*5.1
)
*
0.08
+
Math.random()*
0.08;

vector.multiplyScalar(
wobble
);

position.setXYZ(
i,
vector.x,
vector.y,
vector.z
);

}

position.needsUpdate=
true;

geometry.computeVertexNormals();

return geometry;

}


const asteroidGeometries=
[
1,
2,
3,
4
]
.map(
createAsteroidGeometry
);

const asteroids=[];


function makeAsteroidMaterial(){

const color=
new THREE.Color(
0x77716b
);

color.offsetHSL(
random(-0.03,0.03),
random(-0.04,0.04),
random(-0.10,0.08)
);

return new THREE.MeshStandardMaterial({
color,
roughness:0.96,
metalness:0.02
});

}


function setAsteroidScale(
asteroid
){

const scale=
random(
1.2,
5.3
);

asteroid.scale.set(
scale*
random(
0.86,
1.18
),

scale*
random(
0.84,
1.16
),

scale*
random(
0.86,
1.2
)
);

asteroid.userData.radius=
scale*
0.9;

asteroid.userData.spinX=
random(
-0.65,
0.65
);

asteroid.userData.spinY=
random(
-0.65,
0.65
);

asteroid.userData.spinZ=
random(
-0.65,
0.65
);

asteroid.userData.near=
false;

}


function placeBeltAsteroid(
asteroid
){

const angle=
random(
0,
Math.PI*2
);

const radius=
random(
85,
220
);

asteroid.position.set(
planet.position.x+
Math.cos(
angle
)*
radius,

planet.position.y+
random(
-48,
48
),

planet.position.z+
Math.sin(
angle
)*
radius
);

setAsteroidScale(
asteroid
);

}


function placeRoamingAsteroid(
asteroid,
first=false
){

const forward=
new THREE.Vector3(
0,
0,
1
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();

const right=
new THREE.Vector3(
1,
0,
0
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();

const up=
new THREE.Vector3(
0,
1,
0
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();

const ahead=
first
?
random(
100,
720
)
:
random(
260,
850
);

asteroid.position
.copy(
shipRig.position
)
.addScaledVector(
forward,
ahead
)
.addScaledVector(
right,
random(
-320,
320
)
)
.addScaledVector(
up,
random(
-170,
170
)
);

setAsteroidScale(
asteroid
);

}


for(
let i=0;
i<110;
i++
){

const asteroid=
new THREE.Mesh(

asteroidGeometries[
i%
asteroidGeometries.length
],

makeAsteroidMaterial()

);

asteroid.userData.fixedBelt=
i<
40;

if(
asteroid.userData.fixedBelt
){

placeBeltAsteroid(
asteroid
);

}

else{

placeRoamingAsteroid(
asteroid,
true
);

}

asteroids.push(
asteroid
);

world.add(
asteroid
);

}


/* =========================================================
   MARCADORES
========================================================= */

const poiLayer=
document.createElement(
"div"
);

poiLayer.style.cssText=
"position:fixed;inset:0;z-index:21;pointer-events:none;overflow:hidden";

document.body.appendChild(
poiLayer
);


function makeMarker(
label
){

const el=
document.createElement(
"div"
);

el.style.cssText=
"position:absolute;transform:translate(-50%,-50%);color:#9ceeff;font:700 10px/1.3 Arial,sans-serif;letter-spacing:1px;text-align:center;text-shadow:0 0 9px rgba(62,220,255,.8);opacity:0;white-space:nowrap";

el.innerHTML=
`<div style="width:12px;height:12px;border:1px solid rgba(120,235,255,.9);transform:rotate(45deg);margin:0 auto 5px"></div>
<span>${label}</span>
<div class="poi-distance"></div>`;

poiLayer.appendChild(
el
);

return el;

}


const POIS=[

{
name:"LUA NEREID",
short:"LUA",
object:moon,
discoverRadius:55,
score:150,
discovered:false,
marker:makeMarker(
"LUA NEREID"
)
},

{
name:"PLANETA AURORA",
short:"PLANETA",
object:planet,
discoverRadius:90,
score:250,
discovered:false,
marker:makeMarker(
"PLANETA AURORA"
)
},

{
name:"ESTAÇÃO ORBITAL",
short:"ESTAÇÃO",
object:station,
discoverRadius:55,
score:300,
discovered:false,
marker:makeMarker(
"ESTAÇÃO ORBITAL"
)
},

{
name:"SINAL DESCONHECIDO",
short:"SINAL",
object:beacon,
discoverRadius:45,
score:350,
discovered:false,
marker:makeMarker(
"SINAL DESCONHECIDO"
)
},

{
name:"DESTROÇOS K-17",
short:"K-17",
object:wreck,
discoverRadius:55,
score:400,
discovered:false,
marker:makeMarker(
"DESTROÇOS K-17"
)
}

];


/* =========================================================
   ESTADO
========================================================= */

const keys=
new Set();

let speed=22;

let turbo=false;

let health=100;

let score=0;

let gameStarted=false;

let gameOver=false;

let lastHitTime=-9999;

let shake=0;

let impactFlash=0;

let yaw=0;

let pitch=0;

let roll=0;

let yawVelocity=0;

let pitchVelocity=0;

let distanceTravelled=0;

let launchState=
"waiting";

let launchStartTime=0;

let manualControl=false;

let launchMessageLast="";

const forwardVector=
new THREE.Vector3();


function currentSector(){

const size=
1000;

const sx=
Math.floor(
shipRig.position.x/
size
);

const sz=
Math.floor(
shipRig.position.z/
size
);

return `S-${
sx>=0
?
"+"
:
""
}${sx}:${
sz>=0
?
"+"
:
""
}${sz}`;

}


function getNearestPoi(){

let nearest=null;

let distance=
Infinity;

const position=
new THREE.Vector3();

for(
const poi
of POIS
){

if(
poi.discovered
){

continue;

}

poi.object.getWorldPosition(
position
);

const d=
position.distanceTo(
shipRig.position
);

if(
d<
distance
){

distance=d;

nearest=poi;

}

}

return{
poi:nearest,
distance
};

}


function getRadarRange(){

const d=
getNearestPoi()
.distance;

if(
d<
300
){

return 350;

}

if(
d<
650
){

return 700;

}

if(
d<
1200
){

return 1300;

}

return 2200;

}


/* =========================================================
   DESCOBERTA
========================================================= */

function flashDiscovery(
name,
bonus
){

discoveryBanner.innerHTML=
`LOCAL DESCOBERTO

<br>

<span
style="
font-size:12px;
color:white;
"
>

${name}

+${bonus}

</span>`;

discoveryBanner.style.opacity=
"1";

clearTimeout(
flashDiscovery.timer
);

flashDiscovery.timer=
setTimeout(
()=>{

discoveryBanner.style.opacity=
"0";

},
2200
);

newTargetPulseUntil=
performance.now()+
2200;

}


/* =========================================================
   MARCADORES
========================================================= */

function updatePoiMarkers(){

const worldPos=
new THREE.Vector3();

for(
const poi
of POIS
){

poi.object.getWorldPosition(
worldPos
);

const distance=
worldPos.distanceTo(
shipRig.position
);

if(
!poi.discovered
&&
distance<=
poi.discoverRadius
){

poi.discovered=
true;

score+=
poi.score;

flashDiscovery(
poi.name,
poi.score
);

}

const projected=
worldPos
.clone()
.project(
camera
);

const visible=
projected.z>
-1
&&
projected.z<
1
&&
distance<
1800
&&
gameStarted
&&
!gameOver;

if(
visible
){

const x=
(
projected.x*
0.5+
0.5
)
*
innerWidth;

const y=
(
-projected.y*
0.5+
0.5
)
*
innerHeight;

if(
x>
40
&&
x<
innerWidth-
40
&&
y>
40
&&
y<
innerHeight-
40
){

poi.marker.style.left=
`${x}px`;

poi.marker.style.top=
`${y}px`;

poi.marker.style.opacity=
poi.discovered
?
"0.24"
:
"0.85";

poi.marker
.querySelector(
".poi-distance"
)
.textContent=
`${Math.round(
distance
)} u${
poi.discovered
?
" • DESCOBERTO"
:
""
}`;

}

else{

poi.marker.style.opacity=
"0";

}

}

else{

poi.marker.style.opacity=
"0";

}

}

}


/* =========================================================
   RADAR
========================================================= */

const radarTemp=
new THREE.Vector3();

const poiPos=
new THREE.Vector3();

const radarQuaternion=
new THREE.Quaternion();

const radarAxisY=
new THREE.Vector3(
0,
1,
0
);


/* =========================================================
   TELA ESQUERDA
========================================================= */

function drawLeftScreen(){

const ctx=
leftScreen.ctx;

const w=
leftScreen.canvas.width;

const h=
leftScreen.canvas.height;

drawScreenFrame(
ctx,
w,
h,
"LAST SECOND // NAV",
health<=40
);

const nearest=
getNearestPoi();

const discovered=
POIS.filter(
p=>
p.discovered
).length;

const target=
nearest.poi
?
nearest.poi.name
:
"EXPLORAÇÃO COMPLETA";

const distance=
nearest.poi
?
`${Math.round(
nearest.distance
)} U`
:
"---";

const healthColor=
health>
40
?
"#5ff7ff"
:
"#ff5d78";

ctx.font=
"28px Consolas";

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"SETOR",
36,
118
);

ctx.fillStyle=
"#fff";

ctx.fillText(
currentSector(),
220,
118
);

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"MISSÃO ATUAL",
36,
172
);

ctx.fillStyle=
"#fff";

ctx.font=
"700 29px Consolas";

ctx.fillText(
target,
36,
208
);

ctx.font=
"28px Consolas";

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"DISTÂNCIA",
36,
270
);

ctx.fillStyle=
"#fff";

ctx.fillText(
distance,
245,
270
);

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"VELOCIDADE",
36,
326
);

ctx.fillStyle=
"#fff";

ctx.fillText(
`${Math.round(
speed
)}${
turbo
?
"  TURBO"
:
""
}`,
245,
326
);

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"INTEGRIDADE",
36,
382
);

ctx.fillStyle=
healthColor;

ctx.font=
"700 30px Consolas";

ctx.fillText(
`${health}%`,
245,
382
);

ctx.font=
"26px Consolas";

ctx.fillStyle=
"#67dff0";

ctx.fillText(
"LOCAIS",
36,
438
);

ctx.fillStyle=
"#fff";

ctx.fillText(
`${discovered}/${POIS.length}`,
245,
438
);

ctx.fillStyle=
gameOver
?
"#ff5d78"
:
health<=40
?
"#ff5d78"
:
"#4dff9b";

ctx.font=
"700 26px Consolas";

ctx.fillText(
gameOver
?
"STATUS: CRÍTICO"
:
health<=40
?
"STATUS: ALERTA"
:
"STATUS: NOMINAL",
36,
505
);

leftTexture.needsUpdate=
true;

}


/* =========================================================
   TELA CENTRAL
========================================================= */

function drawMidScreen(
now
){

const ctx=
midScreen.ctx;

const w=
midScreen.canvas.width;

const h=
midScreen.canvas.height;

drawScreenFrame(
ctx,
w,
h,
"NAVEGAÇÃO",
health<=20
);

const cx=
w/2;

const cy=
h/2+
18;

const radius=
Math.min(
w,
h
)
*
0.34;

const range=
getRadarRange();

ctx.strokeStyle=
"rgba(70,230,250,.22)";

ctx.lineWidth=
3;

for(
let i=1;
i<=4;
i++
){

ctx.beginPath();

ctx.arc(
cx,
cy,
radius*
i/
4,
0,
Math.PI*
2
);

ctx.stroke();

}

ctx.beginPath();

ctx.moveTo(
cx-radius,
cy
);

ctx.lineTo(
cx+radius,
cy
);

ctx.moveTo(
cx,
cy-radius
);

ctx.lineTo(
cx,
cy+radius
);

ctx.stroke();

ctx.fillStyle=
"#83efff";

ctx.font=
"24px Consolas";

ctx.textAlign=
"center";

ctx.fillText(
"N",
cx,
cy-radius-
12
);

ctx.fillText(
"S",
cx,
cy+radius+
30
);

ctx.fillText(
"W",
cx-radius-
28,
cy+
8
);

ctx.fillText(
"E",
cx+radius+
28,
cy+
8
);

radarQuaternion.setFromAxisAngle(
radarAxisY,
-yaw
);


/* ASTEROIDES */

for(
const asteroid
of asteroids
){

const distance=
asteroid.position.distanceTo(
shipRig.position
);

if(
distance>
range
){

continue;

}

radarTemp
.copy(
asteroid.position
)
.sub(
shipRig.position
)
.applyQuaternion(
radarQuaternion
);

const px=
cx+
(
radarTemp.x/
range
)
*
radius;

const py=
cy-
(
radarTemp.z/
range
)
*
radius;

const dx=
px-
cx;

const dy=
py-
cy;

if(
dx*
dx
+
dy*
dy
>
radius*
radius
){

continue;

}

ctx.beginPath();

ctx.arc(
px,
py,
4,
0,
Math.PI*
2
);

ctx.fillStyle=
"rgba(255,170,80,.8)";

ctx.fill();

}


/* OBJETIVO */

const nearest=
getNearestPoi();

if(
nearest.poi
&&
nearest.poi.name!==
lastTargetName
){

lastTargetName=
nearest.poi.name;

newTargetPulseUntil=
now+
1800;

}


/* LOCAIS */

for(
const poi
of POIS
){

poi.object.getWorldPosition(
poiPos
);

radarTemp
.copy(
poiPos
)
.sub(
shipRig.position
)
.applyQuaternion(
radarQuaternion
);

let px=
cx+
(
radarTemp.x/
range
)
*
radius;

let py=
cy-
(
radarTemp.z/
range
)
*
radius;

const dx=
px-
cx;

const dy=
py-
cy;

const markerDistance=
Math.sqrt(
dx*
dx
+
dy*
dy
);

if(
markerDistance>
radius*
0.88
){

const angle=
Math.atan2(
dy,
dx
);

px=
cx+
Math.cos(
angle
)
*
radius*
0.88;

py=
cy+
Math.sin(
angle
)
*
radius*
0.88;

}

const pulse=
(
!poi.discovered
&&
poi===
nearest.poi
&&
now<
newTargetPulseUntil
)
?
1+
Math.sin(
now*
0.012
)
*
0.45
:
1;

ctx.save();

ctx.translate(
px,
py
);

ctx.rotate(
Math.PI/
4
);

ctx.fillStyle=
poi.discovered
?
"rgba(90,170,185,.5)"
:
"#49efff";

ctx.shadowColor=
poi.discovered
?
"transparent"
:
"#49efff";

ctx.shadowBlur=
poi.discovered
?
0
:
12;

ctx.fillRect(
-7*
pulse,
-7*
pulse,
14*
pulse,
14*
pulse
);

ctx.restore();

}


/* NAVE */

ctx.save();

ctx.translate(
cx,
cy
);

ctx.beginPath();

ctx.moveTo(
0,
-20
);

ctx.lineTo(
-12,
14
);

ctx.lineTo(
0,
8
);

ctx.lineTo(
12,
14
);

ctx.closePath();

ctx.fillStyle=
"#fff";

ctx.shadowColor=
"#53eaff";

ctx.shadowBlur=
18;

ctx.fill();

ctx.restore();

ctx.fillStyle=
"#78eaff";

ctx.font=
"22px Consolas";

ctx.textAlign=
"center";

ctx.fillText(
`ALCANCE ${range}U`,
cx,
h-
26
);

if(
nearest.poi
){

ctx.fillStyle=
now<
newTargetPulseUntil
?
"#fff"
:
"#76efff";

ctx.font=
"700 20px Consolas";

ctx.fillText(
`ALVO: ${nearest.poi.short}`,
cx,
104
);

}

midTexture.needsUpdate=
true;

}


/* =========================================================
   TELA DIREITA
========================================================= */

function drawRightScreen(){

const ctx=
rightScreen.ctx;

const w=
rightScreen.canvas.width;

const h=
rightScreen.canvas.height;

drawScreenFrame(
ctx,
w,
h,
"SISTEMAS",
health<=40
);

const energy=
turbo
?
78
:
100;

const propulsion=
turbo
?
100
:
64;

const rows=[
[
"PROPULSÃO",
propulsion,
"#46efff"
],

[
"ENERGIA",
energy,
"#46efff"
],

[
"INTEGRIDADE",
health,
health>
40
?
"#46efff"
:
"#ff5d78"
],

[
"NAVEGAÇÃO",
100,
"#46efff"
]
];

let y=
125;

for(
const [
name,
value,
color
]
of rows
){

ctx.fillStyle=
"#75eafa";

ctx.font=
"25px Consolas";

ctx.textAlign=
"left";

ctx.fillText(
name,
38,
y
);

ctx.fillStyle=
"#fff";

ctx.textAlign=
"right";

ctx.fillText(
`${value}%`,
w-
40,
y
);

bar(
ctx,
38,
y+
14,
w-
76,
22,
value,
color
);

y+=
82;

}

ctx.textAlign=
"left";

ctx.font=
"24px Consolas";

const statusY=
470;

ctx.fillStyle=
"#75eafa";

ctx.fillText(
"COMUNICAÇÃO",
38,
statusY
);

ctx.fillText(
"SUPORTE DE VIDA",
38,
statusY+
40
);

ctx.fillText(
"RADAR",
38,
statusY+
80
);

ctx.fillStyle=
"#4dff9b";

ctx.textAlign=
"right";

ctx.fillText(
"ONLINE",
w-
40,
statusY
);

ctx.fillText(
"ONLINE",
w-
40,
statusY+
40
);

ctx.fillText(
"ONLINE",
w-
40,
statusY+
80
);

ctx.textAlign=
"left";

ctx.font=
"700 27px Consolas";

ctx.fillStyle=
turbo
?
"#ffd45a"
:
health<=40
?
"#ff5d78"
:
"#73efff";

ctx.fillText(
turbo
?
"⚡ TURBO ATIVO"
:
health<=40
?
"⚠ HULL DAMAGE"
:
"PROPULSÃO NORMAL",
38,
h-
28
);

rightTexture.needsUpdate=
true;

}


/* =========================================================
   ATUALIZA TELAS
========================================================= */

function updateRealCockpitScreens(
now
){

if(
!screensReady
){

return;

}

if(
!screenBootDone
){

const progress=
THREE.MathUtils.clamp(
(
now-
screenBootStart
)
/
1800,
0,
1
);

drawBootScreen(
leftScreen,
leftTexture,
"NAV SYSTEM",
progress
);

drawBootScreen(
midScreen,
midTexture,
"RADAR LINK",
progress
);

drawBootScreen(
rightScreen,
rightTexture,
"SYSTEM CHECK",
progress
);

if(
progress>=
1
){

screenBootDone=
true;

}

return;

}

drawLeftScreen();

drawMidScreen(
now
);

drawRightScreen();

}


/* =========================================================
   TOUCH STEERING
========================================================= */

let touchPointerId=
null;

let touchStartX=0;

let touchStartY=0;

let touchSteerX=0;

let touchSteerY=0;

let isTouchSteering=false;

const isCoarse=()=>
window.matchMedia(
"(pointer:coarse)"
).matches;


function steeringStart(
event
){

if(
!gameStarted
||
!manualControl
||
gameOver
||
!isCoarse()
||
event.pointerType===
"mouse"
){

return;

}

if(
event.target===
mobileTurbo
||
mobileTurbo?.contains(
event.target
)
){

return;

}

touchPointerId=
event.pointerId;

touchStartX=
event.clientX;

touchStartY=
event.clientY;

touchSteerX=0;

touchSteerY=0;

isTouchSteering=true;

try{

renderer.domElement
.setPointerCapture(
event.pointerId
);

}
catch{}

touchStick.style.display=
"block";

touchStick.style.left=
`${touchStartX}px`;

touchStick.style.top=
`${touchStartY}px`;

touchHint.style.opacity=
"0";

event.preventDefault();

}


function steeringMove(
event
){

if(
!isTouchSteering
||
event.pointerId!==
touchPointerId
){

return;

}

const range=
85;

touchSteerX=
THREE.MathUtils.clamp(
(
event.clientX-
touchStartX
)
/
range,
-1,
1
);

touchSteerY=
THREE.MathUtils.clamp(
(
event.clientY-
touchStartY
)
/
range,
-1,
1
);

touchStick.style.transform=
`translate(-50%,-50%)
translate(
${touchSteerX*25}px,
${touchSteerY*25}px
)`;

event.preventDefault();

}


function steeringEnd(
event
){

if(
event.pointerId!==
touchPointerId
){

return;

}

touchPointerId=
null;

touchSteerX=0;

touchSteerY=0;

isTouchSteering=false;

touchStick.style.display=
"none";

touchStick.style.transform=
"translate(-50%,-50%)";

}


renderer.domElement.addEventListener(
"pointerdown",
steeringStart,
{
passive:false
}
);

renderer.domElement.addEventListener(
"pointermove",
steeringMove,
{
passive:false
}
);

renderer.domElement.addEventListener(
"pointerup",
steeringEnd,
{
passive:false
}
);

renderer.domElement.addEventListener(
"pointercancel",
steeringEnd,
{
passive:false
}
);

renderer.domElement.addEventListener(
"lostpointercapture",
steeringEnd,
{
passive:false
}
);


/* =========================================================
   TURBO MOBILE
========================================================= */

function bindMobileButton(
element,
keyCode
){

if(
!element
){

return;

}

function press(
event
){

event.preventDefault();

event.stopPropagation();

if(
!gameStarted
||
!manualControl
||
gameOver
){

return;

}

try{

element.setPointerCapture?.(
event.pointerId
);

}
catch{}

keys.add(
keyCode
);

element.classList.add(
"pressed"
);

}


function release(
event
){

if(
event
){

event.preventDefault();

event.stopPropagation();

}

keys.delete(
keyCode
);

element.classList.remove(
"pressed"
);

}


element.addEventListener(
"pointerdown",
press,
{
passive:false
}
);

element.addEventListener(
"pointerup",
release,
{
passive:false
}
);

element.addEventListener(
"pointercancel",
release,
{
passive:false
}
);

element.addEventListener(
"lostpointercapture",
release,
{
passive:false
}
);

}


/* COMPATIBILIDADE */

bindMobileButton(
mobileUp,
"ArrowUp"
);

bindMobileButton(
mobileDown,
"ArrowDown"
);

bindMobileButton(
mobileLeft,
"ArrowLeft"
);

bindMobileButton(
mobileRight,
"ArrowRight"
);

bindMobileButton(
mobileTurbo,
"ShiftLeft"
);


/* =========================================================
   SEQUÊNCIA DE DECOLAGEM
========================================================= */

function setLaunchMessage(
text,
visible=true
){

if(
text!==
launchMessageLast
){

launchMessage.textContent=
text;

launchMessageLast=
text;

}

launchMessage.style.opacity=
visible
?
"1"
:
"0";

}


function beginLaunch(){

launchState=
"launching";

manualControl=
false;

launchStartTime=
performance.now();

speed=0;

turbo=false;

yaw=0;

pitch=0;

roll=0;

yawVelocity=0;

pitchVelocity=0;

shipRig.position.set(
0,
0,
0
);

shipRig.rotation.set(
0,
0,
0
);

gateLeft.position.x=
-8.5;

gateRight.position.x=
8.5;

keys.clear();

screenBootDone=
false;

screenBootStart=
performance.now();

setLaunchMessage(
"INICIALIZANDO SISTEMAS"
);

}


function updateLaunchSequence(
now,
dt
){

if(
launchState!==
"launching"
){

return;

}

const t=
(
now-
launchStartTime
)
/
1000;


/* 0–2 SEGUNDOS */

if(
t<
2
){

speed=0;

setLaunchMessage(
"INICIALIZANDO SISTEMAS"
);

}


/* 2–4 SEGUNDOS */

else if(
t<
4
){

speed=0;

setLaunchMessage(
"LIBERAÇÃO DE VOO"
);

}


/* 4–6.2 ABERTURA DO PORTÃO */

else if(
t<
6.2
){

const p=
THREE.MathUtils.smoothstep(
(
t-
4
)
/
2.2,
0,
1
);

gateLeft.position.x=
THREE.MathUtils.lerp(
-8.5,
-25,
p
);

gateRight.position.x=
THREE.MathUtils.lerp(
8.5,
25,
p
);

speed=0;

setLaunchMessage(
"DECOLAGEM AUTORIZADA"
);

}


/* SAÍDA AUTOMÁTICA */

else if(
t<
11.5
){

gateLeft.position.x=
-25;

gateRight.position.x=
25;

const p=
THREE.MathUtils.clamp(
(
t-
6.2
)
/
5.3,
0,
1
);

speed=
THREE.MathUtils.lerp(
4,
28,
p
);

forwardVector.set(
0,
0,
1
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();

shipRig.position
.addScaledVector(
forwardVector,
speed*
dt
);

distanceTravelled+=
speed*
dt;

setLaunchMessage(
t<
8.2
?
"PROPULSORES ATIVOS"
:
"SAINDO DO HANGAR"
);

}


/* CONTROLE DO JOGADOR */

else{

launchState=
"complete";

manualControl=
true;

speed=
22;

setLaunchMessage(
"CONTROLE MANUAL LIBERADO"
);

setTimeout(
()=>{

setLaunchMessage(
"",
false
);

},
1800
);

if(
isCoarse()
){

touchHint.style.display=
"block";

touchHint.style.opacity=
"1";

setTimeout(
()=>{

touchHint.style.opacity=
"0";

},
2800
);

}

}

}


/* =========================================================
   MENU
========================================================= */

startBtn.addEventListener(
"click",
()=>{

gameStarted=
true;

beginLaunch();

menu.classList.add(
"hide"
);

hud.classList.add(
"show"
);

compass.style.opacity=
"1";

if(
mobileControls
){

mobileControls
.classList
.add(
"show"
);

}

if(
isCoarse()
&&
manualControl
){

touchHint.style.display=
"block";

touchHint.style.opacity=
"1";

setTimeout(
()=>{

touchHint.style.opacity=
"0";

},
3200
);

}

keys.clear();

}
);


howBtn.addEventListener(
"click",
()=>{

howTo.classList.add(
"show"
);

}
);


closeHowBtn.addEventListener(
"click",
()=>{

howTo.classList.remove(
"show"
);

}
);


howTo.addEventListener(
"click",
event=>{

if(
event.target===
howTo
){

howTo.classList.remove(
"show"
);

}

}
);


/* =========================================================
   TECLADO
========================================================= */

window.addEventListener(
"keydown",
event=>{

if(
!gameStarted
){

return;

}

if(
!manualControl
&&
!gameOver
){

return;

}

keys.add(
event.code
);

if(
event.code.startsWith(
"Arrow"
)
){

event.preventDefault();

}

if(
event.code===
"KeyR"
&&
gameOver
){

resetGame();

}

}
);


window.addEventListener(
"keyup",
event=>{

keys.delete(
event.code
);

}
);


window.addEventListener(
"blur",
()=>{

keys.clear();

touchSteerX=0;

touchSteerY=0;

isTouchSteering=false;

touchStick.style.display=
"none";

}
);


/* =========================================================
   RESET
========================================================= */

function resetGame(){

health=100;

score=0;

speed=22;

yaw=0;

pitch=0;

roll=0;

yawVelocity=0;

pitchVelocity=0;

distanceTravelled=0;

gameOver=false;

launchState=
"waiting";

manualControl=
false;

gateLeft.position.x=
-8.5;

gateRight.position.x=
8.5;

setLaunchMessage(
"",
false
);

shipRig.position.set(
0,
0,
0
);

shipRig.rotation.set(
0,
0,
0
);

warning.textContent=
"COLISÃO";

warning.style.opacity=
"0";

keys.clear();

POIS.forEach(
poi=>{

poi.discovered=
false;

}
);

lastTargetName="";

newTargetPulseUntil=0;

}


/* =========================================================
   COLISÃO
========================================================= */

function hitPlayer(){

const now=
performance.now();

if(
now-
lastHitTime<
700
||
gameOver
){

return;

}

lastHitTime=
now;

health=
Math.max(
0,
health-
20
);

shake=
0.5;

impactFlash=
1;

warning.style.opacity=
"1";

setTimeout(
()=>{

if(
!gameOver
){

warning.style.opacity=
"0";

}

},
180
);

if(
health<=
0
){

gameOver=true;

speed=0;

keys.clear();

warning.textContent=
"SISTEMA CRÍTICO — R PARA REINICIAR";

warning.style.opacity=
"1";

}

}


/* =========================================================
   ASTEROIDES
========================================================= */

function updateAsteroids(
dt
){

for(
const asteroid
of asteroids
){

asteroid.rotation.x+=
asteroid.userData.spinX*
dt;

asteroid.rotation.y+=
asteroid.userData.spinY*
dt;

asteroid.rotation.z+=
asteroid.userData.spinZ*
dt;

const distance=
asteroid.position.distanceTo(
shipRig.position
);

if(
!asteroid.userData.fixedBelt
&&
distance>
1000
){

placeRoamingAsteroid(
asteroid,
false
);

}

const collisionRadius=
asteroid.userData.radius+
1.4;

if(
distance<
collisionRadius
){

hitPlayer();

forwardVector.set(
0,
0,
1
)
.applyQuaternion(
shipRig.quaternion
);

shipRig.position
.addScaledVector(
forwardVector,
-4
);

}

if(
!asteroid.userData.near
&&
distance>
collisionRadius+
1.5
&&
distance<
collisionRadius+
5.5
){

asteroid.userData.near=
true;

score+=
15;

}

if(
distance>
collisionRadius+
10
){

asteroid.userData.near=
false;

}

}

}


/* =========================================================
   VOO
========================================================= */

function updateFreeFlight(
dt
){

const left=
keys.has(
"KeyA"
)
||
keys.has(
"ArrowLeft"
);

const right=
keys.has(
"KeyD"
)
||
keys.has(
"ArrowRight"
);

const up=
keys.has(
"KeyW"
)
||
keys.has(
"ArrowUp"
);

const down=
keys.has(
"KeyS"
)
||
keys.has(
"ArrowDown"
);

turbo=
keys.has(
"ShiftLeft"
)
||
keys.has(
"ShiftRight"
);

let turnInput=
(
left
?
1
:
0
)
-
(
right
?
1
:
0
);

let pitchInput=
(
down
?
1
:
0
)
-
(
up
?
1
:
0
);


/* TOUCH NO CELULAR */

if(
isTouchSteering
){

turnInput+=
-touchSteerX;

pitchInput+=
touchSteerY;

turnInput=
THREE.MathUtils.clamp(
turnInput,
-1,
1
);

pitchInput=
THREE.MathUtils.clamp(
pitchInput,
-1,
1
);

}

const damping=
Math.pow(
0.045,
dt
);

yawVelocity+=
turnInput*
2.7*
dt;

pitchVelocity+=
pitchInput*
2.35*
dt;

yawVelocity*=
damping;

pitchVelocity*=
damping;

yawVelocity=
THREE.MathUtils.clamp(
yawVelocity,
-1.05,
1.05
);

pitchVelocity=
THREE.MathUtils.clamp(
pitchVelocity,
-0.85,
0.85
);

yaw+=
yawVelocity*
dt;

pitch+=
pitchVelocity*
dt;

pitch=
THREE.MathUtils.clamp(
pitch,
-1.30,
1.30
);

const desiredRoll=
-turnInput*
0.20
-
yawVelocity*
0.10;

roll+=
(
desiredRoll-
roll
)
*
Math.min(
1,
dt*
5.5
);

shipRig.rotation.set(
pitch,
yaw,
roll,
"YXZ"
);

const targetSpeed=
turbo
?
60
:
22;

speed+=
(
targetSpeed-
speed
)
*
Math.min(
1,
dt*
3.4
);

forwardVector.set(
0,
0,
1
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();

const moveDistance=
speed*
dt;

shipRig.position
.addScaledVector(
forwardVector,
moveDistance
);

distanceTravelled+=
moveDistance;

score+=
moveDistance*
0.05;

}


/* =========================================================
   HUD
========================================================= */

const topbarCyan=
document.querySelectorAll(
".topbar .cyan"
);

const sectorText=
topbarCyan.length>
1
?
topbarCyan[1]
:
null;

const footerSpans=
document.querySelectorAll(
".menu-footer span"
);

if(
footerSpans.length
){

footerSpans[
footerSpans.length-
1
].textContent=
"v1.9 LAUNCH SEQUENCE";

}


/* =========================================================
   LOOP
========================================================= */

let previousTime=
performance.now();

let screenAccumulator=
0;

function animate(
now
){

requestAnimationFrame(
animate
);

const dt=
Math.min(
(
now-
previousTime
)
/
1000,
0.05
);

previousTime=
now;

if(
gameStarted
&&
!gameOver
){

if(
launchState===
"launching"
){

updateLaunchSequence(
now,
dt
);

updateInfiniteStars();

}

else if(
manualControl
){

updateFreeFlight(
dt
);

updateInfiniteStars();

updateAsteroids(
dt
);

updatePoiMarkers();

}

}

updateStreaks(
dt,
speed
);


/* TELAS */

screenAccumulator+=
dt;

if(
screenAccumulator>
0.08
){

updateRealCockpitScreens(
now
);

screenAccumulator=
0;

}


/* CÂMERA */

const bob=
Math.sin(
now*
0.0017
)
*
(
gameStarted
?
0.008
:
0.004
);

let shakeX=0;

let shakeY=0;

if(
shake>
0
){

shake=
Math.max(
0,
shake-
dt*
1.9
);

shakeX=
(
Math.random()-
0.5
)
*
shake*
0.16;

shakeY=
(
Math.random()-
0.5
)
*
shake*
0.12;

}

camera.position.set(
shakeX,
bob+
shakeY,
0
);


/* FOV */

const desiredFov=
gameStarted
&&
turbo
?
94
:
COCKPIT_CAMERA.fov;

camera.fov+=
(
desiredFov-
camera.fov
)
*
Math.min(
1,
dt*
3.6
);

camera.updateProjectionMatrix();


/* TURBO */

const turboAmount=
gameStarted
?
THREE.MathUtils.clamp(
(
speed-
22
)
/
38,
0,
1
)
:
0;

turboFlash.style.opacity=
(
turboAmount*
0.9
)
.toFixed(
2
);

cockpitLight.intensity=
10+
turboAmount*
7;

renderer.toneMappingExposure=
1.18+
turboAmount*
0.12;


/* ANIMAÇÕES DO MUNDO */

planet.rotation.y+=
dt*
0.022;

atmosphere.rotation.y-=
dt*
0.01;

moon.rotation.y+=
dt*
0.016;

station.rotation.y+=
dt*
0.08;

wreck.rotation.y+=
dt*
0.025;

beaconOrb.scale.setScalar(
1+
Math.sin(
now*
0.006
)
*
0.12
);


/* TOP BAR */

if(
speedText
){

speedText.textContent=
turbo
?
"TURBO"
:
`${(
speed/
22
).toFixed(
1
)}x`;

}

if(
sectorText
){

sectorText.textContent=
currentSector();

}


/* COORDENADAS */

compass.innerHTML=
`X ${shipRig.position.x.toFixed(0)}
&nbsp;
Y ${shipRig.position.y.toFixed(0)}
&nbsp;
Z ${shipRig.position.z.toFixed(0)}
<br>
YAW ${THREE.MathUtils.radToDeg(yaw).toFixed(0)}°
&nbsp;
PITCH ${THREE.MathUtils.radToDeg(pitch).toFixed(0)}°`;


/* DANO */

impactFlash=
Math.max(
0,
impactFlash-
dt*
3.8
);

vignette.style.opacity=
(
impactFlash*
0.95
)
.toFixed(
2
);


/* RENDER */

renderer.render(
scene,
camera
);

}

requestAnimationFrame(
animate
);


/* =========================================================
   RESIZE
========================================================= */

window.addEventListener(
"resize",
()=>{

camera.aspect=
innerWidth/
innerHeight;

camera.updateProjectionMatrix();

renderer.setSize(
innerWidth,
innerHeight
);

}
);


}

catch(
error
){

console.error(
error
);

}

})();
