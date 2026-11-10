// Local, fictional career. No government data or remote service.
export const SAVE_KEY = 'prf-rp-career-v1';
export const WEATHER = { clear:{label:'Céu limpo',grip:1,rain:0,fog:680}, rain:{label:'Chuva / pista molhada',grip:.68,rain:1,fog:360}, fog:{label:'Neblina',grip:.86,rain:0,fog:110} };
const bounded=(v,lo,hi,f=lo)=>Number.isFinite(v)?Math.max(lo,Math.min(hi,v)):f;
export function createOperations(){return {weather:{kind:'clear',automatic:true,elapsed:0},career:{xp:0,shifts:0,rating:100,collisions:0,inspections:0,incidents:0,weighings:0,commands:0},records:[],seen:{inspection:0,incident:0,weighing:0,command:0,impact:0,day:1},destination:'base',saveStatus:'Sem salvamento neste turno',service:null};}
export function setWeather(s,kind){if(!WEATHER[kind])return false;s.operations.weather.kind=kind;s.operations.weather.automatic=false;s.operations.weather.elapsed=0;return true;}
export function addRecord(s,type,text,xp=0){const o=s.operations;o.records.unshift({type,text:String(text).slice(0,300),day:s.clock.day,minute:Math.floor(s.clock.minute)});o.records.length=Math.min(o.records.length,30);o.career.xp+=xp;}
export function updateOperations(s,dt){
 const o=s.operations,w=o.weather,c=s.car;w.elapsed+=dt;
 if(w.automatic&&w.elapsed>=180){w.kind=['clear','rain','fog'][(Math.floor(w.elapsed/180))%3];}
 c.fuel=Math.max(0,(c.fuel??100)-(s.mode==='drive'?(0.003+Math.abs(c.speed)*.001)*dt:0));
 c.doorOpen=Math.max(0,(c.doorOpen??0)-dt*.6);
 c.occupants=s.mode==='drive'?1+s.escort.boarded.length:0;
 const counts={inspection:s.completed,incident:s.copom.completed,weighing:s.weighbridge?.completed??0,command:s.command.completed,impact:s.impactSerial};
 for(const [key,n] of Object.entries(counts)){
  if(n>o.seen[key]){
   const delta=n-o.seen[key];
   if(key==='impact'){o.career.collisions+=delta;o.career.rating=Math.max(0,o.career.rating-delta*4);}
   else {const field={inspection:'inspections',incident:'incidents',weighing:'weighings',command:'commands'}[key];o.career[field]+=delta;addRecord(s,key,`${delta} ${ {inspection:'fiscalização(ões)',incident:'ocorrência(s) COPOM',weighing:'pesagem(ns)',command:'missão(ões) de comando'}[key]} concluída(s)`,delta*{inspection:15,incident:35,weighing:20,command:30}[key]);}
  }o.seen[key]=n;
 }
 if(s.clock.day>o.seen.day){o.career.shifts+=s.clock.day-o.seen.day;addRecord(s,'shift','Plantão concluído · avaliação '+o.career.rating+'%',50);o.seen.day=s.clock.day;}
}
export function careerRank(s){return s.operations.career.xp>=700?'Comando regional':s.operations.career.xp>=250?'Comando de operações':'Comando da unidade';}
export function serviceVehicle(s,kind,facility){
 if(s.paused||s.inspection||!['fuel','repair'].includes(kind)||!facility||facility.kind!==kind||Math.hypot(s.car.x-facility.x,s.car.z-facility.z)>7||Math.abs(s.car.speed)>.3)return false;
 if(kind==='fuel')s.car.fuel=100;else s.car.condition=100;
 addRecord(s,'service',kind==='fuel'?'Viatura abastecida':'Revisão e reparo da viatura concluídos');return true;
}
export function inspectionDetails(t){const irregular=t.id%4===2;return {plate:t.plate,license:'CNH válida',registration:irregular?'CRLV com pendência fictícia':'CRLV regular',equipment:irregular?'Pneu com desgaste na vistoria':'Equipamentos conferidos',result:irregular?'Pendências: registrar autuação simulada e encaminhamento':'Sem irregularidades nesta fiscalização',dialogue:irregular?'Condutor: estou levando o veículo para regularização.':'Condutor: bom dia, comandante. Seguem meus documentos.',irregular,checked:[],decision:'orient'};}
export function decideInspection(s,decision){if(!s.inspection||!['orient','fine','retain'].includes(decision))return false;s.mission.report.decision=decision;return true;}
export function recordInspection(s){const r=s.mission.report;if(!r)return;const decision={orient:'Orientação e liberação',fine:'Autuação simulada',retain:'Encaminhamento administrativo ao pátio'}[r.decision??'orient'];addRecord(s,'report',`${r.plate} · ${decision} · ${r.registration} · ${r.equipment}`);if(r.irregular&&r.decision==='orient')s.operations.career.rating=Math.max(0,s.operations.career.rating-2);}
export function saveCareer(s,storage){
 try{storage.setItem(SAVE_KEY,JSON.stringify({schema:1,career:s.operations.career,records:s.operations.records,clock:s.clock,car:{fuel:s.car.fuel,condition:s.car.condition},weather:s.operations.weather.kind,completed:{inspection:s.completed,incident:s.copom.completed,command:s.command.completed}}));s.operations.saveStatus='Carreira salva neste navegador';return true;}catch{s.operations.saveStatus='Armazenamento indisponível; turno continua sem salvar';return false;}
}
export function restoreCareer(s,storage){
 try {const raw=storage.getItem(SAVE_KEY);if(!raw||raw.length>25000)return false;const data=JSON.parse(raw);if(data.schema!==1||!data.career)return false;
 for(const key of Object.keys(s.operations.career))s.operations.career[key]=bounded(data.career[key],0,key==='rating'?100:1e7,key==='rating'?100:0);
 s.operations.records=Array.isArray(data.records)?data.records.slice(0,30).filter(r=>r&&typeof r.text==='string').map(r=>({type:String(r.type).slice(0,20),text:r.text.slice(0,300),day:bounded(r.day,1,1e5,1),minute:bounded(r.minute,0,1439)})):[];
 if(data.clock){s.clock.day=bounded(data.clock.day,1,1e5,1);s.clock.minute=bounded(data.clock.minute,0,1439,990);s.operations.seen.day=s.clock.day;}
 s.car.fuel=bounded(data.car?.fuel,0,100,100);s.car.condition=bounded(data.car?.condition,0,100,100);
 if(WEATHER[data.weather])s.operations.weather.kind=data.weather;
 s.completed=bounded(data.completed?.inspection,0,1e6);s.copom.completed=bounded(data.completed?.incident,0,1e6);s.command.completed=bounded(data.completed?.command,0,1e6);
 Object.assign(s.operations.seen,{inspection:s.completed,incident:s.copom.completed,command:s.command.completed});
 s.operations.saveStatus='Carreira retomada · novo serviço na base';return true;
 }catch{return false;}
}
export function useRepairKit(s){
 const o=s.operations;if(s.paused||s.inspection||o.career.xp<250||o.kitDay===s.clock.day||Math.abs(s.car.speed)>.3||s.car.condition>=100)return false;
 o.kitDay=s.clock.day;s.car.condition=Math.min(100,s.car.condition+20);addRecord(s,'equipment','Kit de manutenção de campo usado · +20% de integridade');return true;
}
