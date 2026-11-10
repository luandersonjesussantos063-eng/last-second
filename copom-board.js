// COPOM fictício: dados locais de missões, sem serviços externos.
import { COMMAND_MISSIONS, missionProgress } from "./command-sim.js?v=2.13.0";
export function copomSnapshot(s) {
  const m = s.command.mission, def = COMMAND_MISSIONS[m.index];
  const active = m.stage === "active", complete = m.stage === "complete";
  return {
    title: def.title, brief: def.brief,
    status: complete ? "Concluída" : active ? "Em atendimento" : "Aguardando despacho",
    progress: active || complete ? missionProgress(s).filter(Boolean).length : 0,
    total: def.objectives.length,
    action: active ? null : complete ? "RECEBER PRÓXIMA OCORRÊNCIA" : "DESPACHAR OCORRÊNCIA",
    history: s.command.log.filter(e => /Missão iniciada|Missão concluída/.test(e.text)).slice(0, 4),
  };
}
