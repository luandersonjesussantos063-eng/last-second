// Local dispatch connects physical tasks to concise radio guidance.
export function createMissionRadio() {
  return { messages: [], serial: 0, seen: {} };
}
export function updateMissionRadio(s) {
  const r = (s.radioFeed ??= createMissionRadio());
  const emit = (key, value, text) => {
    if (r.seen[key] === value) return;
    r.seen[key] = value;
    if (!text) return;
    r.messages.unshift({ serial: ++r.serial, time: s.time, text });
    r.messages.length = Math.min(8, r.messages.length);
  };
  const i = s.incident;
  const guidance = {
    arrival: "COPOM: confirme o isolamento antes da aproximação.",
    secured: "COPOM: ouça o condutor e registre a vistoria.",
    surveyed: "Apoio acionado. Mantenha a área segura e aguarde a equipe.",
    towCalled: "Guincho em deslocamento. Mantenha livre o acesso.",
    towReady: "Guincho posicionado. Autorize o recolhimento [F].",
    resolved: "Área liberada. Transmita o encerramento [F].",
  };
  emit("incident", i.stage, guidance[i.stage]);
  emit(
    "escort",
    s.escort.stage,
    {
      boarding:
        "Equipe: saindo da unidade para embarque. Aguarde a confirmação.",
      aboard: "Equipe embarcada. Viatura pronta para deslocar.",
      returning: "Equipe: desembarcando e retornando aos postos.",
    }[s.escort.stage],
  );
  emit(
    "scale",
    s.weighbridge.stage,
    {
      weighing: "Balança da base: pesagem iniciada. Aguarde a leitura.",
      weighed: "Balança da base: resultado disponível. Confira e registre [F].",
      approach:
        "Balança da base: próximo caminhão entrando. Mantenha a plataforma livre.",
    }[s.weighbridge.stage],
  );
  emit(
    "mission",
    s.command.mission.stage,
    s.command.mission.stage === "complete"
      ? "Central: missão de comando concluída. Próxima ordem disponível no rádio [T]."
      : null,
  );
}
