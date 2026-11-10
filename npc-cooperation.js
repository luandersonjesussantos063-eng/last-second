// Cooperação local: policiais decidem ajudar colegas e saem fisicamente do posto.
// Não usa API, não cria missões reais e nunca substitui ordens do jogador.
import { rememberNpc } from "./npc-intelligence.js?v=2.21.0";
const POINTS = {
  1: {to:[[38,22],[36,22],[34,22]],back:[[36,22],[38,22]]},
  7: {to:[[12,-10],[15,-6],[16,-2]],back:[[15,-6],[12,-10],[10.4,-12]]},
  8: {to:[[21,5],[24,4],[26,4]],back:[[24,4],[21,5],[21.5,9]]},
};
const copyPath=path=>path.map(pair=>[...pair]);
const waiting=s=>s.reception.visitors.filter(v=>v.state==="queue").length;
const emergency=s=>["pursuit","detained"].includes(s.life.evasion.stage);
function planFor(s,agent) {
  const id=agent.id, day=s.clock.day;
  if(id===1 && waiting(s)>=3) return {
    key:"queue:"+day+":"+Math.floor(s.time/95),
    type:"queue", approach:"Indo reforçar a fila da recepção",
    working:"Apoiando atendimento de cidadãos",action:"typing",duration:12,
    report:"Reforço realizado na recepção",
  };
  if(id===7) {
    if(emergency(s)) return {
      key:"evasion:"+s.life.evasion.vehicleId+":"+s.life.evasion.completed,
      type:"radio",approach:"Deslocando-se para coordenar a ocorrência",
      working:"Coordenando equipes pelo rádio",action:"radio",duration:9,
      report:"Evasão acompanhada e equipes informadas",
    };
    if(["dispatched","on_scene"].includes(s.copom.stage)) return {
      key:"copom:"+s.copom.index+":"+s.copom.start,
      type:"radio",approach:"Indo transmitir orientações COPOM",
      working:"Transmitindo informações da ocorrência",action:"radio",duration:8,
      report:"Atualização do COPOM transmitida à equipe",
    };
    if(["enroute","onScene"].includes(s.escort.backup.stage)) return {
      key:"backup:"+s.escort.backup.since,
      type:"radio",approach:"Indo coordenar a chegada do reforço",
      working:"Monitorando viatura de apoio",action:"radio",duration:7,
      report:"Posição do reforço conferida pelo rádio",
    };
    if(s.checkpoint.phase==="setup") return {
      key:"blitz:"+day+":"+s.checkpoint.startMinute,
      type:"radio",approach:"Indo apoiar comunicação da blitz",
      working:"Confirmando sinalização da fiscalização",action:"radio",duration:6,
      report:"Montagem da blitz confirmada com equipe",
    };
  }
  if(id===8 && s.life.patrol.stage==="parked") {
    if(emergency(s)) return {
      key:"perimeter:evasion:"+s.life.evasion.vehicleId+":"+s.life.evasion.completed,
      type:"gate",approach:"Indo proteger o acesso ao posto",
      working:"Observando trânsito para a equipe de apoio",action:"signal",duration:10,
      report:"Acesso monitorado durante ocorrência de evasão",
    };
    if(["dispatched","on_scene"].includes(s.copom.stage)) return {
      key:"perimeter:copom:"+s.copom.index+":"+s.copom.start,
      type:"gate",approach:"Deslocando-se para vigiar o acesso",
      working:"Preparando passagem da equipe COPOM",action:"signal",duration:8,
      report:"Acesso preparado para deslocamento COPOM",
    };
  }
  return null;
}
function readyForTask(s,a) {
  if(!POINTS[a.id]||a.task!=="routine"||a.embarked||!a.visible||a.teamwork)return false;
  if(a.human && a.human.phase!=="idle")return false;
  if(a.autonomy && ["human","meet","talk"].includes(a.autonomy.phase))return false;
  if(s.command.conversation?.ids.includes(a.id))return false;
  if(a.id===8 && s.life.patrol.stage!=="parked")return false;
  // Só inicia a partir de uma posição estável, evitando atalhos através de paredes.
  return Math.hypot(a.x-a.home.x,a.z-a.home.z)<1.2 && a.path.length===0;
}
function begin(s,a,plan,writeLog) {
  const points=POINTS[a.id];
  a.teamwork={...plan,phase:"going",since:s.time,lastProgress:s.time,
    lastX:a.x,lastZ:a.z,returnPath:copyPath(points.back)};
  a.autonomy??={phase:"work",timer:10};
  a.autonomy.phase="teamwork";
  a.path=copyPath(points.to);a.waypoint=0;
  a.action="walk";a.status=plan.approach;
  a.mind.nextCooperationAt=s.time+35;
  writeLog(a.name+" · "+plan.approach);
}
function reset(a) {
  a.teamwork=null;
  if(a.autonomy?.phase==="teamwork") {
    a.autonomy.phase="work";
    a.autonomy.timer=24;
  }
}
export function interruptNpcCooperation(a) {
  if(!a.teamwork)return false;
  // Não tocar no caminho: uma nova ordem pode tê-lo substituído.
  reset(a);
  return true;
}
function finish(s,a,writeLog) {
  const t=a.teamwork;
  a.path=[];a.waypoint=0;a.moving=false;
  a.action="watch";a.status="Retornando à função de origem";
  a.mind.handledCooperation??={};
  a.mind.handledCooperation[t.key]=s.clock.day;
  rememberNpc(a.mind,"cooperation",t.key,t.report,s.time);
  a.mind.goal="cooperar";a.mind.status=t.report;
  a.completed.cooperation=(a.completed.cooperation??0)+1;
  s.command.cooperation??={completed:0,history:[]};
  s.command.cooperation.completed++;
  s.command.cooperation.history.unshift({agent:a.name,text:t.report,
    day:s.clock.day,time:Math.floor(s.clock.minute)});
  s.command.cooperation.history.length=Math.min(s.command.cooperation.history.length,8);
  writeLog(a.name+" · "+t.report);
  reset(a);
}
export function runNpcCooperation(s,a,dt,move,writeLog) {
  if(a.task!=="routine"){
    interruptNpcCooperation(a);
    return false;
  }
  if(!a.teamwork) {
    if(!readyForTask(s,a) || s.time < (a.mind?.nextCooperationAt??0))return false;
    const plan=planFor(s,a);
    if(!plan || a.mind.handledCooperation?.[plan.key]!==undefined)return false;
    begin(s,a,plan,writeLog);
  }
  const t=a.teamwork;
  if(t.phase==="going" || t.phase==="returning") {
    const reached=move(s,a,dt);
    if(a.moving) {
      t.lastProgress=s.time;t.lastX=a.x;t.lastZ=a.z;
    }
    if(reached) {
      a.path=[];a.waypoint=0;
      if(t.phase==="going") {
        t.phase="working";t.until=s.time+t.duration;
        a.action=t.action;a.status=t.working;
      } else finish(s,a,writeLog);
    } else if(s.time-t.lastProgress>30) {
      // Sem teleporte. Tenta voltar pela rota pública já definida.
      if(t.phase==="going") {
        t.phase="returning";a.path=copyPath(t.returnPath);a.waypoint=0;
        a.status="Rota obstruída · retornando ao setor";
        t.lastProgress=s.time;
      } else {
        a.status="Aguardando acesso desobstruído ao posto";
        t.lastProgress=s.time;
      }
    } else a.status=t.phase==="going"?t.approach:"Retornando ao posto após apoio";
  } else if(t.phase==="working") {
    a.moving=false;a.action=t.action;a.status=t.working;
    if(s.time>=t.until){
      t.phase="returning";a.path=copyPath(t.returnPath);a.waypoint=0;
      t.lastProgress=s.time;
      a.action="walk";a.status="Retornando ao posto após apoio";
    }
  }
  return true;
}
export function npcQueueAssistance(s) {
  const costa=s.command.agents.find(a=>a.id===1);
  return costa?.teamwork?.type==="queue" && costa.teamwork.phase==="working" &&
    Math.hypot(costa.x-34,costa.z-22)<1.1;
}
