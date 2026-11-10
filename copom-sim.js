import {beginIncident} from "./incident-sim.js?v=2.17.0";
// IA-02 | Ocorrências fictícias COPOM do simulador de navegador.
// Somente estado local: nenhuma consulta governamental, persistência remota ou identidade real.
const TASKS = [
  { id: "COP-001", title: "Veículo imobilizado no acostamento", x: -9.3, z: -180,
    description: "Recebemos relato de veículo parado no acostamento. Verifique a segurança do trecho." },
  { id: "COP-002", title: "Objeto sinalizado junto à pista", x: -9.3, z: 280,
    description: "Sinalização preventiva solicitada. Faça uma verificação do acostamento." },
];
const distance = (p, t) => Math.hypot(p.x - t.x, p.z - t.z);
export function createCopom() {
  return { stage: "available", index: 0, start: null, onSceneAt: null,
    completed: 0, availableAt: 0, history: [], serial: 0 };
}
export function currentCopom(s) {
  const c=s.copom;
  return TASKS[c.index % TASKS.length];
}
export function requestCopom(s) {
  const c=s.copom;
  if (s.paused || s.inspection) return false;
  if (!["available","complete"].includes(c.stage) || s.time < c.availableAt) return false;
  if (c.stage === "complete") c.index++;
  c.stage="dispatched";
  c.start=s.time;
  c.onSceneAt=null;
  c.serial++;
  beginIncident(s,currentCopom(s));
  s.notice="COPOM: " + currentCopom(s).description;
  s.noticeUntil=s.time+8;
  return true;
}
export function updateCopom(s) {
  const c=s.copom;
  if(c.stage!=="dispatched") return;
  const location=currentCopom(s);
  const observer=s.mode==="drive" ? s.car : s.player;
  const d=distance(observer,location);
  if (d<23 && (s.mode==="foot" || Math.abs(s.car.speed)<1.8)) {
    c.stage="on_scene";
    c.onSceneAt=s.time;
    c.serial++;
    s.notice="COPOM: local encontrado. Desembarque e sinalize o atendimento [F].";
    s.noticeUntil=s.time+7;
  }
}
export function canCompleteCopom(s) {
  return s.copom.stage==="on_scene" && s.incident.stage==="resolved" && s.mode==="foot" &&
    !s.paused && !s.inspection &&
    distance(s.player,currentCopom(s)) <= 10;
}
export function completeCopom(s) {
  if(!canCompleteCopom(s)) return false;
  const c=s.copom,task=currentCopom(s);
  c.stage="complete";
  c.completed++;
  c.serial++;
  c.history.unshift({
    id:task.id,
    title:task.title,
    time:Math.round(s.time),
    outcome:s.incident.kind==="vehicle"?"Via liberada após isolamento, vistoria e guincho":"Objeto retirado com apoio e via liberada",
  });
  c.history=c.history.slice(0,6);
  c.availableAt=s.time+35;
  s.notice="COPOM: atendimento concluído. Obrigado, comandante.";
  s.noticeUntil=s.time+7;
  return true;
}
export function copomDistance(s) {
  const who=s.mode==="drive" ? s.car : s.player;
  return Math.round(distance(who,currentCopom(s)));
}
export function copomStatus(s) {
  const statuses={
    available:"AGUARDANDO DESPACHO",
    dispatched:"EM DESLOCAMENTO",
    on_scene:"ATENDIMENTO OPERACIONAL EM ANDAMENTO",
    complete:"ATENDIMENTO CONCLUÍDO",
  };
  return statuses[s.copom.stage] || "SEM CHAMADO";
}
