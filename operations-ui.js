import {
  WEATHER,
  careerRank,
  setWeather,
  serviceVehicle,
  saveCareer,
  useRepairKit,
} from "./operations-sim.js?v=2.20.0";
import {
  TOWNS,
  URBAN_FACILITIES,
  navigationRoute,
  routeDistance,
} from "./urban-layout.js?v=2.20.0";
import { currentCopom } from "./copom-sim.js?v=2.20.0";
export const BASE_FACILITIES = [
  { id: "base-fuel", name: "Bomba da base", kind: "fuel", x: 50, z: -35 },
  { id: "base-garage", name: "Oficina da base", kind: "repair", x: 49, z: -23 },
];
export function facilities() {
  return [
    ...BASE_FACILITIES,
    ...URBAN_FACILITIES.filter((f) =>
      ["fuel", "workshop"].includes(f.type),
    ).map((f) => ({ ...f, kind: f.type === "workshop" ? "repair" : f.type })),
  ];
}
export function closestService(s) {
  return facilities()
    .filter((f) => Math.hypot(s.car.x - f.x, s.car.z - f.z) <= 7)
    .sort(
      (a, b) =>
        Math.hypot(s.car.x - a.x, s.car.z - a.z) -
        Math.hypot(s.car.x - b.x, s.car.z - b.z),
    )[0];
}
export function createOperationsUI({ getSim, release, refresh, audio }) {
  const $ = (id) => document.getElementById(id),
    dialog = $("operationsDialog");
  let route = [],
    destination = null;
  function targets(s) {
    const scale = s.weighbridge.kiosk ?? s.weighbridge;
    return [
      { id: "base", name: "Base PRF", x: 20, z: -8 },
      { id: "scale", name: "Balança rodoviária", x: scale.x, z: scale.z },
      { ...currentCopom(s), id: "copom", name: "Ocorrência COPOM" },
      ...TOWNS,
      ...facilities(),
    ];
  }
  function open() {
    const s = getSim();
    if (s.paused || s.inspection) return;
    if (s.mode === "drive" && Math.abs(s.car.speed) > 1.2) {
      s.notice = "Pare a viatura antes de abrir o tablet.";
      s.noticeUntil = s.time + 4;
      refresh();
      return;
    }
    release();
    $("destinationSelect").replaceChildren(
      ...targets(s).map((t) => {
        const option = document.createElement("option");
        option.value = t.id;
        option.textContent = t.name ?? t.title;
        return option;
      }),
    );
    $("destinationSelect").value = s.operations.destination;
    if (!dialog.open) dialog.showModal();
    update();
  }
  function close() {
    dialog.close();
    release();
  }
  function save() {
    try {
      saveCareer(getSim(), localStorage);
    } catch {
      getSim().operations.saveStatus = "Armazenamento indisponível";
    }
    update();
  }
  $("tabletBtn").onclick = open;
  $("closeOperations").onclick = close;
  dialog.addEventListener("cancel", (event) => {
    event.preventDefault();
    close();
  });
  $("destinationSelect").onchange = () => {
    getSim().operations.destination = $("destinationSelect").value;
    update();
  };
  $("weatherSelect").onchange = () => {
    const s = getSim(),
      value = $("weatherSelect").value;
    if (value === "auto")
      Object.assign(s.operations.weather, {
        automatic: true,
        elapsed: 0,
        kind: "clear",
      });
    else setWeather(s, value);
    update();
  };
  $("saveCareerBtn").onclick = save;
  $("repairKitBtn").onclick = () => {
    if (useRepairKit(getSim())) audio.emit("ui");
    update();
  };
  $("serviceVehicleBtn").onclick = () => {
    const s = getSim(),
      f = closestService(s);
    if (f && serviceVehicle(s, f.kind, f)) {
      audio.emit("ui");
      refresh();
      update();
    }
  };
  function update() {
    const s = getSim(),
      who = s.mode === "drive" ? s.car : s.player;
    destination =
      targets(s).find((t) => t.id === s.operations.destination) ??
      targets(s)[0];
    route = navigationRoute(who, destination);
    const distance = routeDistance(route);
    $("gpsHud").hidden = false;
    $("gpsHud").textContent =
      `GPS · ${destination.name ?? destination.title} · ${Math.round(distance)} m · ${WEATHER[s.operations.weather.kind].label}`;
    if (!dialog.open) return;
    const c = s.operations.career;
    $("careerStatus").textContent =
      `${careerRank(s)} · ${c.xp} XP · avaliação ${c.rating}% · ${c.shifts} plantão(ões) · ${c.inspections} fiscalizações · ${c.incidents} COPOM · ${c.weighings} pesagens`;
    $("vehicleStatus").textContent =
      `Combustível ${Math.round(s.car.fuel)}% · Integridade ${Math.round(s.car.condition)}% · Equipe embarcada ${s.escort?.boarded.length ?? 0}/3`;
    $("repairKitBtn").disabled =
      c.xp < 250 ||
      s.operations.kitDay === s.clock.day ||
      Math.abs(s.car.speed) > 0.3 ||
      s.car.condition >= 100;
    $("repairKitBtn").textContent =
      c.xp < 250
        ? "KIT DE CAMPO · DESBLOQUEIA EM 250 XP"
        : "USAR KIT DE CAMPO (+20%, UMA VEZ POR DIA)";
    $("weatherSelect").value = s.operations.weather.automatic
      ? "auto"
      : s.operations.weather.kind;
    const f = closestService(s);
    $("serviceVehicleBtn").disabled = !f || Math.abs(s.car.speed) > 0.3;
    $("serviceVehicleBtn").textContent = f
      ? f.kind === "fuel"
        ? "ABASTECER VIATURA"
        : "REPARAR VIATURA"
      : "PARE JUNTO À BOMBA OU OFICINA";
    $("saveStatus").textContent = s.operations.saveStatus;
    $("operationsHistory").replaceChildren(
      ...s.operations.records.slice(0, 12).map((r) => {
        const li = document.createElement("li");
        li.textContent = `D${r.day} · ${r.text}`;
        return li;
      }),
    );
    drawMap(s, who);
  }
  function drawMap(s, who) {
    const canvas = $("operationsMap"),
      m = canvas.getContext("2d"),
      px = (x) => 40 + x * 1.3,
      pz = (z) => 130 - z * 0.075;
    m.fillStyle = "#102331";
    m.fillRect(0, 0, canvas.width, canvas.height);
    m.strokeStyle = "#657d88";
    m.lineWidth = 5;
    m.beginPath();
    m.moveTo(px(0), pz(-1500));
    m.lineTo(px(0), pz(1500));
    m.stroke();
    for (const town of TOWNS) {
      m.lineWidth = 3;
      m.beginPath();
      m.moveTo(px(0), pz(town.z));
      m.lineTo(px(town.x + 70), pz(town.z));
      m.stroke();
      m.fillStyle = "#253f51";
      m.fillRect(px(95), pz(town.z + 60), 170, 12);
      m.fillStyle = "#c6d6d9";
      m.font = "11px Arial";
      m.fillText(town.name, px(100), pz(town.z) - 12);
    }
    m.strokeStyle = "#f3d36c";
    m.lineWidth = 2;
    m.beginPath();
    route.forEach((p, i) =>
      i ? m.lineTo(px(p.x), pz(p.z)) : m.moveTo(px(p.x), pz(p.z)),
    );
    m.stroke();
    for (const t of [
      s.car,
      ...s.support,
      ...s.command.agents.filter((a) => a.visible),
    ]) {
      m.fillStyle = "#74d4e4";
      m.fillRect(px(t.x) - 2, pz(t.z) - 2, 4, 4);
    }
    m.fillStyle = "#f8df94";
    m.beginPath();
    m.arc(px(who.x), pz(who.z), 4, 0, Math.PI * 2);
    m.fill();
    m.fillStyle = "#ffffff";
    m.font = "11px Arial";
    m.fillText("BR-163 · mapa operacional / rota em amarelo", 15, 245);
  }
  function drawMinimap(m, who) {
    m.save();
    m.strokeStyle = "#f2cb61";
    m.lineWidth = 2;
    m.beginPath();
    route.forEach((p, i) => {
      const x = 90 - (p.x - who.x) * 0.8,
        z = 90 - (p.z - who.z) * 0.8;
      i ? m.lineTo(x, z) : m.moveTo(x, z);
    });
    m.stroke();
    m.restore();
  }
  return {
    open,
    close,
    update,
    save,
    drawMinimap,
    get isOpen() {
      return dialog.open;
    },
  };
}
