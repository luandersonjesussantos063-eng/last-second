// Operação COPOM visível, interativa e exclusivamente fictícia.
// Estado determinístico: patrulha, isolamento, inspeção, apoio, guincho e relatório.
const distance=(a,b)=>Math.hypot(a.x-b.x,a.z-b.z);
const stepTo=(o,dest,speed,dt)=>{
 const dx=dest.x-o.x,dz=dest.z-o.z,dist=Math.hypot(dx,dz);
 if(dist<0.1){o.x=dest.x;o.z=dest.z;return true;}
 const walk=Math.min(dist,speed*dt);
 o.x+=dx/dist*walk;o.z+=dz/dist*walk;
 o.heading=Math.atan2(dx,dz);
 return dist<=walk+0.1;
};
const messages={
 arrival:"Chegada confirmada. Saia da viatura e isole a área [F].",
 secured:"Cones posicionados. Procure o condutor ou verifique o objeto [F].",
 surveyed:"Vistoria registrada. Aguarde a equipe e coordene o atendimento [F].",
 towCalled:"Guincho chamado. Aguarde o caminhão chegar à área sinalizada.",
 towReady:"Guincho posicionado. Autorize o recolhimento [F].",
 recovering:"Guincho removendo o veículo. Mantenha a área sinalizada.",
 clearing:"Equipe recolhendo o objeto e conferindo o acostamento.",
 resolved:"Área liberada. Pressione F para transmitir o encerramento ao COPOM."
};
export function createIncident(){
 return {
  stage:"inactive",active:false,kind:"vehicle",site:{x:0,z:0},taskId:"",
  progress:0,actions:[],lastStageAt:0,driver:{x:0,z:0,visible:false,action:"wait"},
  support:{stage:"idle",x:0,z:0,heading:0,speed:0,lights:false,since:0},
  agents:[0,1].map(i=>({id:i,x:0,z:0,heading:0,visible:false,action:"radio",moving:false})),
  tow:{stage:"idle",x:0,z:0,heading:0,speed:0,visible:false,since:0},
  vehicle:{x:0,z:0,visible:false,heading:0},
  debris:{x:0,z:0,visible:false},cleared:false
 };
}
function notice(s,msg){
 s.notice="COPOM · "+msg;s.noticeUntil=s.time+6;
}
function journal(s,text){
 const i=s.incident;i.actions.unshift({text,time:Math.round(s.time)});
 i.actions.length=Math.min(i.actions.length,8);
 notice(s,text);
}
export function beginIncident(s,task){
 const i=s.incident,vehicle=task.id==="COP-001",at={x:task.x,z:task.z};
 Object.assign(i,{active:true,stage:"dispatched",kind:vehicle?"vehicle":"debris",
  site:at,taskId:task.id,progress:0,actions:[],cleared:false,lastStageAt:s.time,
  driver:{x:at.x+2.1,z:at.z+2.7,visible:vehicle,action:"wait"},
  support:{stage:"idle",x:at.x,z:at.z-100,heading:0,speed:0,lights:false,since:0},
  agents:[0,1].map(n=>({id:n,x:at.x,z:at.z-100,heading:0,visible:false,action:"radio",moving:false})),
  tow:{stage:"idle",x:at.x,z:at.z-145,heading:0,speed:0,visible:false,since:0},
  vehicle:{x:at.x,z:at.z+1.4,visible:vehicle,heading:Math.PI},
  debris:{x:at.x+0.8,z:at.z,visible:!vehicle},
 });
 journal(s,"Equipe despachada para "+task.title+". Local sinalizado no HUD.");
}
export function incidentActionLabel(s) {
 const i=s.incident;
 if(!i.active||s.paused||s.inspection||s.mode!=="foot"||
    s.copom.stage!=="on_scene"||distance(s.player,i.site)>13)return "";
 switch(i.stage){
 case "arrival":return "ISOLAR CENA · COLOCAR CONES [F]";
 case "secured":return i.kind==="vehicle"?"OUVIR CONDUTOR E INSPECIONAR [F]":"AVALIAR OBSTÁCULO NA PISTA [F]";
 case "surveyed":
   if(i.support.stage!=="deployed")return "";
   return i.kind==="vehicle"?"SOLICITAR GUINCHO [F]":"RETIRAR OBSTÁCULO COM APOIO [F]";
 case "towReady":return "AUTORIZAR REMOÇÃO AO PÁTIO [F]";
 default:return "";
 }
}
export function incidentInteract(s) {
 const i=s.incident;
 if(!incidentActionLabel(s))return false;
 if(i.stage==="arrival"){
  i.stage="secured";i.progress=1;
  i.support.stage="enroute";i.support.since=s.time;i.support.lights=true;
  journal(s,"Isolamento colocado. Viatura de apoio deslocando-se ao local.");
 }else if(i.stage==="secured"){
  i.stage="surveyed";i.progress=2;i.driver.action="talk";
  journal(s,i.kind==="vehicle"
   ?"Condutor orientado: veículo com falha mecânica e aguardando retirada."
   :"Objeto identificado. Controle o trânsito enquanto a equipe chega.");
 }else if(i.stage==="surveyed"){
  if(i.kind==="vehicle"){
   i.stage="towCalled";i.progress=3;i.tow.stage="enroute";i.tow.visible=true;i.tow.since=s.time;
   journal(s,"Guincho solicitado pelo rádio; mantenha o isolamento.");
  }else{
   i.stage="clearing";i.progress=3;i.lastStageAt=s.time;
   journal(s,"Equipe iniciou retirada do obstáculo com sinalização.");
  }
 }else if(i.stage==="towReady"){
  i.stage="recovering";i.progress=4;i.tow.stage="recovery";i.lastStageAt=s.time;
  i.driver.action="safe";
  journal(s,"Guincho acoplado. Iniciada remoção simulada ao pátio.");
 }else return false;
 return true;
}
export function updateIncident(s,dt){
 const i=s.incident;
 if(!i.active)return;
 if(s.copom.stage==="complete"){
  // A cena sai do mapa após encerramento, preservando apenas o registro COPOM.
  i.active=false;i.stage="closed";i.support.lights=false;
  return;
 }
 if(s.copom.stage==="on_scene" && i.stage==="dispatched"){
  i.stage="arrival";i.lastStageAt=s.time;
  notice(s,messages.arrival);
 }
 const sup=i.support,site=i.site;
 if(sup.stage==="enroute"){
  sup.speed=12;sup.lights=true;
  if(stepTo(sup,{x:site.x-0.1,z:site.z-15},12,dt)){
   sup.stage="onScene";sup.since=s.time;sup.speed=0;
   i.agents.forEach((a,n)=>{
    a.x=sup.x+(n?1.8:-1.8);a.z=sup.z-1.5;a.visible=true;a.moving=true;
   });
   journal(s,"Apoio chegou! Dois policiais desembarcaram para sinalização.");
  }
 }else if(sup.stage==="onScene"){
  let ready=true;
  for(const a of i.agents){
   const target={x:site.x+(a.id?1.9:-1.8),z:site.z+(a.id?7:-5)};
   const arrived=stepTo(a,target,1.65,dt);
   a.moving=!arrived;a.action=arrived?a.id?"documents":"signal":"walk";
   if(!arrived)ready=false;
  }
  if(ready){
   sup.stage="deployed";
   journal(s,"Agentes no posto: um sinaliza o tráfego e outro acompanha o atendimento.");
  }
 }else if(sup.stage==="deployed"){
  i.agents.forEach(a=>{a.moving=false;a.action=a.id?"documents":"signal";});
 }
 const tow=i.tow;
 if(tow.stage==="enroute"){
  tow.speed=14;
  if(stepTo(tow,{x:site.x-0.2,z:site.z-8},14,dt)){
   tow.speed=0;tow.stage="ready";i.stage="towReady";
   journal(s,"Guincho chegou e aguarda autorização para remoção.");
  }
 }else if(tow.stage==="recovery"){
  tow.speed=6;
  const elapsed=s.time-i.lastStageAt;
  if(elapsed>2) {
   stepTo(tow,{x:site.x-0.1,z:site.z+94},7,dt);
   i.vehicle.x=tow.x;i.vehicle.z=tow.z-5.4;i.vehicle.heading=0;
  }
  if(elapsed>=18){
   tow.stage="gone";tow.visible=false;tow.speed=0;
   i.vehicle.visible=false;i.stage="resolved";i.progress=5;
   journal(s,"Veículo removido do acostamento. Trecho seguro e liberado.");
  }
 }
 if(i.stage==="clearing" && s.time-i.lastStageAt>8){
  i.debris.visible=false;i.cleared=true;i.stage="resolved";i.progress=5;
  journal(s,"Objeto retirado. Acostamento liberado para circulação.");
 }
}
export function incidentSummary(s){
 const i=s.incident;
 if(!i.active||s.copom.stage==="available"||s.copom.stage==="complete")return null;
 const label=messages[i.stage]??"Deslocamento até a ocorrência.";
 const dist=Math.round(distance(s.mode==="drive"?s.car:s.player,i.site));
 const status=i.stage==="surveyed" && i.support.stage!=="deployed"
  ?"Apoio a caminho ou desembarcando · aguarde na área isolada."
  :label;
 const stageName={
  dispatched:"DESLOCAMENTO",arrival:"LOCALIZAR E ISOLAR",secured:"COLETAR INFORMAÇÕES",
  surveyed:"AGUARDAR APOIO",towCalled:"GUINCHO A CAMINHO",towReady:"REMOVER VEÍCULO",
  recovering:"REMOÇÃO EM ANDAMENTO",clearing:"LIMPEZA DA PISTA",resolved:"ENCERRAR CHAMADO"
 }[i.stage]??"OPERAÇÃO";
 return {title:"COPOM · "+stageName,description:status,dist,progress:i.progress,
  support:i.support.stage,agents:i.agents.filter(a=>a.visible).length,
  log:i.actions[0]?.text??"",completed:i.stage==="resolved"};
}
export function incidentTrafficMultiplier(s,t){
 const i=s.incident;
 if(!i.active || ["dispatched","closed","resolved"].includes(i.stage))return 1;
 const ahead=(i.site.z-t.z)*t.direction;
 if(ahead<0||ahead>110)return 1;
 // Lentidão progressiva pela intervenção, independentemente da existência de diálogo.
 return ahead<25?0.42:ahead<60?0.56:0.78;
}
