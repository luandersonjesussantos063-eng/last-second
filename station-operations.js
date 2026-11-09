// Deterministic station routines: no rendering, timers or external services.
export const FLIGHT_LABELS = {
  service: "PREPARAÇÃO",
  boarding: "PILOTO A CAMINHO",
  embarking: "EMBARQUE",
  ready: "AGUARDANDO PISTA",
  clearance: "AUTORIZADO",
  taxiOut: "TAXIANDO",
  depart: "DECOLANDO",
  patrol: "EM PATRULHA",
  holding: "AGUARDANDO RETORNO",
  approach: "APROXIMAÇÃO",
  returning: "POUSANDO",
  taxiIn: "ESTACIONANDO",
  disembarking: "DESEMBARQUE",
  debrief: "RELATÓRIO DE VOO",
};
const smooth = (t) => {
  t = Math.max(0, Math.min(1, t));
  return t * t * (3 - 2 * t);
};
const mix = (a, b, t) => a + (b - a) * t;
const movePerson = (p, x, z, dt, speed = 1.8) => {
  const dx = x - p.x,
    dz = z - p.z,
    d = Math.hypot(dx, dz),
    step = Math.min(d, dt * speed);
  if (d > 0.001) {
    p.x += (dx / d) * step;
    p.z += (dz / d) * step;
    p.yaw = Math.atan2(dx, dz);
  }
  p.moving = d > 0.08;
  p.phase += step * 5;
  return d < 0.08;
};
export class StationTraffic {
  constructor() {
    this.reset();
  }
  reset() {
    this.owner = null;
    this.gate = 0;
    this.completedFlights = 0;
    this.ships = [
      [-20, 32],
      [20, 48],
      [-20, 74],
    ].map(([x, z], i) => ({
      id: `ALPHA-${i + 2}`,
      side: Math.sign(x),
      bay: { x, z },
      x,
      y: -2.6,
      z,
      state: "service",
      elapsed: 0,
      dwell: 5 + i * 12,
      cycles: 0,
      blocked: false,
      hatch: 1,
      thruster: 0,
      yaw: 0,
      pilot: {
        x: Math.sign(x) * 27,
        z: z - 2,
        y: -5.2,
        yaw: (-Math.sign(x) * Math.PI) / 2,
        visible: true,
        moving: false,
        phase: i,
        action: "briefing",
        role: "PILOTO",
      },
    }));
  }
  get busy() {
    return this.owner !== null;
  }
  transition(ship, state) {
    ship.state = state;
    ship.elapsed = 0;
  }
  update(dt, { playerPriority = false, walker = null } = {}) {
    for (const ship of this.ships) {
      ship.elapsed += dt;
      ship.blocked = false;
      const p = ship.pilot,
        lane = ship.side * 10.5;
      p.moving = false;
      if (ship.state === "service") {
        p.action = "briefing";
        if (ship.elapsed >= ship.dwell) this.transition(ship, "boarding");
      } else if (ship.state === "boarding") {
        p.action = "walking";
        if (movePerson(p, ship.bay.x + ship.side * 5.8, ship.bay.z - 2, dt))
          this.transition(ship, "embarking");
      } else if (ship.state === "embarking") {
        const t = smooth(ship.elapsed / 2);
        p.x = mix(
          ship.bay.x + ship.side * 5.8,
          ship.bay.x + ship.side * 2.5,
          t,
        );
        p.y = mix(-5.2, -3.5, t);
        p.action = "walking";
        p.phase += dt * 6;
        ship.hatch = 1 - t;
        if (ship.elapsed >= 2) {
          p.visible = false;
          this.transition(ship, "ready");
        }
      } else if (ship.state === "ready" || ship.state === "holding") {
        if (!this.busy && !playerPriority) {
          const unsafe =
            walker &&
            walker.y < 0 &&
            Math.abs(walker.x - ship.bay.x) < 7 &&
            Math.abs(walker.z - ship.bay.z) < 8;
          if (!unsafe) {
            this.owner = ship.id;
            this.transition(
              ship,
              ship.state === "ready" ? "clearance" : "approach",
            );
          } else ship.blocked = true;
        }
      } else if (ship.state === "clearance") {
        if (ship.elapsed >= 2) this.transition(ship, "taxiOut");
      } else if (
        ["taxiOut", "depart", "approach", "returning", "taxiIn"].includes(
          ship.state,
        )
      ) {
        const pedestrian =
          walker &&
          walker.y < 0 &&
          ((Math.abs(walker.x - ship.x) < 6 &&
            Math.abs(walker.z - ship.z) < 9) ||
            (Math.abs(walker.x - lane) < 5.5 &&
              walker.z > ship.bay.z - 7 &&
              walker.z < 104));
        if (pedestrian) {
          ship.elapsed = Math.max(0, ship.elapsed - dt);
          ship.blocked = true;
        }
        const t = smooth(
          ship.elapsed /
            { taxiOut: 3, depart: 8, approach: 6, returning: 7, taxiIn: 3 }[
              ship.state
            ],
        );
        if (ship.state === "taxiOut") {
          ship.x = mix(ship.bay.x, lane, t);
          ship.thruster = 0.25;
          if (t >= 1) this.transition(ship, "depart");
        } else if (ship.state === "depart") {
          ship.z = mix(ship.bay.z, 240, t);
          ship.y = -2.6 + smooth((ship.z - 105) / 135) * 22;
          ship.thruster = 1;
          if (t >= 1) {
            this.owner = null;
            this.transition(ship, "patrol");
          }
        } else if (ship.state === "approach") {
          ship.x = lane;
          ship.z = mix(240, 105, t);
          ship.y = mix(19.4, -2.6, t);
          ship.yaw = Math.PI;
          ship.thruster = 0.4;
          if (t >= 1) this.transition(ship, "returning");
        } else if (ship.state === "returning") {
          ship.z = mix(105, ship.bay.z, t);
          ship.thruster = 0.2;
          if (t >= 1) this.transition(ship, "taxiIn");
        } else {
          ship.x = mix(lane, ship.bay.x, t);
          ship.yaw = Math.PI * (1 - t);
          ship.thruster = 0.12;
          if (t >= 1) {
            this.owner = null;
            ship.thruster = 0;
            p.visible = true;
            this.transition(ship, "disembarking");
          }
        }
      } else if (ship.state === "patrol") {
        const t = ship.elapsed;
        ship.x = ship.side * (60 + Math.sin(t * 0.18) * 40);
        ship.z = 350 + Math.sin(t * 0.12) * 110;
        ship.y = 30 + Math.cos(t * 0.15) * 15;
        if (t > 22 + this.ships.indexOf(ship) * 5)
          this.transition(ship, "holding");
      } else if (ship.state === "disembarking") {
        const t = smooth(ship.elapsed / 2);
        ship.hatch = t;
        p.x = mix(
          ship.bay.x + ship.side * 2.5,
          ship.bay.x + ship.side * 5.8,
          t,
        );
        p.z = ship.bay.z - 2;
        p.y = mix(-3.5, -5.2, t);
        p.action = "walking";
        p.phase += dt * 6;
        if (t >= 1) this.transition(ship, "debrief");
      } else if (ship.state === "debrief") {
        p.action = "briefing";
        if (
          movePerson(p, ship.side * 27, ship.bay.z - 2, dt) &&
          ship.elapsed > 6
        ) {
          ship.cycles++;
          this.completedFlights++;
          ship.dwell = 14;
          this.transition(ship, "service");
        }
      }
    }
    this.gate += ((this.busy ? 1 : 0) - this.gate) * Math.min(1, dt * 4);
  }
}

