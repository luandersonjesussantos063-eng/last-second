// Shared geometry and navigation dimensions (metres, X/Z floor plane).
export const FLOOR_Y = -5.2;
export const EYE_HEIGHT = 1.65;
export const PLAYER_RADIUS = 0.32;
export const DOOR_HALF_WIDTH = 2.4;
export const ROOMS = [
  { side: -1, z: 24, name: "ALOJAMENTOS", color: 0x77ddba, kind: "quarters" },
  { side: -1, z: 62, name: "ENFERMARIA", color: 0x91ceff, kind: "medical" },
  { side: 1, z: 24, name: "OFICINA", color: 0xffbe73, kind: "workshop" },
  { side: 1, z: 62, name: "COMANDO", color: 0x82b7ff, kind: "command" },
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

export function moveWalker(position, dx, dz, doors, props = []) {
  // Small swept steps prevent tunnelling and permit sliding along a wall.
  const steps = Math.max(1, Math.ceil(Math.hypot(dx, dz) / 0.12));
  const canMove = (x, z) =>
    inWalkableArea(x, z) &&
    !blockedByDoor(x, z, doors) &&
    !blockedByProp(x, z, props);
  for (let i = 0; i < steps; i++) {
    const x = position.x + dx / steps;
    if (canMove(x, position.z)) position.x = x;
    const z = position.z + dz / steps;
    if (canMove(position.x, z)) position.z = z;
  }
  return position;
}
