// Balança de cargas demonstrativa do PRF RP. Massas e limites FICTÍCIOS.
const scale={x:-9.2,z:-520};
const weights=[51600,40800,47250,43980];
export function createWeighbridge(){
 return {
  x:scale.x,z:scale.z,stage:"ready",grossKg:weights[0],
  referenceKg:45000,sequence:0,completed:0,report:null,history:[],
  truck:{x:scale.x,z:scale.z,heading:Math.PI,speed:0,visible:true},
  nextAt:0
 };
}
export function platformOccupied(w){return !!w.truck.visible && Math.abs(w.truck.x-w.x)<2.6 && Math.abs(w.truck.z-w.z)<9 && Math.abs(w.truck.speed)<0.5 && w.stage!=="released";}
export function configureReference(s,kg){const w=s.weighbridge;if(s.paused||s.inspection||w.stage!=="ready"||!Number.isSafeInteger(kg)||kg<10000||kg>100000)return false;w.referenceKg=kg;return true;}
export function weighbridgePanel(s){const w=s.weighbridge,occupied=platformOccupied(w);return {occupied,stage:w.stage,grossKg:occupied?w.grossKg:null,referenceKg:w.referenceKg,excessKg:occupied?Math.max(0,w.grossKg-w.referenceKg):null,plate:occupied?"SIM-CARGA-"+(2000+w.sequence):null,report:w.report,completed:w.completed,canWeigh:!!weighbridgeActionLabel(s),history:w.history};}
const near=s=>s.mode==="foot"&&Math.hypot(s.player.x-s.weighbridge.x,
  s.player.z-s.weighbridge.z)<9;
export function weighbridgeActionLabel(s){
 if(s.paused||s.inspection||!near(s))return "";
 if(s.weighbridge.stage==="ready" && platformOccupied(s.weighbridge))return "PESAR CAMINHÃO NA BALANÇA [F]";
 if(s.weighbridge.stage==="weighed" && platformOccupied(s.weighbridge))return "REGISTRAR RESULTADO DA PESAGEM [F]";
 return "";
}
export function interactWeighbridge(s){
 const w=s.weighbridge,action=weighbridgeActionLabel(s);
 if(!action||w.stage==="released")return false;
 if(w.stage==="ready"){
  if(!platformOccupied(w))return false;
  w.stage="weighed";
  w.report={grossKg:w.grossKg,referenceKg:w.referenceKg,
   differenceKg:Math.max(0,w.grossKg-w.referenceKg),
   plate:"SIM-CARGA-"+(2000+w.sequence),sequence:w.sequence+1,
   description:w.grossKg>w.referenceKg
    ?"Excesso comparado à referência fictícia desta balança"
    :"Massa dentro da referência fictícia do simulador"};
  s.notice="BALANÇA: "+w.grossKg.toLocaleString("pt-BR")+" kg · confira e registre o resultado.";
  s.noticeUntil=s.time+7;
 }else if(w.stage==="weighed"){
  w.stage="released";w.completed++;w.nextAt=s.time+13;
  w.history.unshift({...w.report,time:Math.round(s.time)});
  w.history.length=Math.min(w.history.length,8);
  s.notice="PESAGEM REGISTRADA: "+w.report.plate+" · "+
    (w.report.differenceKg?"excesso simulado "+w.report.differenceKg+" kg":"dentro da referência");
  s.noticeUntil=s.time+9;
 }
 return true;
}
export function updateWeighbridge(s,dt) {
 const w=s.weighbridge;
 if(w.stage==="released"){
  w.truck.speed=5.5;
  w.truck.z-=5.5*dt;
  if(s.time>=w.nextAt && Math.abs(w.truck.z-w.z)>60) {
   w.sequence++;w.grossKg=weights[w.sequence%weights.length];
   w.truck.z=w.z;w.truck.speed=0;w.truck.visible=true;
   w.stage="ready";w.report=null;
  }
 }
}
export function weighbridgeSummary(s){
 const w=s.weighbridge,observer=s.mode==="drive"?s.car:s.player;
 const dist=Math.round(Math.hypot(w.x-observer.x,w.z-observer.z));
 return {distance:dist,visible:dist<220,stage:w.stage,weight:w.grossKg,
  count:w.completed,report:w.report};
}
