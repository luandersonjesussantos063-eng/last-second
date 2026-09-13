(async()=>{

try{

const THREE=await import(
"https://esm.sh/three@0.186.0"
);

const {
GLTFLoader
}=await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/GLTFLoader.js"
);

const {
DRACOLoader
}=await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/DRACOLoader.js"
);


const $=
id=>
document.getElementById(
id
);


const speedText=
$("speedText");

const hud=
$("hud");

const menu=
$("menu");

const startBtn=
$("startBtn");

const howBtn=
$("howBtn");

const howTo=
$("howTo");

const closeHowBtn=
$("closeHowBtn");

const mobileControls=
$("mobileControls");

const mobileUp=
$("mobileUp");

const mobileDown=
$("mobileDown");

const mobileLeft=
$("mobileLeft");

const mobileRight=
$("mobileRight");

const mobileTurbo=
$("mobileTurbo");


/* =========================
   CENA
========================= */

const scene=
new THREE.Scene();


scene.background=
new THREE.Color(
0x01030a
);


scene.fog=
new THREE.FogExp2(
0x01030a,
0.0012
);


/* =========================
   CÂMERA
========================= */

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


/* =========================
   RENDERER
========================= */

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


/* =========================
   CABINE
========================= */

const COCKPIT_CAMERA={

x:-0.082,

y:-62.874,

z:27.989,

pitch:0,

yaw:Math.PI,

fov:85

};


/* =========================
   NAVE
========================= */

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


/* =========================
   MUNDO
========================= */

const world=
new THREE.Group();


scene.add(
world
);


/* =========================
   LUZ
========================= */

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


/* =========================
   HUD EXTRA
========================= */

const hudExtra=
document.createElement(
"div"
);


hudExtra.id=
"hudExtra";


hudExtra.style.cssText=`

position:fixed;

left:18px;

bottom:18px;

z-index:20;

color:#dff9ff;

font:
12px/1.55
Consolas,
monospace;

background:
rgba(0,8,18,.46);

border:
1px solid
rgba(72,216,255,.32);

border-radius:
12px;

padding:
10px 12px;

pointer-events:none;

backdrop-filter:
blur(5px);

min-width:
210px;

opacity:0;

transition:
opacity .7s ease;

`;


document.body.appendChild(
hudExtra
);


/* =========================
   AVISO
========================= */

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


/* =========================
   AVISO DESCOBERTA
========================= */

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


/* =========================
   FLASH IMPACTO
========================= */

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

rgba(255,255,255,0)
45%,

rgba(255,50,80,.08)
75%,

rgba(255,30,60,.28)
100%

);

transition:
opacity .08s linear;

`;


document.body.appendChild(
vignette
);


/* =========================
   TURBO VISUAL
========================= */

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

rgba(60,170,255,.04)
55%,

rgba(30,120,255,.12)

);

`;


document.body.appendChild(
turboFlash
);


/* =========================
   COORDENADAS
========================= */

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
opacity .7s ease;

text-shadow:
0 0 9px
rgba(80,220,255,.4);

`;


document.body.appendChild(
compass
);


/* =========================
   OBJETIVO
========================= */

const objectiveHud=
document.createElement(
"div"
);


objectiveHud.style.cssText=`

position:fixed;

left:50%;

bottom:18px;

transform:
translateX(-50%);

z-index:20;

color:#c9f8ff;

font:
11px/1.5
Consolas,
monospace;

text-align:center;

pointer-events:none;

opacity:0;

transition:
opacity .7s ease;

text-shadow:
0 0 10px
rgba(70,220,255,.35);

background:
rgba(0,8,18,.36);

border:
1px solid
rgba(72,216,255,.22);

border-radius:
10px;

padding:
7px 12px;

