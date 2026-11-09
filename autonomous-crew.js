// Rotinas locais e deterministicas. Ordens e ocorrencias sempre tem prioridade.
const WAYPOINTS = {
  0: [[32,22],[33.8,22.3],[32,22]],
  1: [[38,22],[36.5,23.4],[38,22]],
  5: [[-5.7,-4],[-5.5,-8],[-5.7,-4]],
  6: [[-10.7,19.8],[-12.2,22],[-10.7,19.8]],
  7: [[10.4,-12],[12,-12.5],[10.4,-12]],
  8: [[21.5,9],[24,4],[24,8],[21.5,9]],
};
// Cada agente possui intervalos e percursos ligeiramente diferentes.
// Sem deslocamentos aleatorios no asfalto, teleporte ou troca automatica de atribuicao.
function interval(a) {
  return 19 + ((a.id * 13 + a.cycles * 7) % 19);
}
function canWalk(s, a) {
  if (a.task !== "routine" || a.embarked || (a.id >= 16)) return false;
  if ((a.id === 5 || a.id === 6) && s.checkpoint.stage !== "idle") return false;
  if ((a.id === 0 || a.id === 1) &&
      (s.reception.visitors.some(v => v.state === "queue") ||
       s.reception.visitors.some(v => v.state === "serving"))) return false;
  if (a.id === 8 && s.life.patrol.stage !== "parked") return false;
  return true;
}
export function scheduleCrewRoutine(s, a) {
  const brain = a.autonomy ??= { timer: 4 + a.id * 2, phase: "work", pause: 0 };
  if (a.task !== "routine") {
    brain.phase = "work";
    brain.pause = 0;
    return;
  }
  if (brain.phase === "walk" && a.path.length) return;
  if (brain.phase === "walk") {
    brain.phase = "work";
    brain.timer = interval(a);
    a.cycles++;
    a.status = "Retomando atividade habitual";
  }
  if (brain.timer > 0) return;
  if (!canWalk(s, a) || !WAYPOINTS[a.id]) {
    brain.timer = 5 + (a.id % 4);
    return;
  }
  a.path = WAYPOINTS[a.id].map(([x, z]) => [x, z]);
  a.waypoint = 0;
  a.elapsed = 0;
  brain.phase = "walk";
  brain.timer = interval(a);
  a.status = "Realizando ronda de rotina";
}
export function updateCrewRoutineClock(a, dt) {
  if (a.task === "routine") {
    if (a.autonomy) a.autonomy.timer = Math.max(0, a.autonomy.timer - dt);
  }
}
export function crewRoutineStatus(s, a) {
  if (a.autonomy?.phase === "walk" && a.path.length)
    return "Realizando ronda de rotina";
  const t = a.elapsed + a.id * 3.7;
  if (a.id === 0 || a.id === 1)
    return t % 42 < 5 ? ["Conferindo atendimento", "Organizando documentos"][a.id] : null;
  if (a.id === 5 || a.id === 6)
    return t % 38 < 6 ? "Conferindo equipamento de fiscalizacao" : null;
  if (a.id === 7) return t % 31 < 5 ? "Checando canal de radio" : null;
  if (a.id === 8) return t % 29 < 7 ? "Observando movimento no patio" : null;
  return t % 35 < 7 ? "Conferindo equipamento da motopatrulha" : null;
}
