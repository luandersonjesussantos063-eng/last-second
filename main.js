(async()=>{

try{

const THREE=
await import(
"https://esm.sh/three@0.186.0"
);

const {
GLTFLoader
}=
await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/GLTFLoader.js"
);

const {
DRACOLoader
}=
await import(
"https://esm.sh/three@0.186.0/examples/jsm/loaders/DRACOLoader.js"
);

const $=
id=>
document.getElementById(id);

const loading=$("loading");
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

/* CENA */

const scene=
new THREE.Scene();

scene.background=
new THREE.Color(
0x01030a
);

scene.fog=
new THREE.FogExp2(
0x01030a,
0.0032
);

/* CÂMERA */

const camera=
new THREE.PerspectiveCamera(

85,

window.innerWidth /
window.innerHeight,

0.01,

1400

);

camera.rotation.order=
"YXZ";

/* RENDERER */

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

/* COCKPIT */

const COCKPIT_CAMERA={

x:-0.082,

y:-62.874,

z:27.989,

pitch:0,

yaw:Math.PI,

fov:85

};

camera.position.set(

COCKPIT_CAMERA.x,

COCKPIT_CAMERA.y,

COCKPIT_CAMERA.z

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

/* MUNDO */

const world=
new THREE.Group();

scene.add(
world
);

/* ILUMINAÇÃO */

scene.add(

new THREE.HemisphereLight(

0xbadfff,

0x05070c,

1.7

)

);

const cockpitLight=
new THREE.PointLight(

0x40d9ff,

10,

30

);

cockpitLight.position.set(

COCKPIT_CAMERA.x,

COCKPIT_CAMERA.y + 2,

COCKPIT_CAMERA.z + 6

);

scene.add(
cockpitLight
);

const warmFill=
new THREE.PointLight(

0xff6a4d,

5,

22

);

warmFill.position.set(

COCKPIT_CAMERA.x + 4,

COCKPIT_CAMERA.y - 1,

COCKPIT_CAMERA.z + 4

);

scene.add(
warmFill
);

const sunLight=
new THREE.DirectionalLight(

0xffffff,

3.5

);

sunLight.position.set(

-10,

14,

-8

);

scene.add(
sunLight
);

/* HUD EXTRA */

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
190px;

opacity:0;

transition:
opacity .7s ease;

`;

document.body.appendChild(
hudExtra
);

/* AVISO */

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
700 22px Arial,sans-serif;

letter-spacing:
3px;

text-shadow:
0 0 15px rgba(255,50,90,.65);

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

/* FLASH IMPACTO */

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
rgba(255,255,255,0) 45%,
rgba(255,50,80,.08) 75%,
rgba(255,30,60,.28) 100%
);

transition:
opacity .08s linear;

`;

document.body.appendChild(
vignette
);

/* FLASH TURBO */

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

/* UTILIDADE */

function random(
min,
max
){

return (

min +

Math.random() *

(max-min)

);

}

/* ESTRELAS */

const STAR_COUNT=
3200;

const starGeometry=
new THREE.BufferGeometry();

const starPositions=
new Float32Array(
STAR_COUNT * 3
);

function respawnStar(
i,
first=false
){

const j=
i * 3;

starPositions[j]=
COCKPIT_CAMERA.x +
random(
-120,
120
);

starPositions[j+1]=
COCKPIT_CAMERA.y +
random(
-85,
85
);

starPositions[j+2]=

COCKPIT_CAMERA.z +

random(

first
?
20
:
470,

first
?
560
:
580

);

}

for(
let i=0;
i<STAR_COUNT;
i++
){

respawnStar(
i,
true
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
0.16,

transparent:
true,

opacity:
0.88,

sizeAttenuation:
true

})

);

world.add(
stars
);

/* RASTROS */

const STREAK_COUNT=
520;

const streakGeometry=
new THREE.BufferGeometry();

const streakPositions=
new Float32Array(
STREAK_COUNT * 6
);

const streakData=[];

function resetStreak(
i,
first=false
){

streakData[i]={

x:
COCKPIT_CAMERA.x +
random(
-95,
95
),

y:
COCKPIT_CAMERA.y +
random(
-60,
60
),

z:
COCKPIT_CAMERA.z +
random(

first
?
45
:
430,

first
?
520
:
560

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

world.add(
streaks
);

/* PLANETA */

const planet=
new THREE.Mesh(

new THREE.SphereGeometry(

18,

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

COCKPIT_CAMERA.x - 44,

COCKPIT_CAMERA.y + 24,

COCKPIT_CAMERA.z + 250

);

world.add(
planet
);

/* ATMOSFERA */

const atmosphere=
new THREE.Mesh(

new THREE.SphereGeometry(

19.4,

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

80,

200

);

planetGlow.position
.copy(
planet.position
)
.add(

new THREE.Vector3(

10,

8,

-8

)

);

world.add(
planetGlow
);

/* CARREGAMENTO DO MODELO */

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

(gltf)=>{

const cockpit=
gltf.scene;

cockpit.traverse(
(child)=>{

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
(material)=>{

if(
material
){

material.needsUpdate=
true;

}

});

});

scene.add(
cockpit
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

12 /

(
Math.max(

size.x,

size.y,

size.z

)

|| 1
)

);

if(
loading
){

loading.innerHTML=`

<strong>
LAST SECOND
</strong>

<div>
V1.1.2 ONLINE
</div>

<span>
MOBILE CONTROL READY
</span>

`;

setTimeout(
()=>{

loading.style.opacity=
"0";

setTimeout(
()=>{

loading.style.display=
"none";

},
450
);

},
350
);

}

},

(progress)=>{

if(
!loading ||
!progress.total
){

return;

}

const pct=
Math.round(

progress.loaded /
progress.total *

100

);

loading.innerHTML=`

<strong>
LAST SECOND
</strong>

<div>
CARREGANDO V1.1.2
${pct}%
</div>

<span>
MENU SYSTEM
</span>

`;

},

(error)=>{

console.error(

"Erro ao carregar cockpit:",

error

);

if(
loading
){

loading.innerHTML=`

<strong>
LAST SECOND
</strong>

<div style="color:#ff4267">

ERRO NO COCKPIT

</div>

<span>

Abra F12 → Console

</span>

`;

}

}

);

/* ASTEROIDES */

function createIrregularAsteroidGeometry(
seed=0
){

const geometry=
new THREE.IcosahedronGeometry(

1,

2

);

const position=
geometry.attributes.position;

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

0.78 +

Math.sin(

i * 12.9898 +

seed * 9.7

) * 0.12 +

Math.cos(

i * 4.123 +

seed * 5.1

) * 0.08 +

Math.random() * 0.08;

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

color:
color,

roughness:
0.96,

metalness:
0.02

});

}

function respawnAsteroid(
asteroid,
first=false
){

asteroid.position.x=

COCKPIT_CAMERA.x +

random(
-19,
19
);

asteroid.position.y=

COCKPIT_CAMERA.y +

random(
-12,
12
);

asteroid.position.z=

COCKPIT_CAMERA.z +

random(

first
?
60
:
260,

first
?
340
:
380

);

const scale=
random(
0.9,
3.7
);

asteroid.scale.set(

scale *
random(
0.86,
1.18
),

scale *
random(
0.84,
1.16
),

scale *
random(
0.86,
1.2
)

);

asteroid.userData.radius=
scale * 0.9;

asteroid.userData.spinX=
random(
-0.85,
0.85
);

asteroid.userData.spinY=
random(
-0.85,
0.85
);

asteroid.userData.spinZ=
random(
-0.85,
0.85
);

asteroid.userData.nearPassed=
false;

}

for(
let i=0;
i<44;
i++
){

const asteroid=
new THREE.Mesh(

asteroidGeometries[
i %
asteroidGeometries.length
],

makeAsteroidMaterial()

);

respawnAsteroid(

asteroid,

true

);

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

4.6

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

/* ESTADO DO JOGO */

const keys=
new Set();

let targetX=0;
let targetY=0;

let shipX=0;
let shipY=0;

let speed=22;

let turbo=false;

let health=100;

let score=0;

let gameOver=false;

let gameStarted=false;

let lastHitTime=
-9999;

let shake=0;

let impactFlash=0;

let nearMissFlash=0;

/* CONTROLES MOBILE */

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
press
);

element.addEventListener(
"pointerup",
release
);

element.addEventListener(
"pointercancel",
release
);

element.addEventListener(
"lostpointercapture",
release
);

element.addEventListener(

"contextmenu",

(event)=>{

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

/* MENU */

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

howTo.addEventListener(

"click",

(event)=>{

if(
event.target === howTo
){

howTo.classList.remove(
"show"
);

}

}

);

/* TECLADO */

window.addEventListener(

"keydown",

(event)=>{

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

(event)=>{

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
(button)=>{

button.classList.remove(
"pressed"
);

}

);

}

);

/* RESET */

function resetGame(){

health=
100;

score=
0;

speed=
22;

shipX=
0;

shipY=
0;

targetX=
0;

targetY=
0;

gameOver=
false;

world.position.set(

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

asteroids.forEach(
(asteroid)=>{

respawnAsteroid(

asteroid,

true

);

}

);

warning.textContent=
"COLISÃO";

warning.style.opacity=
"0";

}

/* DANO */

function hitPlayer(){

const now=
performance.now();

if(

now -
lastHitTime

<
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

health - 20

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
health <= 0
){

gameOver=
true;

warning.textContent=

"SISTEMA CRÍTICO — R PARA REINICIAR";

warning.style.opacity=
"1";

}

}

/* ATUALIZA ESTRELAS */

function updateStars(
dt,
worldSpeed
){

const positions=

starGeometry
.attributes
.position
.array;

const step=

worldSpeed *

dt *

2.5;

for(
let i=0;
i<STAR_COUNT;
i++
){

const j=
i * 3;

positions[
j+2
] -= step;

if(

positions[
j+2
]

<

COCKPIT_CAMERA.z - 5

){

respawnStar(

i,

false

);

}

}

starGeometry
.attributes
.position
.needsUpdate=
true;

}

/* ATUALIZA RASTROS */

function updateStreaks(
dt,
worldSpeed
){

const positions=

streakGeometry
.attributes
.position
.array;

const turboFactor=

THREE.MathUtils.clamp(

(
worldSpeed - 22
)

/
28,

0,

1

);

const streakLength=

2 +

turboFactor * 18;

const move=

worldSpeed *

dt *

(
2.4 +

turboFactor * 1.8
);

streakMaterial.opacity +=

(
turboFactor * 0.75

-

streakMaterial.opacity
)

*

Math.min(

1,

dt * 7

);

for(
let i=0;
i<STREAK_COUNT;
i++
){

const data=
streakData[i];

data.z -=
move;

if(

data.z <

COCKPIT_CAMERA.z - 4

){

resetStreak(

i,

false

);

}

const base=
i * 6;

positions[
base
]=
data.x;

positions[
base+1
]=
data.y;

positions[
base+2
]=
data.z;

positions[
base+3
]=
data.x;

positions[
base+4
]=
data.y;

positions[
base+5
]=

data.z +

streakLength;

}

streakGeometry
.attributes
.position
.needsUpdate=
true;

}

/* ATUALIZA ASTEROIDES */

function updateAsteroids(
dt,
worldSpeed
){

for(
const asteroid of asteroids
){

asteroid.position.z -=

worldSpeed *

dt;

asteroid.rotation.x +=

asteroid.userData.spinX *

dt;

asteroid.rotation.y +=

asteroid.userData.spinY *

dt;

asteroid.rotation.z +=

asteroid.userData.spinZ *

dt;

const visibleX=

asteroid.position.x +

world.position.x;

const visibleY=

asteroid.position.y +

world.position.y;

const dz=

asteroid.position.z -

COCKPIT_CAMERA.z;

if(

asteroid.position.z

<

COCKPIT_CAMERA.z - 8

){

respawnAsteroid(

asteroid,

false

);

score +=
10;

continue;

}

const dx=

visibleX -

COCKPIT_CAMERA.x;

const dy=

visibleY -

COCKPIT_CAMERA.y;

const lateralDist=

Math.hypot(

dx,

dy

);

/* RASPANDO */

if(

!asteroid.userData.nearPassed

&&

dz > 0

&&

dz < 9

&&

lateralDist >

asteroid.userData.radius +
1.3

&&

lateralDist <

asteroid.userData.radius +
4.2

){

asteroid.userData.nearPassed=
true;

nearMissFlash=
1;

score +=
15;

}

/* COLISÃO */

if(

dz > -2

&&

dz < 5

){

const radius=

asteroid.userData.radius +

1.15;

if(

dx * dx +

dy * dy

<

radius * radius

){

hitPlayer();

respawnAsteroid(

asteroid,

false

);

}

}

}

}

/* LOOP */

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
currentTime -
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

if(
!gameOver
){

const controlSpeed=
1.5;

targetX +=

(
(
right ? 1 : 0
)

-

(
left ? 1 : 0
)
)

*

controlSpeed *

dt;

targetY +=

(
(
up ? 1 : 0
)

-

(
down ? 1 : 0
)
)

*

controlSpeed *

dt;

targetX *=

Math.pow(

0.34,

dt

);

targetY *=

Math.pow(

0.34,

dt

);

targetX=

THREE.MathUtils.clamp(

targetX,

-1,

1

);

targetY=

THREE.MathUtils.clamp(

targetY,

-1,

1

);

shipX +=

(
targetX -
shipX
)

*

Math.min(

1,

dt * 5.5

);

shipY +=

(
targetY -
shipY
)

*

Math.min(

1,

dt * 5.5

);

const targetSpeed=

turbo

?

50

:

22;

speed +=

(
targetSpeed -
speed
)

*

Math.min(

1,

dt * 3.8

);

score +=

speed *

dt *

0.22;

world.position.x +=

(
-shipX * 9

-

world.position.x
)

*

Math.min(

1,

dt * 5

);

world.position.y +=

(
-shipY * 6

-

world.position.y
)

*

Math.min(

1,

dt * 5

);

updateStars(

dt,

speed

);

updateStreaks(

dt,

speed

);

updateAsteroids(

dt,

speed

);

}

}

else{

turbo=
false;

}

/* MOVIMENTO VISUAL */

const bank=

gameStarted

?

-shipX * 0.078

:

0;

const flightPitch=

gameStarted

?

shipY * 0.042

:

0;

const bob=

Math.sin(

currentTime *

(
gameStarted
?
0.0017
:
0.0012
)

)

*

(
gameStarted
?
0.012
:
0.005
);

let shakeX=
0;

let shakeY=
0;

if(
shake > 0
){

shake=

Math.max(

0,

shake -

dt * 1.9

);

shakeX=

(
Math.random() -
0.5
)

*

shake *

0.2;

shakeY=

(
Math.random() -
0.5
)

*

shake *

0.15;

}

camera.position.set(

COCKPIT_CAMERA.x +
shakeX,

COCKPIT_CAMERA.y +
bob +
shakeY,

COCKPIT_CAMERA.z

);

camera.rotation.set(

COCKPIT_CAMERA.pitch +
flightPitch,

COCKPIT_CAMERA.yaw,

bank,

"YXZ"

);

/* TURBO */

const desiredFov=

gameStarted

&&

turbo

?

94

:

COCKPIT_CAMERA.fov;

camera.fov +=

(
desiredFov -

camera.fov
)

*

Math.min(

1,

dt * 3.6

);

camera.updateProjectionMatrix();

planet.rotation.y +=

dt * 0.022;

atmosphere.rotation.y -=

dt * 0.01;

const turboAmount=

gameStarted

?

THREE.MathUtils.clamp(

(
speed - 22
)

/
28,

0,

1

)

:

0;

turboFlash.style.opacity=

(
turboAmount * 0.9
)
.toFixed(
2
);

cockpitLight.intensity=

10 +

turboAmount * 7;

renderer.toneMappingExposure=

1.18 +

turboAmount * 0.12;

/* FLASHES */

impactFlash=

Math.max(

0,

impactFlash -

dt * 3.8

);

nearMissFlash=

Math.max(

0,

nearMissFlash -

dt * 4.6

);

vignette.style.opacity=

Math.max(

impactFlash * 0.95,

nearMissFlash * 0.28

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
speed /
22
).toFixed(
1
)}x`;

}

const healthColor=

health > 40

?

"#67e8ff"

:

"#ff5275";

hudExtra.innerHTML=`

INTEGRIDADE

<b style="color:${healthColor}">

${health}%

</b>

<br>

PONTOS

<b>

${Math.floor(
score
)}

</b>

<br>

PROPULSÃO

<b>

${
turbo
?
"TURBO"
:
"NORMAL"
}

</b>

<br>

VERSÃO

<b>

1.1.2

</b>

`;

renderer.render(

scene,

camera

);

}

requestAnimationFrame(
animate
);

/* RESPONSIVO */

window.addEventListener(

"resize",

()=>{

camera.aspect=

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

catch(
error
){

console.error(
error
);

const loading=
document.getElementById(
"loading"
);

if(
loading
){

loading.innerHTML=`

<strong>
LAST SECOND
</strong>

<div style="color:#ff4267">

ERRO NO SISTEMA 3D

</div>

<span>

Abra F12 → Console

</span>

`;

}

}

})();
