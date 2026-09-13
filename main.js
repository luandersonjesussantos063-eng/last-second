(async()=>{

try{

/* =========================================================
   IMPORTS
========================================================= */

const THREE = await import(
"https://esm.sh/three@0.186.0"
);

const { GLTFLoader } = await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/GLTFLoader.js"
);

const { DRACOLoader } = await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/DRACOLoader.js"
);

const $ = id => document.getElementById(id);


/* =========================================================
   HTML
========================================================= */

const speedText = $("speedText");
const hud = $("hud");

const menu = $("menu");
const startBtn = $("startBtn");

const howBtn = $("howBtn");
const howTo = $("howTo");
const closeHowBtn = $("closeHowBtn");

const mobileControls = $("mobileControls");
const mobileUp = $("mobileUp");
const mobileDown = $("mobileDown");
const mobileLeft = $("mobileLeft");
const mobileRight = $("mobileRight");
const mobileTurbo = $("mobileTurbo");


/* =========================================================
   CENA
========================================================= */

const scene = new THREE.Scene();

scene.background = new THREE.Color(
0x01030a
);

scene.fog = new THREE.FogExp2(
0x01030a,
0.0012
);


/* =========================================================
   CÂMERA
========================================================= */

const camera = new THREE.PerspectiveCamera(

85,

window.innerWidth /
window.innerHeight,

0.01,

7000

);

camera.rotation.order = "YXZ";


/* =========================================================
   RENDERER
========================================================= */

const renderer = new THREE.WebGLRenderer({

antialias:true,

powerPreference:"high-performance"

});

renderer.setSize(
window.innerWidth,
window.innerHeight
);

renderer.setPixelRatio(
Math.min(
window.devicePixelRatio,
2
)
);

renderer.outputColorSpace =
THREE.SRGBColorSpace;

renderer.toneMapping =
THREE.ACESFilmicToneMapping;

renderer.toneMappingExposure =
1.18;

document.body.prepend(
renderer.domElement
);


/* =========================================================
   CABINE
========================================================= */

const COCKPIT_CAMERA = {

x:-0.082,
y:-62.874,
z:27.989,

pitch:0,
yaw:Math.PI,

fov:85

};


/* =========================================================
   NAVE
========================================================= */

const shipRig =
new THREE.Group();

shipRig.rotation.order =
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

camera.fov =
COCKPIT_CAMERA.fov;

camera.updateProjectionMatrix();

shipRig.add(
camera
);


/* =========================================================
   MUNDO
========================================================= */

const world =
new THREE.Group();

scene.add(
world
);


/* =========================================================
   ILUMINAÇÃO
========================================================= */

scene.add(

new THREE.HemisphereLight(

0xbadfff,
0x05070c,
1.65

)

);


const cockpitLight =
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


const warmFill =
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


const sunLight =
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


/* =========================================================
   FUNÇÃO RANDOM
========================================================= */

const random =
(min,max)=>
min +
Math.random() *
(max-min);


/* =========================================================
   HUD EXTRA
========================================================= */

const hudExtra =
document.createElement(
"div"
);

hudExtra.id =
"hudExtra";

hudExtra.style.cssText = `

position:fixed;

left:18px;
bottom:18px;

z-index:20;

color:#dff9ff;

font:12px/1.55 Consolas,monospace;

background:rgba(0,8,18,.46);

border:1px solid rgba(72,216,255,.32);

border-radius:12px;

padding:10px 12px;

pointer-events:none;

backdrop-filter:blur(5px);

min-width:210px;

opacity:0;

transition:opacity .7s ease;

`;

document.body.appendChild(
hudExtra
);


/* =========================================================
   COORDENADAS
========================================================= */

const compass =
document.createElement(
"div"
);

compass.style.cssText = `

position:fixed;

right:18px;
top:18px;

z-index:20;

color:#91eaff;

font:11px/1.5 Consolas,monospace;

text-align:right;

pointer-events:none;

opacity:0;

transition:opacity .7s ease;

text-shadow:0 0 9px rgba(80,220,255,.4);

`;

document.body.appendChild(
compass
);


/* =========================================================
   OBJETIVO
========================================================= */

const objectiveHud =
document.createElement(
"div"
);

objectiveHud.style.cssText = `

position:fixed;

left:50%;
bottom:18px;

transform:translateX(-50%);

z-index:20;

color:#c9f8ff;

font:11px/1.5 Consolas,monospace;

text-align:center;

pointer-events:none;

opacity:0;

transition:opacity .7s ease;

text-shadow:0 0 10px rgba(70,220,255,.35);

`;

document.body.appendChild(
objectiveHud
);


/* =========================================================
   PAINEL DA CABINE
========================================================= */

const cockpitPanel =
document.createElement(
"div"
);

cockpitPanel.id =
"cockpitPanel";

cockpitPanel.style.cssText = `

position:fixed;

left:50%;
bottom:54px;

transform:translateX(-50%);

width:min(720px,64vw);
height:210px;

z-index:19;

display:grid;

grid-template-columns:
1fr 1.25fr 1fr;

gap:5px;

pointer-events:none;

opacity:0;

transition:
opacity .7s ease;

font-family:
Consolas,
monospace;

`;

document.body.appendChild(
cockpitPanel
);


/* =========================================================
   PAINEL ESQUERDO
========================================================= */

const shipPanel =
document.createElement(
"div"
);

shipPanel.style.cssText = `

border:
1px solid rgba(65,222,255,.55);

background:
linear-gradient(
180deg,
rgba(0,21,31,.88),
rgba(0,7,13,.92)
);

box-shadow:
inset 0 0 25px rgba(30,190,255,.08),
0 0 8px rgba(0,190,255,.12);

padding:12px;

color:#89efff;

font-size:12px;

text-shadow:
0 0 6px rgba(65,220,255,.4);

overflow:hidden;

`;

cockpitPanel.appendChild(
shipPanel
);


/* =========================================================
   PAINEL CENTRAL
========================================================= */

const navPanel =
document.createElement(
"div"
);

navPanel.style.cssText = `

position:relative;

border:
1px solid rgba(65,222,255,.7);

background:
radial-gradient(
circle,
rgba(1,35,43,.88),
rgba(0,8,14,.96)
);

box-shadow:
inset 0 0 30px rgba(20,220,255,.08),
0 0 10px rgba(20,180,255,.14);

overflow:hidden;

`;

cockpitPanel.appendChild(
navPanel
);


const panelRadar =
document.createElement(
"canvas"
);

panelRadar.width =
600;

panelRadar.height =
400;

panelRadar.style.cssText = `

width:100%;
height:100%;

display:block;

`;

navPanel.appendChild(
panelRadar
);

const panelRadarCtx =
panelRadar.getContext(
"2d"
);


/* =========================================================
   PAINEL DIREITO
========================================================= */

const systemsPanel =
document.createElement(
"div"
);

systemsPanel.style.cssText = `

border:
1px solid rgba(65,222,255,.55);

background:
linear-gradient(
180deg,
rgba(0,21,31,.88),
rgba(0,7,13,.92)
);

box-shadow:
inset 0 0 25px rgba(30,190,255,.08),
0 0 8px rgba(0,190,255,.12);

padding:12px;

color:#89efff;

font-size:11px;

text-shadow:
0 0 6px rgba(65,220,255,.4);

overflow:hidden;

`;

cockpitPanel.appendChild(
systemsPanel
);


/* =========================================================
   MOBILE DO PAINEL
========================================================= */

const cockpitStyle =
document.createElement(
"style"
);

cockpitStyle.textContent = `

@media
(max-width:900px),
(pointer:coarse){

#cockpitPanel{

width:58vw!important;

height:145px!important;

bottom:4px!important;

}

#cockpitPanel > div{

font-size:8px!important;

padding:6px!important;

}

}

@media
(max-height:500px)
and
(pointer:coarse){

#cockpitPanel{

width:55vw!important;

height:120px!important;

bottom:0!important;

}

}

`;

document.head.appendChild(
cockpitStyle
);


/* =========================================================
   ALERTAS
========================================================= */

const warning =
document.createElement(
"div"
);

warning.style.cssText = `

position:fixed;

left:50%;
top:18%;

transform:translateX(-50%);

z-index:25;

color:#ff5275;

font:
700 22px Arial,sans-serif;

letter-spacing:3px;

text-shadow:
0 0 15px rgba(255,50,90,.65);

opacity:0;

transition:opacity .12s;

pointer-events:none;

`;

warning.textContent =
"COLISÃO";

document.body.appendChild(
warning
);


const discoveryBanner =
document.createElement(
"div"
);

discoveryBanner.style.cssText = `

position:fixed;

left:50%;
top:27%;

transform:translateX(-50%);

z-index:26;

color:#8df3ff;

font:
700 16px Arial,sans-serif;

letter-spacing:3px;

text-align:center;

text-shadow:
0 0 16px rgba(64,220,255,.75);

opacity:0;

transition:opacity .3s;

pointer-events:none;

`;

document.body.appendChild(
discoveryBanner
);


const vignette =
document.createElement(
"div"
);

vignette.style.cssText = `

position:fixed;

inset:0;

z-index:18;

pointer-events:none;

opacity:0;

background:
radial-gradient(

circle at center,

transparent 45%,

rgba(255,50,80,.08) 75%,

rgba(255,30,60,.28) 100%

);

`;

document.body.appendChild(
vignette
);


const turboFlash =
document.createElement(
"div"
);

turboFlash.style.cssText = `

position:fixed;

inset:0;

z-index:17;

pointer-events:none;

opacity:0;

background:
radial-gradient(

circle at center,

rgba(90,220,255,.02),

rgba(60,170,255,.04) 55%,

rgba(30,120,255,.12)

);

`;

document.body.appendChild(
turboFlash
);


/* =========================================================
   ESTRELAS
========================================================= */

const STAR_COUNT =
4200;

const STAR_BOX =
2200;

const HALF_STAR_BOX =
STAR_BOX / 2;

const starGeometry =
new THREE.BufferGeometry();

const starPositions =
new Float32Array(
STAR_COUNT * 3
);


for(
let i=0;
i<STAR_COUNT;
i++
){

const j =
i*3;

starPositions[j] =
random(
-HALF_STAR_BOX,
HALF_STAR_BOX
);

starPositions[j+1] =
random(
-HALF_STAR_BOX,
HALF_STAR_BOX
);

starPositions[j+2] =
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


const stars =
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

const p =
starGeometry
.attributes
.position
.array;

const sx =
shipRig.position.x;

const sy =
shipRig.position.y;

const sz =
shipRig.position.z;

let changed =
false;


for(
let i=0;
i<STAR_COUNT;
i++
){

const j =
i*3;


if(
p[j]-sx >
HALF_STAR_BOX
){

p[j]-=
STAR_BOX;

changed=true;

}

else if(
p[j]-sx <
-HALF_STAR_BOX
){

p[j]+=
STAR_BOX;

changed=true;

}


if(
p[j+1]-sy >
HALF_STAR_BOX
){

p[j+1]-=
STAR_BOX;

changed=true;

}

else if(
p[j+1]-sy <
-HALF_STAR_BOX
){

p[j+1]+=
STAR_BOX;

changed=true;

}


if(
p[j+2]-sz >
HALF_STAR_BOX
){

p[j+2]-=
STAR_BOX;

changed=true;

}

else if(
p[j+2]-sz <
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
.needsUpdate =
true;

}

}


/* =========================================================
   RASTROS
========================================================= */

const STREAK_COUNT =
360;

const streakGeometry =
new THREE.BufferGeometry();

const streakPositions =
new Float32Array(
STREAK_COUNT * 6
);

const streakData = [];


function resetStreak(
i,
first=false
){

streakData[i] = {

x:
random(-60,60),

y:
random(-38,38),

z:
random(

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


const streakMaterial =
new THREE.LineBasicMaterial({

color:0xa7eeff,

transparent:true,

opacity:0,

blending:
THREE.AdditiveBlending,

depthWrite:false

});


const streaks =
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

const p =
streakGeometry
.attributes
.position
.array;


const factor =
THREE.MathUtils.clamp(

(speedNow-22)/38,

0,
1

);


const length =
2 +
factor*20;


const move =
speedNow *
dt *
(
2.2 +
factor*2.1
);


streakMaterial.opacity +=

(
factor*0.8 -
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

const data =
streakData[i];

data.z -=
move;


if(
data.z <
1
){

resetStreak(
i,
false
);

}


const b =
i*6;

p[b] =
data.x;

p[b+1] =
data.y;

p[b+2] =
data.z;

p[b+3] =
data.x;

p[b+4] =
data.y;

p[b+5] =
data.z + length;

}


streakGeometry
.attributes
.position
.needsUpdate =
true;

}


/* =========================================================
   PLANETA
========================================================= */

const planet =
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


const atmosphere =
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

side:
THREE.BackSide,

blending:
THREE.AdditiveBlending,

depthWrite:false

})

);

atmosphere.position.copy(
planet.position
);

world.add(
atmosphere
);


const planetGlow =
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


/* =========================================================
   LUA
========================================================= */

const moon =
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

const station =
new THREE.Group();


const stationCore =
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

stationCore.rotation.z =
Math.PI/2;

station.add(
stationCore
);


const stationRing =
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

stationRing.rotation.y =
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

const beacon =
new THREE.Group();


const beaconPole =
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


const beaconOrb =
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

beaconOrb.position.y =
11;

beacon.add(
beaconOrb
);


const beaconLight =
new THREE.PointLight(

0x4feaff,
70,
180

);

beaconLight.position.y =
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

const wreck =
new THREE.Group();


const wreckMat =
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

const part =
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
   COCKPIT 3D
========================================================= */

const dracoLoader =
new DRACOLoader();

dracoLoader.setDecoderPath(

"https://www.gstatic.com/draco/versioned/decoders/1.5.7/"

);

const loader =
new GLTFLoader();

loader.setDRACOLoader(
dracoLoader
);


loader.load(

"./models/cockpit_scifi.glb",

gltf=>{

const cockpit =
gltf.scene;


cockpit.traverse(
child=>{

if(
!child.isMesh
){
return;
}

const materials =

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

material.needsUpdate =
true;

}

});

});


