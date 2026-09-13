<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#02040a">
<title>LAST SECOND 3D</title>

<style>

*{
box-sizing:border-box;
margin:0;
padding:0;
}

html,body{
width:100%;
height:100%;
overflow:hidden;
background:#000;
font-family:Arial,Helvetica,sans-serif;
}

canvas{
display:block;
}

button{
font:inherit;
}

/* =========================================
   CARREGAMENTO
========================================= */

#loading{
position:fixed;
inset:0;
z-index:120;
display:flex;
align-items:center;
justify-content:center;
flex-direction:column;
gap:12px;
color:#c9f7ff;
background:
radial-gradient(
circle at center,
rgba(8,28,56,.92),
#010208 68%
);
letter-spacing:2px;
transition:opacity .5s ease;
}

#loading strong{
font-size:clamp(24px,5vw,48px);
color:#fff;
text-shadow:
0 0 20px #42d8ff;
}

#loading span{
font-size:12px;
opacity:.75;
}

/* =========================================
   MENU PRINCIPAL
========================================= */

#menu{
position:fixed;
inset:0;
z-index:70;

display:flex;
align-items:center;
justify-content:center;

overflow:hidden;

background:
radial-gradient(
circle at 50% 38%,
rgba(20,65,110,.34),
rgba(0,3,10,.82) 50%,
rgba(0,0,0,.96) 100%
);

transition:
opacity .7s ease,
visibility .7s ease;
}

#menu.hide{
opacity:0;
visibility:hidden;
pointer-events:none;
}

/* estrelas do menu */

.menu-stars,
.menu-stars::before,
.menu-stars::after{

position:absolute;
inset:-20%;

content:"";

background-image:
radial-gradient(
circle,
rgba(255,255,255,.95) 0 1px,
transparent 1.4px
);

background-size:
62px 62px;

opacity:.18;

animation:
drift 22s linear infinite;
}

.menu-stars::before{
background-size:
95px 95px;

opacity:.38;

animation-duration:
35s;

transform:
scale(1.2);
}

.menu-stars::after{
background-size:
145px 145px;

opacity:.7;

animation-duration:
52s;

transform:
scale(1.4);
}

@keyframes drift{

from{
transform:
translate3d(0,0,0);
}

to{
transform:
translate3d(-110px,85px,0);
}

}

/* brilho atrás do logo */

.menu-glow{
position:absolute;

width:min(70vw,900px);
height:min(70vw,900px);

border-radius:50%;

background:
radial-gradient(
circle,
rgba(44,165,255,.17),
rgba(32,89,170,.07) 35%,
transparent 68%
);

filter:
blur(16px);

top:50%;
left:50%;

transform:
translate(-50%,-50%);
}

/* painel central */

.menu-panel{
position:relative;
z-index:2;

width:min(520px,92vw);

padding:
44px 30px 28px;

text-align:center;

border:
1px solid
rgba(95,220,255,.22);

border-radius:
26px;

background:
linear-gradient(
180deg,
rgba(4,16,28,.48),
rgba(0,5,12,.72)
);

box-shadow:
0 0 70px rgba(43,176,255,.08),
inset 0 0 50px rgba(40,150,255,.04);

backdrop-filter:
blur(10px);
}

.kicker{
font-size:11px;
letter-spacing:5px;
color:#64dfff;
opacity:.9;
margin-bottom:12px;
}

.logo{
font-size:
clamp(44px,9vw,82px);

font-weight:900;

line-height:.9;

letter-spacing:2px;

color:#fff;

text-shadow:
0 0 10px rgba(255,255,255,.4),
0 0 35px rgba(53,205,255,.48);
}

.subtitle{
margin-top:14px;

color:#71dcff;

font-size:13px;

letter-spacing:4px;
}

.tagline{
margin:
26px auto 28px;

color:
rgba(230,248,255,.72);

font-size:12px;

letter-spacing:1.8px;
}

/* botões */

.menu-buttons{
display:flex;
flex-direction:column;

gap:11px;

width:min(340px,100%);

margin:
0 auto;
}