export function createStationWorkers() {
  const job = (role, stations, action, floor = -5.2) => ({
    role,
    stations,
    action,
    workingAction: action,
    x: stations[0][0],
    z: stations[0][1],
    y: floor,
    floor,
    yaw: stations[0][2],
    phase: 0,
    station: 0,
    elapsed: 0,
    dwell: 9,
    moving: false,
    visible: true,
  });
  return [
    job(
      "TÉCNICO DE PISTA",
      [
        [-27, 30, -Math.PI / 2],
        [-25, 34, Math.PI / 2],
      ],
      "repair",
    ),
    job(
      "TÉCNICA DE PISTA",
      [
        [27, 46, Math.PI / 2],
        [25, 50, -Math.PI / 2],
      ],
      "repair",
    ),
    job(
      "INSPEÇÃO",
      [
        [-27, 72, -Math.PI / 2],
        [-25, 76, Math.PI / 2],
      ],
      "scan",
    ),
    job(
      "ENGENHARIA",
      [
        [46.7, 21, Math.PI / 2],
        [46.7, 27, Math.PI / 2],
      ],
      "repair",
    ),
    job(
      "MEDICINA",
      [
        [-46.2, 56, -Math.PI / 2],
        [-46.2, 62, -Math.PI / 2],
      ],
      "scan",
    ),
    job(
      "SUPRIMENTOS",
      [
        [-46.4, 24, -Math.PI / 2],
        [-45, 28, 0],
      ],
      "scan",
    ),
    job(
      "COMUNICAÇÕES",
      [
        [45.4, 58, Math.PI / 2],
        [45.4, 66, Math.PI / 2],
      ],
      "typing",
    ),
    job(
      "CONTROLE DE VOO",
      [
        [22, 88, 0],
        [22, 88, 0],
      ],
      "typing",
      2.8,
    ),
    job(
      "NAVEGAÇÃO",
      [
        [26, 88, 0],
        [26, 88, 0],
      ],
      "typing",
      2.8,
    ),
    job(
      "SENSORES",
      [
        [30, 88, 0],
        [30, 88, 0],
      ],
      "typing",
      2.8,
    ),
    job(
      "SUPERVISÃO",
      [
        [20.5, 74, Math.PI / 2],
        [20.5, 80, Math.PI / 2],
      ],
      "typing",
      2.8,
    ),
  ];
}
export function updateStationWorkers(workers, dt, ships = null) {
  for (const [index, p] of workers.entries()) {
    p.elapsed += dt;
    const away = ships && index < 3 && ships[index].state !== "service";
    if (away) p.station = 0;
    const target = p.stations[p.station];
    if (movePerson(p, target[0], target[1], dt, 1.2)) {
      p.yaw = target[2];
      p.moving = false;
      p.action = index < 3 && p.station === 0 ? "typing" : p.workingAction;
      if (!away && p.elapsed > p.dwell) {
        p.station = (p.station + 1) % p.stations.length;
        p.elapsed = 0;
      }
    } else p.action = "walking";
    if (!p.moving) p.phase += dt * 2.5;
  }
}
