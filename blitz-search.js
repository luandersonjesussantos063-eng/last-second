import {interactWeighbridge} from "./weighbridge-sim.js?v=2.23.1";
import { beginImpound } from "./inspection-impound.js?v=2.23.1";
import { addRecord } from "./operations-sim.js?v=2.23.1";
export function searchTarget(s) {
  if (s.mode !== "foot" || s.reception.seated || s.paused || s.inspection)
    return null;
  return (
    [...s.traffic, s.weighbridge.truck]
      .filter(
        (t) =>
          (t.id !== s.mission.targetId || t === s.weighbridge.truck) &&
          !t.impounded &&
          t.visible !== false &&
          Math.abs(t.speed) < 0.3 &&
          (t.stopped || t === s.weighbridge.truck) &&
          Math.hypot(s.player.x - t.x, s.player.z - t.z) < 6,
      )
      .sort(
        (a, b) =>
          Math.hypot(a.x - s.player.x, a.z - s.player.z) -
          Math.hypot(b.x - s.player.x, b.z - s.player.z),
      )[0] ?? null
  );
}
export function beginSearch(s) {
  const t = searchTarget(s);
  if (!t) return false;
  s.blitzSearch = {
    id: t.id ?? "scale",
    plate: t.plate ?? "PESAGEM",
    checks: [],
    result: "Solicite os documentos antes da vistoria.",
    decision: "release",
  };
  if (s.checkpoint.vehicleId === t.id) {
    s.checkpoint.manualHold = true;
    s.checkpoint.status = "COMANDANTE ASSUMIU A FISCALIZAÇÃO";
  }
  return true;
}
export function searchedVehicle(s) {
  return s.blitzSearch?.id === "scale"
    ? s.weighbridge.truck
    : s.traffic.find((t) => t.id === s.blitzSearch?.id);
}
export function inspectPart(s, part) {
  const r = s.blitzSearch,
    t = searchedVehicle(s);
  if (!r || !t || s.paused || !["documents", "cabin", "cargo"].includes(part))
    return false;
  if (part !== "documents" && !r.checks.includes("documents")) {
    r.result = "Peça os documentos e identifique o condutor primeiro.";
    return false;
  }
  if (!r.checks.includes(part)) r.checks.push(part);
  const irregular = Number(t.id ?? 0) % 3 === 2;
  r.result =
    part === "documents"
      ? `Condutor: aqui estão os documentos. Placa ${r.plate}. CNH válida · ${irregular ? "CRLV com pendência fictícia" : "CRLV regular"}.`
      : part === "cabin"
        ? "Revista concluída: cabine, bancos e compartimentos conferidos. Nenhum objeto proibido neste cenário."
        : t.kind === "truck" || t.freightType
          ? `Carga declarada: mercadorias embaladas. Lacre ${r.plate.slice(-4)} · ${irregular ? "divergência fictícia entre volumes e manifesto; registre a ocorrência" : "volumes e manifesto conferidos"}.`
          : "Porta-malas aberto: bagagens e equipamentos de segurança conferidos.";
  return true;
}
export function finishSearch(s, decision) {
  const r = s.blitzSearch,
    t = searchedVehicle(s);
  if (
    !r ||
    !t ||
    s.paused ||
    r.checks.length < 3 ||
    !["release", "fine", "retain"].includes(decision)
  )
    return false;
  if(decision==='retain'&&t===s.weighbridge.truck){
    if(s.weighbridge.stage!=='weighed'){r.result='Finalize a pesagem no terminal antes de encaminhar esta carga ao pátio.';return false;}
    s.weighbridge.report.retainedByCommander=true;
    if(!interactWeighbridge(s))return false;
  }else if (decision === "retain" && !beginImpound(s, t)) return false;
  addRecord(
    s,
    "blitz",
    `${r.plate} · documentos, cabine e carga conferidos · ${{ release: "liberação", fine: "autuação fictícia e liberação", retain: "retenção com guincho" }[decision]}`,
    10,
  );
  const c = s.checkpoint;
  if (c.vehicleId === t.id) {
    c.manualHold = false;
    c.elapsed = 0;
    if (decision === "retain") {
      c.driverVisible = false;
      c.vehicleId = null;
      c.stage = "cooldown";
      c.completed++;
    } else c.stage = "release";
  } else if (t !== s.weighbridge.truck && s.mission.targetId !== t.id) {
    t.stopped = decision === "retain";
  }
  s.blitzSearch = null;
  return true;
}
export function returnSearch(s) {
  if (s.checkpoint.manualHold) {
    s.checkpoint.manualHold = false;
    s.checkpoint.elapsed = 0;
  }
  s.blitzSearch = null;
}