.menu-btn{
position:relative;

overflow:hidden;

border:
1px solid
rgba(101,221,255,.38);

border-radius:
13px;

padding:
14px 18px;

background:
rgba(3,17,28,.62);

color:
#dffbff;

letter-spacing:
2px;

font-weight:
700;

cursor:pointer;

transition:
transform .18s ease,
border-color .18s ease,
box-shadow .18s ease,
background .18s ease;
}

.menu-btn:hover{

transform:
translateY(-2px);

border-color:
rgba(122,233,255,.88);

box-shadow:
0 0 26px
rgba(57,202,255,.18);

background:
rgba(5,28,44,.82);
}

.menu-btn.primary{

padding:
17px 18px;

background:
linear-gradient(
90deg,
rgba(16,129,190,.62),
rgba(39,218,255,.23)
);

border-color:
rgba(105,232,255,.78);

box-shadow:
0 0 24px
rgba(38,196,255,.13),
inset 0 0 18px
rgba(104,227,255,.08);
}

.menu-btn.primary::after{

content:"";

position:absolute;

top:0;
left:-120%;

width:70%;
height:100%;

background:
linear-gradient(
90deg,
transparent,
rgba(255,255,255,.16),
transparent
);

transform:
skewX(-20deg);

animation:
sweep 3.2s ease-in-out infinite;
}

@keyframes sweep{

0%,55%{
left:-120%;
}

100%{
left:150%;
}

}

.menu-btn.disabled{

opacity:.42;

cursor:not-allowed;
}

.menu-footer{

display:flex;

justify-content:
space-between;

gap:12px;

margin-top:
27px;

padding-top:
17px;

border-top:
1px solid
rgba(103,221,255,.13);

font-size:
10px;

letter-spacing:
1.6px;

color:
rgba(198,239,255,.58);
}

.status-online{
color:#72efff;
}

/* =========================================
   COMO JOGAR
========================================= */

#howTo{

position:fixed;
inset:0;

z-index:90;

display:none;

align-items:center;

justify-content:center;

padding:20px;

background:
rgba(0,3,9,.82);

backdrop-filter:
blur(10px);
}

#howTo.show{
display:flex;
}

.how-panel{

width:min(520px,94vw);

padding:30px;

border:
1px solid
rgba(82,216,255,.32);

border-radius:
22px;

background:
linear-gradient(
180deg,
rgba(5,20,33,.97),
rgba(1,8,17,.97)
);

box-shadow:
0 0 50px
rgba(32,179,255,.13);

color:
#e6fbff;
}

.how-panel h2{

font-size:
24px;

letter-spacing:
2px;

margin-bottom:
18px;

color:#fff;
}

.how-panel p{

line-height:
1.8;

color:
rgba(222,247,255,.76);

font-size:
14px;

margin-bottom:
8px;
}

.key{

display:inline-block;

min-width:
56px;

padding:
5px 8px;

margin-right:
8px;

border:
1px solid
rgba(101,224,255,.35);

border-radius:
7px;

background:
rgba(7,31,48,.75);

color:#7be7ff;

text-align:center;

font-weight:700;
}

.how-close{

margin-top:
22px;

width:100%;
}

/* =========================================
   HUD
========================================= */

#hud{

position:fixed;
inset:0;

z-index:10;

pointer-events:none;

color:white;

opacity:0;

transition:
opacity .7s ease;
}

#hud.show{
opacity:1;
}

.topbar{

position:absolute;

top:18px;
left:50%;

transform:
translateX(-50%);

display:flex;

gap:24px;

align-items:center;

padding:
8px 15px;

border:
1px solid
rgba(73,211,255,.35);

border-radius:
14px;

background:
rgba(1,11,20,.35);

backdrop-filter:
blur(7px);

font-size:
12px;

letter-spacing:
1px;

white-space:
nowrap;
}

.cyan{
color:#55dcff;
}

#crosshair{

position:absolute;

width:46px;
height:46px;