`;


document.body.appendChild(
objectiveHud
);


const random=
(
min,
max
)=>

min+

Math.random()*

(
max-
min
);


/* =========================
   ESTRELAS
========================= */

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


const dx=
p[j]-sx;


const dy=
p[j+1]-sy;


const dz=
p[j+2]-sz;


if(
dx>
HALF_STAR_BOX
){

p[j]-=
STAR_BOX;

changed=
true;

}

else if(
dx<
-HALF_STAR_BOX
){

p[j]+=
STAR_BOX;

changed=
true;

}


if(
dy>
HALF_STAR_BOX
){

p[j+1]-=
STAR_BOX;

changed=
true;

}

else if(
dy<
-HALF_STAR_BOX
){

p[j+1]+=
STAR_BOX;

changed=
true;

}


if(
dz>
HALF_STAR_BOX
){

p[j+2]-=
STAR_BOX;

changed=
true;

}

else if(
dz<
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


/* =========================
   RASTROS TURBO
========================= */

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

const positions=
streakGeometry
.attributes
.position
.array;


const turboFactor=
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


const streakLength=
2+
turboFactor*
20;


const move=
speedNow*
dt*
(
2.2+
turboFactor*
2.1
);


streakMaterial.opacity+=

(
turboFactor*
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


positions[b]=
data.x;


positions[b+1]=
data.y;


positions[b+2]=
data.z;


positions[b+3]=
data.x;


positions[b+4]=
data.y;


positions[b+5]=
data.z+
streakLength;

}


streakGeometry
.attributes
.position
.needsUpdate=
true;

}


/* =========================
   PLANETA
========================= */

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


/* =========================
   LUA
========================= */

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


/* =========================
   ESTAÇÃO
========================= */

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


/* =========================
   FAROL / SINAL
========================= */

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


/* =========================
   DESTROÇOS
========================= */

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


/* =========================
   CARREGAR COCKPIT
========================= */

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

},

undefined,

error=>{

console.error(

"Erro ao carregar cockpit:",

error

);

}

);


/* =========================
   ASTEROIDES
========================= */

function createIrregularAsteroidGeometry(
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
createIrregularAsteroidGeometry
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


/* =========================
   MARCADORES
========================= */

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
translate(
-50%,
-50%
);

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

transition:
opacity .12s;

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
background:rgba(30,160,210,.12);
"
>
</div>

<span>
${label}
</span>

<div
class="poi-distance"
style="
font-weight:400;
color:#d9fbff;
margin-top:2px;
"
>
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


function flashDiscovery(
name,
bonus
){

discoveryBanner.innerHTML=`

LOCAL DESCOBERTO

<br>

<span
style="
font-size:12px;
letter-spacing:2px;
color:#fff;
"
>

${name}

&nbsp;

+${bonus}

</span>

`;


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


function updatePoiMarkers(){

let nearest=
null;


let nearestDistance=
Infinity;


for(
const poi
of POIS
){

const worldPos=
new THREE.Vector3();


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

distance<
nearestDistance

){

nearest=
poi;


nearestDistance=
distance;

}


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


const margin=
40;


if(

x>
margin

&&

x<
window.innerWidth-
margin

&&

y>
margin

&&

y<
window.innerHeight-
margin

){

poi.marker.style.left=
`${x}px`;


poi.marker.style.top=
`${y}px`;


poi.marker.style.opacity=

poi.discovered

?

"0.45"

:

"1";


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


const discoveredCount=
POIS.filter(
p=>
p.discovered
)
.length;


if(
nearest
){

objectiveHud.innerHTML=`

EXPLORAÇÃO

${discoveredCount}/${POIS.length}

&nbsp; • &nbsp;

MAIS PRÓXIMO:

<b>
${nearest.name}
</b>

${Math.round(
nearestDistance
)} u

`;

}

else{

objectiveHud.innerHTML=`

EXPLORAÇÃO

${discoveredCount}/${POIS.length}

&nbsp; • &nbsp;

TODOS OS SINAIS DESCOBERTOS