const box =
new THREE.Box3()
.setFromObject(
cockpit
);

const size =
new THREE.Vector3();

const center =
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

12 /

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

cockpit.position.x -=
COCKPIT_CAMERA.x;

cockpit.position.y -=
COCKPIT_CAMERA.y;

cockpit.position.z -=
COCKPIT_CAMERA.z;

shipRig.add(
cockpit
);

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

const geometry =
new THREE.IcosahedronGeometry(
1,
2
);

const position =
geometry.attributes.position;

const vector =
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

const wobble =

0.78

+

Math.sin(
i*12.9898 +
seed*9.7
)
*0.12

+

Math.cos(
i*4.123 +
seed*5.1
)
*0.08

+

Math.random()*0.08;


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

position.needsUpdate =
true;

geometry.computeVertexNormals();

return geometry;

}


const asteroidGeometries =
[1,2,3,4]
.map(
createAsteroidGeometry
);


const asteroids = [];


function makeAsteroidMaterial(){

const color =
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

const scale =
random(
1.2,
5.3
);

asteroid.scale.set(

scale*random(0.86,1.18),

scale*random(0.84,1.16),

scale*random(0.86,1.2)

);

asteroid.userData.radius =
scale*0.9;

asteroid.userData.spinX =
random(-0.65,0.65);

asteroid.userData.spinY =
random(-0.65,0.65);

asteroid.userData.spinZ =
random(-0.65,0.65);

asteroid.userData.near =
false;

}