left:50%;
top:47%;

transform:
translate(-50%,-50%);

border:
1px solid
rgba(104,224,255,.55);

border-radius:
50%;

box-shadow:
0 0 18px
rgba(41,207,255,.18);
}

#crosshair::before,
#crosshair::after{

content:"";

position:absolute;

background:
rgba(117,230,255,.9);
}

#crosshair::before{

width:14px;
height:1px;

left:15px;
top:22px;
}

#crosshair::after{

width:1px;
height:14px;

left:22px;
top:15px;
}

.instructions{

position:absolute;

left:50%;
bottom:20px;

transform:
translateX(-50%);

font-size:
11px;

letter-spacing:
.8px;

color:
rgba(220,246,255,.72);

text-align:center;

white-space:
nowrap;
}

#error{

display:none;

position:fixed;

inset:0;

z-index:200;

padding:30px;

align-items:center;

justify-content:center;

text-align:center;

background:#05060a;

color:white;

line-height:1.6;
}

@media(max-width:600px){

.menu-panel{
padding:
34px 20px 24px;
}

.menu-footer{
flex-direction:
column;
}

.topbar{
gap:10px;
font-size:10px;
}

.instructions{
font-size:9px;
}

.logo{
font-size:54px;
}

}

</style>
</head>

<body>

<div id="loading">

<strong>
LAST SECOND
</strong>

<div>
INICIALIZANDO SISTEMA 3D
</div>

<span>
DEEP SPACE PROTOTYPE
</span>

</div>

<!-- MENU -->

<div id="menu">

<div class="menu-stars"></div>

<div class="menu-glow"></div>

<div class="menu-panel">

<div class="kicker">
DEEP SPACE SURVIVAL
</div>

<div class="logo">
LAST<br>
SECOND
</div>

<div class="subtitle">
NO SECOND CHANCE
</div>

<div class="tagline">
SOBREVIVA. DESVIE. NÃO HÁ SEGUNDA CHANCE.
</div>

<div class="menu-buttons">

<button
id="startBtn"
class="menu-btn primary">

INICIAR VOO

</button>

<button
id="howBtn"
class="menu-btn">

COMO JOGAR

</button>

<button
class="menu-btn disabled"
title="Em breve">

CONFIGURAÇÕES — EM BREVE

</button>

</div>

<div class="menu-footer">

<span>
SETOR ALPHA-01
</span>

<span class="status-online">
● SISTEMA ONLINE
</span>

<span>
v1.1 MENU BUILD
</span>

</div>

</div>

</div>

<!-- COMO JOGAR -->

<div id="howTo">

<div class="how-panel">

<h2>
COMO JOGAR
</h2>

<p>
<span class="key">
WASD
</span>
Manobrar a nave
</p>

<p>
<span class="key">
SETAS
</span>
Também controlam a nave
</p>

<p>
<span class="key">
SHIFT
</span>
Ativar turbo
</p>

<p>
<span class="key">
R
</span>
Reiniciar após destruição
</p>

<p style="margin-top:16px">

Desvie dos asteroides,
passe raspando para ganhar
pontos extras e preserve
a integridade da nave.

</p>

<button
id="closeHowBtn"
class="menu-btn how-close">

VOLTAR

</button>

</div>

</div>

<!-- HUD -->

<div id="hud">

<div class="topbar">

<span>
VELOCIDADE
<b class="cyan" id="speedText">
1.0x
</b>
</span>

<span>
SETOR
<b class="cyan">
ALPHA-01
</b>
</span>

<span>
SISTEMA
<b class="cyan">
ONLINE
</b>
</span>

</div>

<div id="crosshair"></div>

<div class="instructions">

WASD / SETAS = MANOBRAR
•
SHIFT = TURBO
•
R = REINICIAR

</div>

</div>

<div id="error">

Não consegui carregar o motor 3D.

<br>

Confira se o computador está conectado
à internet e abra novamente no Chrome.

</div>

<script src="main.js"></script>

</body>
</html>
