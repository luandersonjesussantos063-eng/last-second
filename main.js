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

const scene=new THREE.Scene();

scene.background=
new THREE.Color(
0x01030a
);

scene.fog=
new THREE.FogExp2(
0x01030a,
0.0012
);

const camera=
new THREE.PerspectiveCamera(

85,

window.innerWidth/
window.innerHeight,

0.01,

7000

);

camera.rotation.order=
"YXZ";

const renderer=
new THREE.WebGLRenderer({

antialias:true,

powerPreference:
"high-performance"

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

renderer.outputColorSpace=
THREE.SRGBColorSpace;

renderer.toneMapping=
THREE.ACESFilmicToneMapping;

renderer.toneMappingExposure=
1.18;

document.body.prepend(
renderer.domElement
);

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

const random=
(min,max)=>
min+
Math.random()*
(max-min);


/* =========================================================
   REMOVE OS HUDS FLUTUANTES ANTIGOS
========================================================= */

const cleanupStyle=
document.createElement(
"style"
);

cleanupStyle.textContent=`

.instructions{
display:none!important;
}

#hudExtra,
#spaceRadar,
#cockpitPanel{
display:none!important;
}

`;

document.head.appendChild(
cleanupStyle
);


/* =========================================================
   COORDENADAS
========================================================= */

const compass=
document.createElement(
"div"
);

compass.style.cssText=`

position:fixed;

right:18px;

top:18px;

z-index:20;

color:#91eaff;

font:
11px/1.5
Consolas,
monospace;

text-align:right;

pointer-events:none;

opacity:0;

transition:
opacity .7s;

text-shadow:
0 0 9px
rgba(80,220,255,.4);

`;

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

warning.style.cssText=`

position:fixed;

left:50%;

top:18%;

transform:
translateX(-50%);

z-index:25;

color:#ff5275;

font:
700 22px
Arial,
sans-serif;

letter-spacing:
3px;

text-shadow:
0 0 15px
rgba(255,50,90,.65);

opacity:0;

transition:
opacity .12s;

pointer-events:none;

text-align:center;

`;

warning.textContent=
"COLISÃO";

document.body.appendChild(
warning
);

const discoveryBanner=
document.createElement(
"div"
);

discoveryBanner.style.cssText=`

position:fixed;

left:50%;

top:27%;

transform:
translateX(-50%);

z-index:26;

color:#8df3ff;

font:
700 16px
Arial,
sans-serif;

letter-spacing:
3px;

text-align:center;

text-shadow:
0 0 16px
rgba(64,220,255,.75);

opacity:0;

transition:
opacity .3s;

pointer-events:none;

`;

document.body.appendChild(
discoveryBanner
);

const vignette=
document.createElement(
"div"
);

vignette.style.cssText=`

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

const turboFlash=
document.createElement(
"div"
);

turboFlash.style.cssText=`

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
   TELAS REAIS DA CABINE
========================================================= */

function makeScreenCanvas(
w=1024,
h=640
){

const canvas=
document.createElement(
"canvas"
);

canvas.width=
w;

canvas.height=
h;

return{

canvas,

ctx:
canvas.getContext(
"2d"
)

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

const texture=
new THREE.CanvasTexture(
screen.canvas
);

texture.colorSpace=
THREE.SRGBColorSpace;

texture.flipY=
false;

texture.minFilter=
THREE.LinearFilter;

texture.magFilter=
THREE.LinearFilter;

texture.generateMipmaps=
false;

texture.needsUpdate=
true;

return texture;

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


let screensReady=
false;


function applyScreenTexture(
mesh,
texture
){

mesh.material=
new THREE.MeshBasicMaterial({

map:texture,

toneMapped:false,

side:
THREE.DoubleSide

});

mesh.material.needsUpdate=
true;

}


function drawScreenFrame(
ctx,
w,
h,
title
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
"rgba(76,231,255,.8)";

ctx.lineWidth=
5;

ctx.strokeRect(

8,
8,

w-16,

h-16

);


ctx.fillStyle=
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
"rgba(76,231,255,.25)";

ctx.lineWidth=
2;

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

ctx.lineWidth=
2;

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

ctx.shadowBlur=
12;

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

ctx.shadowBlur=
0;

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

STAR_COUNT*
3

);


for(
let i=0;
i<STAR_COUNT;
i++
){

const j=
i*3;

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

color:
0xffffff,

size:
0.22,

transparent:
true,

opacity:
0.9,

sizeAttenuation:
true

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


let changed=
false;


for(
let i=0;
i<STAR_COUNT;
i++
){

const j=
i*3;


if(
p[j]-sx >
HALF_STAR_BOX
){

p[j]-=
STAR_BOX;

changed=
true;

}

else if(
p[j]-sx <
-HALF_STAR_BOX
){

p[j]+=
STAR_BOX;

changed=
true;

}


if(
p[j+1]-sy >
HALF_STAR_BOX
){

p[j+1]-=
STAR_BOX;

changed=
true;

}

else if(
p[j+1]-sy <
-HALF_STAR_BOX
){

p[j+1]+=
STAR_BOX;

changed=
true;

}


if(
p[j+2]-sz >
HALF_STAR_BOX
){

p[j+2]-=
STAR_BOX;

changed=
true;

}

else if(
p[j+2]-sz <
-HALF_STAR_BOX
){

p[j+2]+=
STAR_BOX;

changed=
true;

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
   TURBO / RASTROS
========================================================= */

const STREAK_COUNT=
360;

const streakGeometry=
new THREE.BufferGeometry();

const streakPositions=
new Float32Array(

STREAK_COUNT*
6

);

const streakData=[];


function resetStreak(
i,
first=false
){

streakData[i]={

x:
random(
-60,
60
),

y:
random(
-38,
38
),

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


const streakMaterial=
new THREE.LineBasicMaterial({

color:
0xa7eeff,

transparent:
true,

opacity:
0,

blending:
THREE.AdditiveBlending,

depthWrite:
false

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

(
speedNow-
22
)
/
38,

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
dt*
7
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


p[b]=
data.x;

p[b+1]=
data.y;

p[b+2]=
data.z;

p[b+3]=
data.x;

p[b+4]=
data.y;

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
   PLANETA
========================================================= */

const planet=
new THREE.Mesh(

new THREE.SphereGeometry(

42,

64,

48

),

new THREE.MeshStandardMaterial({

color:
0x284d8c,

roughness:
0.78,

metalness:
0.06,

emissive:
0x07152c,

emissiveIntensity:
0.72

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

color:
0x4aa9ff,

transparent:
true,

opacity:
0.12,

side:
THREE.BackSide,

blending:
THREE.AdditiveBlending,

depthWrite:
false

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


/* =========================================================
   LUA
========================================================= */

const moon=
new THREE.Mesh(

new THREE.SphereGeometry(

10,

36,

28

),

new THREE.MeshStandardMaterial({

color:
0x8d929c,

roughness:
1,

metalness:
0

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

color:
0x76808c,

metalness:
0.7,

roughness:
0.35,

emissive:
0x07141c,

emissiveIntensity:
0.4

})

);

stationCore.rotation.z=
Math.PI/
2;

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

color:
0x9ab2c6,

metalness:
0.72,

roughness:
0.28,

emissive:
0x0b3145,

emissiveIntensity:
0.6

})

);

stationRing.rotation.y=
Math.PI/
2;

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

color:
0x5d6673,

metalness:
0.75,

roughness:
0.35

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

color:
0x59eeff,

transparent:
true,

opacity:
0.9

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

color:
0x494f59,

metalness:
0.7,

roughness:
0.5,

emissive:
0x130506,

emissiveIntensity:
0.35

});


for(
let i=0;
i<9;
i++
){

const part=
new THREE.Mesh(

new THREE.BoxGeometry(

random(
2,
8
),

random(
1,
4
),

random(
2,
10
)

),

wreckMat

);


part.position.set(

random(
-16,
16
),

random(
-10,
10
),

random(
-14,
14
)

);


part.rotation.set(

random(
0,
Math.PI
),

random(
0,
Math.PI
),

random(
0,
Math.PI
)

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


/* TELAS REAIS DO MODELO */

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

}

);

}

}

);


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


screensReady=
true;

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

i*
12.9898

+

seed*
9.7

)
*
0.12

+

Math.cos(

i*
4.123

+

seed*
5.1

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

random(
-0.03,
0.03
),

random(
-0.04,
0.04
),

random(
-0.10,
0.08
)

);


return new THREE.MeshStandardMaterial({

color,

roughness:
0.96,

metalness:
0.02

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
Math.PI*
2
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
   LUZ ASTEROIDES
========================================================= */

const obstacleLight=
new THREE.DirectionalLight(

0xd9ecff,

4.3

);

obstacleLight.position.set(

-8,

10,

-12

);

world.add(
obstacleLight
);


const rimLight=
new THREE.DirectionalLight(

0x3f8cff,

2

);

rimLight.position.set(

9,

-5,

-8

);

world.add(
rimLight
);


/* =========================================================
   MARCADORES
========================================================= */

const poiLayer=
document.createElement(
"div"
);

poiLayer.style.cssText=

"position:fixed;inset:0;z-index:21;pointer-events:none;overflow:hidden;";

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


el.style.cssText=`

position:absolute;

transform:
translate(-50%,-50%);

color:#9ceeff;

font:
700 10px/1.3
Arial,
sans-serif;

letter-spacing:
1px;

text-align:center;

text-shadow:
0 0 9px
rgba(62,220,255,.8);

opacity:0;

white-space:
nowrap;

`;


el.innerHTML=`

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


const POIS=[

{

name:
"LUA NEREID",

short:
"LUA",

object:
moon,

discoverRadius:
55,

score:
150,

discovered:
false,

marker:
makeMarker(
"LUA NEREID"
)

},

{

name:
"PLANETA AURORA",

short:
"PLANETA",

object:
planet,

discoverRadius:
90,

score:
250,

discovered:
false,

marker:
makeMarker(
"PLANETA AURORA"
)

},

{

name:
"ESTAÇÃO ORBITAL",

short:
"ESTAÇÃO",

object:
station,

discoverRadius:
55,

score:
300,

discovered:
false,

marker:
makeMarker(
"ESTAÇÃO ORBITAL"
)

},

{

name:
"SINAL DESCONHECIDO",

short:
"SINAL",

object:
beacon,

discoverRadius:
45,

score:
350,

discovered:
false,

marker:
makeMarker(
"SINAL DESCONHECIDO"
)

},

{

name:
"DESTROÇOS K-17",

short:
"K-17",

object:
wreck,

discoverRadius:
55,

score:
400,

discovered:
false,

marker:
makeMarker(
"DESTROÇOS K-17"
)

}

];


/* =========================================================
   ESTADO
========================================================= */

const keys=
new Set();


let speed=
22;

let turbo=
false;

let health=
100;

let score=
0;

let gameStarted=
false;

let gameOver=
false;

let lastHitTime=
-9999;

let shake=
0;

let impactFlash=
0;

let yaw=
0;

let pitch=
0;

let roll=
0;

let yawVelocity=
0;

let pitchVelocity=
0;

let distanceTravelled=
0;


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

let nearest=
null;

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

distance=
d;

nearest=
poi;

}

}


return{

poi:
nearest,

distance

};

}


function getRadarRange(){

const distance=
getNearestPoi()
.distance;


if(
distance<
300
){

return 350;

}


if(
distance<
650
){

return 700;

}


if(
distance<
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
<span style="font-size:12px;color:white;">
${name} +${bonus}
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
window.innerWidth;


const y=

(
-projected.y*
0.5+
0.5
)

*
window.innerHeight;


if(

x>
40

&&

x<
window.innerWidth-
40

&&

y>
40

&&

y<
window.innerHeight-
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
   RADAR DAS TELAS
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

"LAST SECOND // NAV"

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
"#ffffff";

ctx.fillText(

currentSector(),

220,

118

);


ctx.fillStyle=
"#67dff0";

ctx.fillText(
"ALVO",
36,
172
);


ctx.fillStyle=
"#ffffff";

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
"#ffffff";

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
"#ffffff";

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
"#ffffff";

ctx.fillText(

`${discovered}/${POIS.length}`,

245,

438

);


ctx.fillStyle=
"#4dff9b";

ctx.font=
"700 26px Consolas";

ctx.fillText(

gameOver
?
"STATUS: CRÍTICO"
:
"STATUS: NOMINAL",

36,

505

);


leftTexture.needsUpdate=
true;

}


/* =========================================================
   TELA CENTRAL - RADAR
========================================================= */

function drawMidScreen(){

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

"NAVEGAÇÃO"

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
px-cx;

const dy=
py-cy;


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


/* POIS */

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
px-cx;

const dy=
py-cy;


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


ctx.fillRect(

-7,

-7,

14,

14

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
"#ffffff";

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

"SISTEMAS"

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

"#73efff";


ctx.fillText(

turbo

?

"⚡ TURBO ATIVO"

:

"PROPULSÃO NORMAL",

38,

h-
28

);


rightTexture.needsUpdate=
true;

}


function updateRealCockpitScreens(){

if(
!screensReady
){

return;

}


drawLeftScreen();

drawMidScreen();

drawRightScreen();

}


/* =========================================================
   CONTROLES MOBILE
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
gameOver
){

return;

}


try{

element.setPointerCapture?.(
event.pointerId
);

}

catch(
error
){}


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

gameStarted=
true;


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

}

);


/* =========================================================
   RESET
========================================================= */

function resetGame(){

health=
100;

score=
0;

speed=
22;

yaw=
0;

pitch=
0;

roll=
0;

yawVelocity=
0;

pitchVelocity=
0;

distanceTravelled=
0;

gameOver=
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

gameOver=
true;

speed=
0;

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
   VOO LIVRE
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


const turnInput=

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


const pitchInput=

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

"v1.7 REAL COCKPIT";

}


/* =========================================================
   LOOP
========================================================= */

let previousTime=
performance.now();


let screenAccumulator=
0;


function animate(
currentTime
){

requestAnimationFrame(
animate
);


const dt=
Math.min(

(
currentTime-
previousTime
)
/
1000,

0.05

);


previousTime=
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

}


updateStreaks(

dt,

speed

);


/* ATUALIZA AS TELAS 12 VEZES POR SEGUNDO */

screenAccumulator+=
dt;


if(
screenAccumulator>
0.08
){

updateRealCockpitScreens();


screenAccumulator=
0;

}


/* MOVIMENTO DA CÂMERA */

const bob=

Math.sin(

currentTime*
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


let shakeX=
0;

let shakeY=
0;


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


/* OBJETOS */

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

currentTime*
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

`X ${shipRig.position.x.toFixed(
0
)}

&nbsp;

Y ${shipRig.position.y.toFixed(
0
)}

&nbsp;

Z ${shipRig.position.z.toFixed(
0
)}

<br>

YAW ${THREE.MathUtils.radToDeg(
yaw
).toFixed(
0
)}°

&nbsp;

PITCH ${THREE.MathUtils.radToDeg(
pitch
).toFixed(
0
)}°`;


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
   RESPONSIVO
========================================================= */

window.addEventListener(

"resize",

()=>{

camera.aspect=

window.innerWidth/

window.innerHeight;


camera.updateProjectionMatrix();


renderer.setSize(

window.innerWidth,

window.innerHeight

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