`;

}

}


/* =========================
   ESTADO
========================= */

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


let gameOver=
false;


let gameStarted=
false;


let lastHitTime=
-9999;


let shake=
0;


let impactFlash=
0;


let nearMissFlash=
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


/* =========================
   MOBILE
========================= */

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


element.addEventListener(

"contextmenu",

event=>{

event.preventDefault();

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


/* =========================
   MENU
========================= */

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


hudExtra.style.opacity=
"1";


compass.style.opacity=
"1";


objectiveHud.style.opacity=
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


/* =========================
   TECLADO
========================= */

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


document
.querySelectorAll(
".mobile-btn"
)
.forEach(
button=>{

button.classList.remove(
"pressed"
);

}

);

}

);


/* =========================
   RESET
========================= */

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


impactFlash=
0;


nearMissFlash=
0;


vignette.style.opacity=
"0";


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


asteroids.forEach(
asteroid=>{

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

}

);

}


/* =========================
   DANO
========================= */

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


/* =========================
   ASTEROIDES
========================= */

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


nearMissFlash=
1;


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


/* =========================
   FREE FLIGHT
========================= */

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


/* CONTROLES CORRIGIDOS */

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


const turnAcceleration=
2.7;


const pitchAcceleration=
2.35;


const angularDamping=
Math.pow(

0.045,

dt

);


yawVelocity+=

turnInput*

turnAcceleration*

dt;


pitchVelocity+=

pitchInput*

pitchAcceleration*

dt;


yawVelocity*=
angularDamping;


pitchVelocity*=
angularDamping;


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


/* =========================
   SETORES
========================= */

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

"v1.4 EXPLORER";

}


/* =========================
   LOOP
========================= */

let previousTime=
performance.now();


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

else if(
!gameStarted
){

turbo=
false;


POIS.forEach(
poi=>{

poi.marker.style.opacity=
"0";

}

);

}


updateStreaks(

dt,

speed

);


/* MOVIMENTO VISUAL */

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


/* FOV TURBO */

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


beaconOrb.scale.setScalar(

1+

Math.sin(

currentTime*
0.006

)
*
0.12

);


wreck.rotation.y+=
dt*
0.025;


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


/* FLASH */

impactFlash=
Math.max(

0,

impactFlash-
dt*
3.8

);


nearMissFlash=
Math.max(

0,

nearMissFlash-
dt*
4.6

);


vignette.style.opacity=

Math.max(

impactFlash*
0.95,

nearMissFlash*
0.28

)
.toFixed(
2
);


/* HUD */

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


const healthColor=

health>
40

?

"#67e8ff"

:

"#ff5275";


const discoveredCount=

POIS.filter(
p=>
p.discovered
)
.length;


hudExtra.innerHTML=`

INTEGRIDADE

<b style="color:${healthColor}">
${health}%
</b>

<br>

VELOCIDADE

<b>
${Math.round(
speed
)}
</b>

<br>

DISTÂNCIA

<b>
${Math.floor(
distanceTravelled
)} u
</b>

<br>

PONTOS

<b>
${Math.floor(
score
)}
</b>

<br>

LOCAIS

<b>
${discoveredCount}/${POIS.length}
</b>

<br>

VERSÃO

<b>
1.4 EXPLORER
</b>

`;


const headingDeg=
THREE.MathUtils.radToDeg(
yaw
);


const pitchDeg=
THREE.MathUtils.radToDeg(
pitch
);


compass.innerHTML=`

${currentSector()}

<br>

X
${shipRig.position.x.toFixed(
0
)}

&nbsp;

Y
${shipRig.position.y.toFixed(
0
)}

&nbsp;

Z
${shipRig.position.z.toFixed(
0
)}

<br>

YAW
${headingDeg.toFixed(
0
)}°

&nbsp;

PITCH
${pitchDeg.toFixed(
0
)}°

`;


renderer.render(

scene,

camera

);

}


requestAnimationFrame(
animate
);


/* =========================
   RESPONSIVO
========================= */

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
