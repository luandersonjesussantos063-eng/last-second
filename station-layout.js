// Shared geometry and navigation dimensions (metres, X/Z floor plane).
export const FLOOR_Y = -5.2;
export const EYE_HEIGHT = 1.65;
export const PLAYER_RADIUS = 0.32;
export const DOOR_HALF_WIDTH = 2.4;
export const UPPER_FLOOR = 2.8;
export const RAMP = { minX: 27.4, maxX: 31.8, minZ: -10, maxZ: 18 };
export const ROOMS = [
  { side: -1, z: 24, name: "ALOJAMENTOS", color: 0x77ddba, kind: "quarters" },
  { side: -1, z: 62, name: "ENFERMARIA", color: 0x91ceff, kind: "medical" },
  { side: 1, z: 24, name: "OFICINA", color: 0xffbe73, kind: "workshop" },
  { side: 1, z: 62, name: "COMUNICAÇÕES", color: 0x82b7ff, kind: "command" },
];

export function inWalkableArea(x, z, radius = PLAYER_RADIUS) {
  if (Math.abs(x) <= 33.4 - radius && z >= -14.4 + radius && z <= 94.5 - radius)
    return true;
  return ROOMS.some((room) => {
    const localX = x * room.side;
    if (
      localX >= 34.6 + radius &&
      localX <= 53.4 - radius &&
      Math.abs(z - room.z) <= 9.4 - radius
    )
      return true;
    // The wall is solid everywhere except the door opening.
    return (
      localX >= 32.5 &&
      localX <= 35.5 &&
      Math.abs(z - room.z) <= DOOR_HALF_WIDTH - radius
    );
  });
}

export function blockedByDoor(x, z, doors, radius = PLAYER_RADIUS) {
  return doors.some((door) => {
    if (Math.abs(x - door.side * 34) > 0.28 + radius) return false;
    const opening = Math.max(0, door.open * DOOR_HALF_WIDTH - radius);
    return (
      Math.abs(z - door.z) < DOOR_HALF_WIDTH + radius &&
      Math.abs(z - door.z) >= opening
    );
  });
}

export function blockedByProp(x, z, props, radius = PLAYER_RADIUS) {
  return props.some(
    (p) =>
      x > p.x - p.hx - radius &&
      x < p.x + p.hx + radius &&
      z > p.z - p.hz - radius &&
      z < p.z + p.hz + radius,
  );
}

export function walkFloorAt(x, z, fromFloor = FLOOR_Y) {
  const r = PLAYER_RADIUS;
  if (
    x >= RAMP.minX + r &&
    x <= RAMP.maxX - r &&
    z >= RAMP.minZ - r &&
    z <= RAMP.maxZ + r
  ) {
    const height =
      FLOOR_Y +
      (UPPER_FLOOR - FLOOR_Y) *
        Math.max(0, Math.min(1, (z - RAMP.minZ) / (RAMP.maxZ - RAMP.minZ)));
    return Math.abs(height - fromFloor) < 0.22 ? height : null;
  }
  const upper =
    (x >= 27.4 + r && x <= 32.2 - r && z >= 18 - r && z <= 64) ||
    (x >= 18.4 + r && x <= 32.2 - r && z >= 62 + r && z <= 94.4 - r);
  if (upper && Math.abs(fromFloor - UPPER_FLOOR) < 0.22) return UPPER_FLOOR;
  if (Math.abs(fromFloor - FLOOR_Y) < 0.22 && inWalkableArea(x, z))
    return FLOOR_Y;
  return null;
}

export function moveWalker(position, dx, dz, doors, props = []) {
  // Small swept steps prevent tunnelling and permit sliding along a wall.
  const steps = Math.max(1, Math.ceil(Math.hypot(dx, dz) / 0.12));
  let floor = Number.isFinite(position.y) ? position.y - EYE_HEIGHT : FLOOR_Y;
  const canMove = (x, z) => {
    const height = walkFloorAt(x, z, floor);
    return (
      height !== null &&
      (height > 0 || !blockedByDoor(x, z, doors)) &&
      !blockedByProp(
        x,
        z,
        props.filter((p) => Math.abs((p.floor ?? FLOOR_Y) - height) < 0.3),
      )
    );
  };
  for (let i = 0; i < steps; i++) {
    const x = position.x + dx / steps;
    if (canMove(x, position.z)) {
      floor = walkFloorAt(x, position.z, floor);
      position.x = x;
    }
    const z = position.z + dz / steps;
    if (canMove(position.x, z)) {
      floor = walkFloorAt(position.x, z, floor);
      position.z = z;
    }
  }
  if (Number.isFinite(position.y)) position.y = floor + EYE_HEIGHT;
  return position;
}
