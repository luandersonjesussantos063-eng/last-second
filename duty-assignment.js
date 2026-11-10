import { moveCrewAgent } from "./crew-navigation.js?v=2.23.1";
const LABELS = {
  dutyBlitz: "Assumir posto na blitz",
  dutyRound: "Fazer ronda na unidade",
  dutyAdmin: "Trabalhar na administração",
};
export const DUTY_LABELS = LABELS;
export function canReassign(s, a) {
  return (
    !!a &&
    a.visible &&
    !a.embarked &&
    !(a.action === "seated" && a.id >= 18) &&
    !(a.id === 16 || a.id === 17
      ? s.life.bikes[a.id - 16].stage !== "ready"
      : false) &&
    !(a.task === "backup" && s.escort.backup.stage === "enroute")
  );
}
function exit(a) {
  return a.x > 26 && a.x < 44 && a.z > 9 && a.z < 30
    ? [
        [35, 21],
        [35, 12],
        [35, 5],
        [24, 4],
      ]
    : a.x < 0
      ? [
          [-10, -32],
          [15, -32],
          [24, 4],
        ]
      : [[24, 4]];
}
export function assignDuty(s, a, type) {
  if (!LABELS[type] || !canReassign(s, a)) return false;
  if(s.escort.members?.includes(a.id)){
    s.escort.members=s.escort.members.filter(id=>id!==a.id);
    s.escort.boarded=s.escort.boarded.filter(id=>id!==a.id);
    s.escort.returned=s.escort.returned.filter(id=>id!==a.id);
  }
  a.task = "assigned";
  a.duty = type;
  a.elapsed = 0;
  a.waypoint = 0;
  a.embarked = false;
  const slot = s.command.agents.findIndex((p) => p.id === a.id);
  a.path = [
    ...exit(a),
    ...(type === "dutyAdmin"
      ? [
          [35, 5],
          [35, 12],
          [35, 21],
          [35 + (slot % 3) * 1.5, 21 + Math.floor(slot / 3) * 1.3],
        ]
      : type === "dutyBlitz"
        ? [
            [15, -32],
            [-10, -32],
            [-10.5, -25 + slot * 2.7],
          ]
        : [
            [24, 4],
            [47, 2],
            [47, 33],
            [24, 34],
            [24, 4],
          ]),
  ];
  a.dutyDepartAt = s.time + slot * 0.35;
  a.dutyRoute = a.path.slice(-5).map((p) => [...p]);
  a.status = LABELS[type] + " · deslocando";
  return true;
}
export function updateDuty(s, a, dt) {
  if (a.task !== "assigned") return false;
  if (s.time < (a.dutyDepartAt ?? 0)) {
    a.action = "watch";
    return true;
  }
  if (!moveCrewAgent(s, a, dt)) return true;
  a.moving = false;
  a.action =
    a.duty === "dutyAdmin"
      ? "typing"
      : a.duty === "dutyBlitz"
        ? s.checkpoint.stage === "checking"
          ? "documents"
          : "signal"
        : "watch";
  a.status = LABELS[a.duty] + " · em serviço";
  if (a.duty === "dutyRound" && a.elapsed > 8) {
    a.path = a.dutyRoute.map((p) => [...p]);
    a.waypoint = 0;
    a.elapsed = 0;
  }
  return true;
}