function placeBeltAsteroid(
asteroid
){

const angle =
random(
0,
Math.PI*2
);

const radius =
random(
85,
220
);

asteroid.position.set(

planet.position.x +
Math.cos(angle)*radius,

planet.position.y +
random(-48,48),

planet.position.z +
Math.sin(angle)*radius

);

setAsteroidScale(
asteroid
);

}


function placeRoamingAsteroid(
asteroid,
first=false
){

const forward =
new THREE.Vector3(
0,
0,
1
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();


const right =
new THREE.Vector3(
1,
0,
0
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();


const up =
new THREE.Vector3(
0,
1,
0
)
.applyQuaternion(
shipRig.quaternion
)
.normalize();


const ahead =

first
?
random(100,720)
:
random(260,850);


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
random(-320,320)
)
.addScaledVector(
up,
random(-170,170)
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

const asteroid =
new THREE.Mesh(

asteroidGeometries[
i %
asteroidGeometries.length
],

makeAsteroidMaterial()

);

asteroid.userData.fixedBelt =
i < 40;


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
   MARCADORES DOS LOCAIS
========================================================= */

const poiLayer =
document.createElement(
"div"
);

poiLayer.style.cssText = `

position:fixed;

inset:0;

z-index:21;

pointer-events:none;

overflow:hidden;

`;

document.body.appendChild(
poiLayer
);


function makeMarker(
label
){

const el =
document.createElement(
"div"
);

el.style.cssText = `

position:absolute;

transform:
translate(-50%,-50%);

color:#9ceeff;

font:
700 10px/1.3 Arial,sans-serif;

letter-spacing:1px;

text-align:center;

text-shadow:
0 0 9px rgba(62,220,255,.8);

opacity:0;

white-space:nowrap;

`;


el.innerHTML = `

<div
style="
width:12px;
height:12px;
border:1px solid rgba(120,235,255,.9);
transform:rotate(45deg);
margin:0 auto 5px;
">
</div>

<span>
${label}
</span>

<div
class="poi-distance">
</div>

`;

poiLayer.appendChild(
el
);

return el;

}


const POIS = [

{

name:"LUA NEREID",

short:"LUA",

object:moon,

discoverRadius:55,

score:150,

discovered:false,

marker:
makeMarker("LUA NEREID")

},

{

name:"PLANETA AURORA",

short:"PLANETA",

object:planet,

discoverRadius:90,

score:250,

discovered:false,

marker:
makeMarker("PLANETA AURORA")

},

{

name:"ESTAÇÃO ORBITAL",

short:"ESTAÇÃO",

object:station,

discoverRadius:55,

score:300,

discovered:false,

marker:
makeMarker("ESTAÇÃO ORBITAL")

},

{

name:"SINAL DESCONHECIDO",

short:"SINAL",

object:beacon,

discoverRadius:45,

score:350,

discovered:false,

marker:
makeMarker("SINAL DESCONHECIDO")

},

{

name:"DESTROÇOS K-17",

short:"K-17",

object:wreck,

discoverRadius:55,

score:400,

discovered:false,

marker:
makeMarker("DESTROÇOS K-17")

}

];


/* =========================================================
   ESTADO
========================================================= */

const keys =
new Set();

let speed =
22;

let turbo =
false;

let health =
100;

let score =
0;

let gameStarted =
false;

let gameOver =
false;

let lastHitTime =
-9999;

let shake =
0;

let impactFlash =
0;

let yaw =
0;

let pitch =
0;

let roll =
0;

let yawVelocity =
0;

let pitchVelocity =
0;

let distanceTravelled =
0;

const forwardVector =
new THREE.Vector3();


/* =========================================================
   DESCOBERTA
========================================================= */

function flashDiscovery(
name,
bonus
){

discoveryBanner.innerHTML = `

LOCAL DESCOBERTO

<br>

<span
style="
font-size:12px;
color:white;
">

${name}

+${bonus}

</span>

`;

discoveryBanner.style.opacity =
"1";

clearTimeout(
flashDiscovery.timer
);

flashDiscovery.timer =
setTimeout(

()=>{

discoveryBanner.style.opacity =
"0";

},

2200

);

}


/* =========================================================
   POIS
========================================================= */

function updatePoiMarkers(){

for(
const poi
of POIS
){

const worldPos =
new THREE.Vector3();

poi.object.getWorldPosition(
worldPos
);


const distance =
worldPos.distanceTo(
shipRig.position
);


if(

!poi.discovered

&&

distance <=
poi.discoverRadius

){

poi.discovered =
true;

score +=
poi.score;

flashDiscovery(
poi.name,
poi.score
);

}


const projected =
worldPos
.clone()
.project(
camera
);


const visible =

projected.z > -1

&&

projected.z < 1

&&

distance < 1800

&&

gameStarted

&&

!gameOver;


if(
visible
){

const x =

(
projected.x*0.5 +
0.5
)

*
window.innerWidth;


const y =

(
-projected.y*0.5 +
0.5
)

*
window.innerHeight;


if(

x > 40

&&

x <
window.innerWidth-40

&&

y > 40

&&

y <
window.innerHeight-40

){

poi.marker.style.left =
`${x}px`;

poi.marker.style.top =
`${y}px`;

poi.marker.style.opacity =
poi.discovered
?
"0.35"
:
"1";


poi.marker.querySelector(
".poi-distance"
).textContent =

`${Math.round(distance)} u${
poi.discovered
?
" • DESCOBERTO"
:
""
}`;

}

else{

poi.marker.style.opacity =
"0";

}

}

else{

poi.marker.style.opacity =
"0";

}

}

}


/* =========================================================
   RADAR DO PAINEL
========================================================= */

const radarTemp =
new THREE.Vector3();

const poiPos =
new THREE.Vector3();

const radarQuaternion =
new THREE.Quaternion();

const radarAxisY =
new THREE.Vector3(
0,
1,
0
);


function getNearestPoi(){

let nearest =
null;

let distance =
Infinity;


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
poiPos
);


const d =
poiPos.distanceTo(
shipRig.position
);


if(
d < distance
){

distance =
d;

nearest =
poi;

}

}


return {

poi:nearest,

distance

};

}


function getRadarRange(){

const result =
getNearestPoi();


if(
result.distance < 300
){

return 350;

}


if(
result.distance < 650
){

return 700;

}


if(
result.distance < 1200
){

return 1300;

}


return 2200;

}


function drawCockpitRadar(){

const ctx =
panelRadarCtx;

const width =
panelRadar.width;

const height =
panelRadar.height;

const cx =
width/2;

const cy =
height/2 + 10;

const radius =
Math.min(
width,
height
)*0.36;

const radarRange =
getRadarRange();


ctx.clearRect(
0,
0,
width,
height
);


/* FUNDO */

ctx.fillStyle =
"rgba(0,15,20,.94)";

ctx.fillRect(
0,
0,
width,
height
);


/* TÍTULO */

ctx.fillStyle =
"#7defff";

ctx.font =
"bold 22px Consolas";

ctx.textAlign =
"left";

ctx.fillText(

"NAVEGAÇÃO",

20,

28

);


/* ANÉIS */

for(
let i=1;
i<=4;
i++
){

ctx.beginPath();

ctx.arc(

cx,
cy,

radius*i/4,

0,

Math.PI*2

);

ctx.strokeStyle =
"rgba(65,220,240,.23)";

ctx.lineWidth =
2;

ctx.stroke();

}


/* CRUZ */

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

ctx.strokeStyle =
"rgba(70,220,240,.18)";

ctx.stroke();


/* DIREÇÕES */

ctx.fillStyle =
"#87efff";

ctx.font =
"18px Consolas";

ctx.textAlign =
"center";

ctx.fillText(
"N",
cx,
cy-radius-10
);

ctx.fillText(
"S",
cx,
cy+radius+24
);

ctx.fillText(
"W",
cx-radius-20,
cy+6
);

ctx.fillText(
"E",
cx+radius+20,
cy+6
);


/* ROTAÇÃO */

radarQuaternion.setFromAxisAngle(

radarAxisY,

-yaw

);


/* ASTEROIDES */

for(
const asteroid
of asteroids
){

const distance =
asteroid.position.distanceTo(
shipRig.position
);


if(
distance >
radarRange
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


const px =

cx +

(
radarTemp.x/
radarRange
)
*
radius;


const py =

cy -

(
radarTemp.z/
radarRange
)
*
radius;


const dx =
px-cx;

const dy =
py-cy;


if(

dx*dx +
dy*dy

>

radius*radius

){
continue;
}


ctx.beginPath();

ctx.arc(
px,
py,
3,
0,
Math.PI*2
);

ctx.fillStyle =
"rgba(255,170,80,.75)";

ctx.fill();

}


/* LOCAIS */

for(
const poi
of POIS
){

poi.object.getWorldPosition(
poiPos
);


const distance =
poiPos.distanceTo(
shipRig.position
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


let px =

cx +

(
radarTemp.x /
radarRange
)
*
radius;


let py =

cy -

(
radarTemp.z /
radarRange
)
*
radius;


const dx =
px-cx;

const dy =
py-cy;


const markerDistance =
Math.sqrt(
dx*dx +
dy*dy
);


if(
markerDistance >
radius*0.90
){

const angle =
Math.atan2(
dy,
dx
);

px =
cx +
Math.cos(angle)*
radius*0.90;

py =
cy +
Math.sin(angle)*
radius*0.90;

}


ctx.save();

ctx.translate(
px,
py
);

ctx.rotate(
Math.PI/4
);


ctx.fillStyle =

poi.discovered

?

"rgba(90,170,185,.5)"

:

"#49efff";


ctx.fillRect(

-6,
-6,
12,
12

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
-16
);

ctx.lineTo(
-10,
12
);

ctx.lineTo(
0,
7
);

ctx.lineTo(
10,
12
);

ctx.closePath();

ctx.fillStyle =
"#ffffff";

ctx.shadowColor =
"#53eaff";

ctx.shadowBlur =
15;

ctx.fill();

ctx.restore();


ctx.fillStyle =
"rgba(120,235,255,.75)";

ctx.font =
"15px Consolas";

ctx.textAlign =
"center";

ctx.fillText(

`ALCANCE ${radarRange}u`,

cx,

height-10

);

}


/* =========================================================
   PAINÉIS
========================================================= */

function updateCockpitPanels(){

const nearest =
getNearestPoi();


const targetName =

nearest.poi

?

nearest.poi.name

:

"EXPLORAÇÃO COMPLETA";


const targetDistance =

nearest.poi

?

`${Math.round(
nearest.distance
)} U`

:

"---";


const healthColor =

health > 40

?

"#5ff7ff"

:

"#ff526d";


shipPanel.innerHTML = `

<div
style="
font-size:13px;
font-weight:bold;
color:#b5f9ff;
margin-bottom:8px;
"
>

LAST SECOND

</div>

<div>
SETOR
</div>

<div
style="
color:#fff;
margin-bottom:10px;
"
>

${currentSector()}

</div>

<div>
ALVO
</div>

<div
style="
color:#fff;
font-weight:bold;
margin-bottom:8px;
"
>

${targetName}

</div>

<div>
DISTÂNCIA
</div>

<div
style="
color:#fff;
margin-bottom:8px;
"
>

${targetDistance}

</div>

<div>
VELOCIDADE
</div>

<div
style="
color:#fff;
"
>

${Math.round(speed)}

${
turbo
?
" • TURBO"
:
""
}

</div>

<div
style="
margin-top:8px;
"
>

INTEGRIDADE

<span
style="
color:${healthColor};
font-weight:bold;
"
>

${health}%

</span>

</div>

`;


const energy =

turbo

?

78

:

100;


const propulsion =

turbo

?

100

:

64;


const systemBar =
(
name,
value,
color="#4cecff"
)=>`

<div
style="
margin-bottom:7px;
"
>

<div
style="
display:flex;
justify-content:space-between;
font-size:9px;
"
>

<span>
${name}
</span>

<span>
${value}%
</span>

</div>

<div
style="
height:6px;
margin-top:2px;
border:1px solid rgba(100,230,255,.35);
"
>

<div
style="
width:${value}%;
height:100%;
background:${color};
box-shadow:0 0 8px ${color};
"
>
</div>

</div>

</div>

`;


systemsPanel.innerHTML = `

<div
style="
font-size:13px;
font-weight:bold;
color:#b5f9ff;
margin-bottom:10px;
"
>

SISTEMAS

</div>

${systemBar(
"PROPULSÃO",
propulsion
)}

${systemBar(
"ENERGIA",
energy
)}

${systemBar(
"INTEGRIDADE",
health,
health > 40
?
"#4cecff"
:
"#ff526d"
)}

${systemBar(
"NAVEGAÇÃO",
100
)}

<div
style="
margin-top:10px;
font-size:9px;
line-height:1.7;
"
>

COMUNICAÇÃO
<span
style="
float:right;
color:#4dff9b;
"
>
ONLINE
</span>

<br>

SUPORTE DE VIDA

<span
style="
float:right;
color:#4dff9b;
"
>
ONLINE
</span>

<br>

RADAR

<span
style="
float:right;
color:#4dff9b;
"
>
ONLINE
</span>

</div>

<div
style="
margin-top:12px;
color:${turbo ? "#ffcf4a" : "#72efff"};
font-weight:bold;
"
>

${
turbo
?
"⚡ TURBO ATIVO"
:
"PROPULSÃO NORMAL"
}

</div>

`;

}


/* =========================================================
   MOBILE
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
!gameStarted ||
gameOver
){
return;
}


try{

element.setPointerCapture?.(
event.pointerId
);

}
catch(error){}


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
{passive:false}
);

element.addEventListener(
"pointerup",
release,
{passive:false}
);

element.addEventListener(
"pointercancel",
release,
{passive:false}
);

element.addEventListener(
"lostpointercapture",
release,
{passive:false}
);

}


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
   MENU
========================================================= */

startBtn.addEventListener(

"click",

()=>{

gameStarted =
true;

menu.classList.add(
"hide"
);

hud.classList.add(
"show"
);

hudExtra.style.opacity =
"1";

compass.style.opacity =
"1";

objectiveHud.style.opacity =
"1";

cockpitPanel.style.opacity =
"1";


if(
mobileControls
){

mobileControls.classList.add(
"show"
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
event.code ===
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

}

);


/* =========================================================
   RESET
========================================================= */

function resetGame(){

health =
100;

score =
0;

speed =
22;

yaw =
0;

pitch =
0;

roll =
0;

yawVelocity =
0;

pitchVelocity =
0;

distanceTravelled =
0;

gameOver =
false;

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

warning.style.opacity =
"0";

keys.clear();


POIS.forEach(
poi=>{

poi.discovered =
false;

}

);

}


/* =========================================================
   DANO
========================================================= */

function hitPlayer(){

const now =
performance.now();


if(

now-lastHitTime <
700

||

gameOver

){
return;
}


lastHitTime =
now;

health =
Math.max(
0,
health-20
);

shake =
0.5;

impactFlash =
1;

warning.style.opacity =
"1";


setTimeout(

()=>{

if(
!gameOver
){

warning.style.opacity =
"0";

}

},

180

);


if(
health <= 0
){

gameOver =
true;

speed =
0;

keys.clear();

warning.textContent =

"SISTEMA CRÍTICO — R PARA REINICIAR";

warning.style.opacity =
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

asteroid.rotation.x +=
asteroid.userData.spinX*dt;

asteroid.rotation.y +=
asteroid.userData.spinY*dt;

asteroid.rotation.z +=
asteroid.userData.spinZ*dt;


const distance =
asteroid.position.distanceTo(
shipRig.position
);


if(

!asteroid.userData.fixedBelt

&&

distance > 1000

){

placeRoamingAsteroid(
asteroid,
false
);

}


const collisionRadius =

asteroid.userData.radius +
1.4;


if(
distance <
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

distance >
collisionRadius+1.5

&&

distance <
collisionRadius+5.5

){

asteroid.userData.near =
true;

score +=
15;

}


if(
distance >
collisionRadius+10
){

asteroid.userData.near =
false;

}

}

}


/* =========================================================
   VOO LIVRE
========================================================= */

function updateFreeFlight(
dt
){

const left =

keys.has("KeyA")

||

keys.has("ArrowLeft");


const right =

keys.has("KeyD")

||

keys.has("ArrowRight");


const up =

keys.has("KeyW")

||

keys.has("ArrowUp");


const down =

keys.has("KeyS")

||

keys.has("ArrowDown");


turbo =

keys.has("ShiftLeft")

||

keys.has("ShiftRight");


const turnInput =

(left ? 1 : 0)

-

(right ? 1 : 0);


const pitchInput =

(down ? 1 : 0)

-

(up ? 1 : 0);


const angularDamping =
Math.pow(
0.045,
dt
);


yawVelocity +=
turnInput *
2.7 *
dt;


pitchVelocity +=
pitchInput *
2.35 *
dt;


yawVelocity *=
angularDamping;

pitchVelocity *=
angularDamping;


yawVelocity =
THREE.MathUtils.clamp(
yawVelocity,
-1.05,
1.05
);


pitchVelocity =
THREE.MathUtils.clamp(
pitchVelocity,
-0.85,
0.85
);


yaw +=
yawVelocity *
dt;


pitch +=
pitchVelocity *
dt;


pitch =
THREE.MathUtils.clamp(
pitch,
-1.30,
1.30
);


const desiredRoll =

-turnInput*0.20

-

yawVelocity*0.10;


roll +=

(
desiredRoll-roll
)

*

Math.min(
1,
dt*5.5
);


shipRig.rotation.set(

pitch,
yaw,
roll,

"YXZ"

);


const targetSpeed =

turbo

?

60

:

22;


speed +=

(
targetSpeed-speed
)

*

Math.min(
1,
dt*3.4
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


const moveDistance =
speed *
dt;


shipRig.position
.addScaledVector(

forwardVector,

moveDistance

);


distanceTravelled +=
moveDistance;


score +=
moveDistance *
0.05;

}


/* =========================================================
   SETOR
========================================================= */

function currentSector(){

const size =
1000;

const sx =
Math.floor(
shipRig.position.x /
size
);

const sz =
Math.floor(
shipRig.position.z /
size
);


return `S-${

sx >= 0
?
"+"
:
""

}${sx}:${

sz >= 0
?
"+"
:
""

}${sz}`;

}


const topbarCyan =
document.querySelectorAll(
".topbar .cyan"
);


const sectorText =

topbarCyan.length > 1

?

topbarCyan[1]

:

null;


const footerSpans =
document.querySelectorAll(
".menu-footer span"
);


if(
footerSpans.length
){

footerSpans[
footerSpans.length-1
].textContent =

"v1.6 COCKPIT SYSTEM";

}


/* =========================================================
   LOOP
========================================================= */

let previousTime =
performance.now();


function animate(
currentTime
){

requestAnimationFrame(
animate
);


const dt =
Math.min(

(
currentTime -
previousTime
)
/
1000,

0.05

);


previousTime =
currentTime;


if(

gameStarted

&&

!gameOver

){

updateFreeFlight(
dt
);

updateInfiniteStars();

updateAsteroids(
dt
);

updatePoiMarkers();

drawCockpitRadar();

updateCockpitPanels();

}


updateStreaks(
dt,
speed
);


/* =========================================================
   CÂMERA
========================================================= */

const bob =

Math.sin(
currentTime *
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


let shakeX =
0;

let shakeY =
0;


if(
shake > 0
){

shake =
Math.max(
0,
shake -
dt*1.9
);


shakeX =

(
Math.random()-0.5
)

*
shake *
0.16;


shakeY =

(
Math.random()-0.5
)

*
shake *
0.12;

}


camera.position.set(

shakeX,

bob+shakeY,

0

);


/* =========================================================
   TURBO
========================================================= */

const desiredFov =

gameStarted

&&

turbo

?

94

:

COCKPIT_CAMERA.fov;


camera.fov +=

(
desiredFov-camera.fov
)

*
Math.min(
1,
dt*3.6
);


camera.updateProjectionMatrix();


const turboAmount =

gameStarted

?

THREE.MathUtils.clamp(

(speed-22)/38,

0,
1

)

:

0;


turboFlash.style.opacity =

(
turboAmount*0.9
)
.toFixed(
2
);


/* =========================================================
   OBJETOS
========================================================= */

planet.rotation.y +=
dt*0.022;

atmosphere.rotation.y -=
dt*0.01;

moon.rotation.y +=
dt*0.016;

station.rotation.y +=
dt*0.08;

wreck.rotation.y +=
dt*0.025;


beaconOrb.scale.setScalar(

1 +

Math.sin(
currentTime*0.006
)
*
0.12

);


/* =========================================================
   HUD
========================================================= */

if(
speedText
){

speedText.textContent =

turbo

?

"TURBO"

:

`${(
speed/22
).toFixed(
1
)}x`;

}


if(
sectorText
){

sectorText.textContent =
currentSector();

}


const discovered =
POIS.filter(
p=>p.discovered
).length;


const healthColor =

health > 40

?

"#67e8ff"

:

"#ff5275";


hudExtra.innerHTML = `

INTEGRIDADE

<b style="color:${healthColor}">
${health}%
</b>

<br>

VELOCIDADE

<b>
${Math.round(speed)}
</b>

<br>

DISTÂNCIA

<b>
${Math.floor(distanceTravelled)} u
</b>

<br>

PONTOS

<b>
${Math.floor(score)}
</b>

<br>

LOCAIS

<b>
${discovered}/${POIS.length}
</b>

<br>

VERSÃO

<b>
1.6 COCKPIT
</b>

`;


const nearest =
getNearestPoi();


objectiveHud.innerHTML =

nearest.poi

?

`

EXPLORAÇÃO

${discovered}/${POIS.length}

&nbsp; • &nbsp;

ALVO:

<b>
${nearest.poi.name}
</b>

${Math.round(
nearest.distance
)} u

`

:

`

EXPLORAÇÃO

${discovered}/${POIS.length}

&nbsp; • &nbsp;

TODOS OS SINAIS DESCOBERTOS

`;


compass.innerHTML = `

X
${shipRig.position.x.toFixed(0)}

&nbsp;

Y
${shipRig.position.y.toFixed(0)}

&nbsp;

Z
${shipRig.position.z.toFixed(0)}

<br>

YAW
${THREE.MathUtils.radToDeg(yaw).toFixed(0)}°

&nbsp;

PITCH
${THREE.MathUtils.radToDeg(pitch).toFixed(0)}°

`;


impactFlash =
Math.max(
0,
impactFlash -
dt*3.8
);


vignette.style.opacity =
(
impactFlash *
0.95
)
.toFixed(
2
);


renderer.render(
scene,
camera
);

}


requestAnimationFrame(
animate
);


/* =========================================================
   RESPONSIVO
========================================================= */

window.addEventListener(

"resize",

()=>{

camera.aspect =

window.innerWidth /
window.innerHeight;


camera.updateProjectionMatrix();


renderer.setSize(

window.innerWidth,
window.innerHeight

);

}

);


}

catch(error){

console.error(
error
);

}

})();
