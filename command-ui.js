import {
  AGENT_DEFINITIONS,
  COMMAND_MISSIONS,
  ORDERS,
  agentById,
  agentBusy,
  nearestAgent,
  orderAvailable,
  issueOrder,
  startCommandMission,
  missionProgress,
} from "./command-sim.js?v=2.15.1";
import { clockReading } from "./shift-clock.js?v=2.15.1";
import {npcSummary} from "./npc-intelligence.js?v=2.15.1";
import { requestCopom, currentCopom, copomStatus, copomDistance } from "./copom-sim.js?v=2.15.1";
export function createCommandUI({ getSim, release, audio, refresh }) {
  const $ = (id) => document.getElementById(id),
    dialog = $("commandDialog"),
    select = $("agentSelect");
  let channel = "radio",
    lastSerial = -1;
  for (const a of AGENT_DEFINITIONS) {
    const option = document.createElement("option");
    option.value = a.id;
    option.textContent = `${a.name} · ${a.role}`;
    select.add(option);
  }
  const buttons = new Map();
  for (const [key, order] of Object.entries(ORDERS)) {
    const b = document.createElement("button");
    b.className = "button";
    b.textContent = order.label;
    b.onclick = () => {
      const s = getSim(),
        a = agentById(s, select.value);
      if (issueOrder(s, a.id, key, channel)) {
        audio.emit("radio");
        update();
        refresh();
      } else {
        $("agentStatus").textContent =
          "Agente indisponível ou fora de alcance. Use o rádio ou aguarde o retorno.";
      }
    };
    $("orderButtons").append(b);
    buttons.set(key, b);
  }
  const rows = AGENT_DEFINITIONS.map((a) => {
    const b = document.createElement("button");
    b.className = "roster-agent";
    b.onclick = () => {
      channel = "radio";
      getSim().player.usingRadio = true;
      select.value = a.id;
      update();
    };
    $("agentRoster").append(b);
    return { id: a.id, element: b };
  });
  function close() {
    dialog.close();
    getSim().player.usingRadio = false;
    release();
  }
  function open(near = false) {
    const s = getSim();
    if (s.paused || s.inspection) return;
    const a = near ? nearestAgent(s) : null;
    if (near && !a) return;
    channel = near ? "near" : "radio";
    if (a) select.value = a.id;
    release();
    s.player.moving = false;
    s.player.running = false;
    s.player.usingRadio = !near;
    if (!dialog.open) dialog.showModal();
    audio.emit("radio");
    update();
  }
  function update() {
    const s = getSim(),
      r = clockReading(s.clock),
      m = s.command.mission,
      definition = COMMAND_MISSIONS[m.index];
    $("shiftClock").textContent =
      `DIA ${s.clock.day} · ${r.text} · ${r.period}`;
    const incident=currentCopom(s), dispatch=s.copom;
    const available=dispatch.stage === "available" ||
      (dispatch.stage==="complete" && s.time>=dispatch.availableAt);
    $("copomHud").hidden=dispatch.stage==="available";
    $("copomHud").textContent=`COPOM · ${copomStatus(s)} · ${incident.title} · ${copomDistance(s)} m`;
    $("copomStatus").textContent=copomStatus(s)+" · "+incident.id;
    $("copomTitle").textContent=incident.title;
    $("copomDescription").textContent=incident.description;
    $("copomDistance").textContent=dispatch.stage==="available"?"Aceite o chamado para receber o destino."
      :dispatch.stage==="complete"?"Ocorrência encerrada neste turno."
      :`Deslocamento: ${copomDistance(s)} m até o ponto de atendimento. Ao chegar, pare e pressione F a pé.`;
    $("copomAcceptBtn").disabled=!available;
    $("copomAcceptBtn").textContent=available?"ACEITAR CHAMADO COPOM"
      :dispatch.stage==="complete"?"AGUARDE NOVA CHAMADA":"CHAMADO EM ATENDIMENTO";
    $("copomHistory").replaceChildren(...dispatch.history.map(entry=>{
      const li=document.createElement("li");
      li.textContent=entry.id+" · "+entry.outcome;
      return li;
    }));
    $("shiftClock").hidden = false;
    const commandView = s.command.view === "command";
    $("missionEyebrow").textContent = commandView
      ? `COMANDO GERAL · ${s.command.completed} MISSÃO(ÕES) CONCLUÍDA(S)`
      : "PATRULHA · FISCALIZAÇÃO";
    if (commandView) {
      $("missionTitle").textContent = definition.title;
      $("missionText").textContent =
        m.stage === "briefing"
          ? "Abra o comando [T] para iniciar a missão."
          : m.stage === "complete"
            ? "Missão concluída. Abra o comando [T] para receber a próxima."
            : definition.brief;
      $("missionDistance").textContent =
        m.stage === "active"
          ? `${missionProgress(s).filter(Boolean).length}/${definition.objectives.length} objetivos · Ordens presenciais [F] ou rádio [T]`
          : "Gerencie a equipe, a blitz e o atendimento";
    }
    $("missionViewBtn").textContent = commandView
      ? "VER FISCALIZAÇÃO"
      : "VER MISSÃO DE COMANDO";
    if (!dialog.open) return;
    const a = agentById(s, select.value);
    $("commandChannel").textContent =
      channel === "near"
        ? "ORDEM PRESENCIAL · " + a.name
        : "RÁDIO OPERACIONAL · CANAL DA UNIDADE";
    const lastMemory = a.ai?.memories.at(-1)?.summary;
    $("agentStatus").textContent =
      `${a.name} — ${a.status}${agentBusy(s, a) ? " · Em atendimento externo" : ""}` +
      ` · Perfil: ${a.ai?.personality ?? "em análise"}` +
      (lastMemory ? ` · Lembra: ${lastMemory}` : "") +
      " · IA: " + npcSummary(a);
    for (const [key, b] of buttons) {
      b.hidden = !ORDERS[key].ids.includes(a.id);
      b.disabled =
        !orderAvailable(s, a, key) ||
        (channel === "near" &&
          (!a.visible ||
            s.mode !== "foot" ||
            Math.hypot(a.x - s.player.x, a.z - s.player.z) > 3.2));
    }
    $("commandMissionTitle").textContent = definition.title;
    $("commandMissionBrief").textContent = definition.brief;
    const checks = missionProgress(s);
    $("commandObjectives").replaceChildren(
      ...definition.objectives.map((text, i) => {
        const li = document.createElement("li");
        li.textContent = (checks[i] ? "✓ " : "○ ") + text;
        li.className = checks[i] ? "done" : "";
        return li;
      }),
    );
    $("startCommandMission").disabled = m.stage === "active";
    $("startCommandMission").textContent =
      m.stage === "briefing"
        ? "INICIAR MISSÃO"
        : m.stage === "active"
          ? "MISSÃO EM ANDAMENTO"
          : "RECEBER PRÓXIMA MISSÃO";
    const teamwork=s.command.cooperation;
    $("npcTeamworkTotal").textContent =
      "Apoios espontâneos concluídos: "+(teamwork?.completed??0)+
      (s.command.agents.filter(a=>a.teamwork).length
        ?" · "+s.command.agents.filter(a=>a.teamwork).map(a=>a.name).join(", ")+" em ação":"");
    $("npcTeamworkHistory").replaceChildren(...(teamwork?.history??[]).slice(0,5).map(item=>{
      const li=document.createElement("li");li.textContent=item.agent+" · "+item.text;return li;
    }));
    for (const row of rows) {
      const p = agentById(s, row.id);
      row.element.textContent = `${p.name} · ${p.status}`;
      row.element.setAttribute("aria-pressed", String(p.id === a.id));
    }
    if (lastSerial !== s.command.serial) {
      lastSerial = s.command.serial;
      $("radioLog").replaceChildren(
        ...s.command.log.slice(0, 7).map((entry) => {
          const li = document.createElement("li");
          const h = String(Math.floor(entry.minute / 60)).padStart(2, "0"),
            min = String(entry.minute % 60).padStart(2, "0");
          li.textContent = `D${entry.day} ${h}:${min} · ${entry.text}`;
          return li;
        }),
      );
    }
  }
  $("copomAcceptBtn").onclick = () => {
    const s=getSim();
    if(requestCopom(s)) audio.emit("radio");
    update();
    refresh();
  };
  $("radioBtn").onclick = () => open();
  $("openCommandBtn").onclick = () => open();
  $("closeCommand").onclick = close;
  dialog.addEventListener("cancel", (e) => {
    e.preventDefault();
    close();
  });
  select.onchange = () => {
    channel = "radio";
    getSim().player.usingRadio = true;
    update();
  };
  $("startCommandMission").onclick = () => {
    if (startCommandMission(getSim())) audio.emit("radio");
    update();
    refresh();
  };
  $("missionViewBtn").onclick = () => {
    const c = getSim().command;
    c.view = c.view === "command" ? "patrol" : "command";
    refresh();
  };
  return {
    open,
    close,
    update,
    get isOpen() {
      return dialog.open;
    },
  };
}
