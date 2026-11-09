import test from "node:test";
import assert from "node:assert/strict";
import {
  ROOMS,
  inWalkableArea,
  blockedByDoor,
  moveWalker,
  FLOOR_Y,
  EYE_HEIGHT,
  UPPER_FLOOR,
  walkFloorAt,
} from "../station-layout.js";

test("hangar boundaries have openings only at the four room doors", () => {
  assert(inWalkableArea(0, 0));
  assert(!inWalkableArea(0, 96));
  assert(!inWalkableArea(0, -16));
  for (const room of ROOMS) {
    assert(inWalkableArea(room.side * 34, room.z));
    assert(inWalkableArea(room.side * 44, room.z));
    assert(!inWalkableArea(room.side * 34, room.z + 4));
    assert(!inWalkableArea(room.side * 54, room.z));
  }
});
test("the ramp provides continuous access to level two and railings prevent stepping off", () => {
  const p = { x: 29.5, y: FLOOR_Y + EYE_HEIGHT, z: -11 };
  moveWalker(p, 0, 74, []);
  assert(p.z > 62);
  assert(Math.abs(p.y - UPPER_FLOOR - EYE_HEIGHT) < 0.01);
  moveWalker(p, -8, 0, []);
  assert(p.x < 23);
  moveWalker(p, 0, 25, []);
  assert(p.z > 86);
  moveWalker(p, 0, 25, []);
  assert(p.z < 94.4);
  moveWalker(p, -20, 0, []);
  assert(p.x > 18.4);
  assert.equal(walkFloorAt(20, 80, FLOOR_Y), FLOOR_Y); // Ground remains usable underneath.
  assert.equal(walkFloorAt(29.5, 10, FLOOR_Y), null); // Cannot enter the raised ramp sideways.
  moveWalker(p, 29.5 - p.x, 0, []);
  moveWalker(p, 0, 19 - p.z, []);
  moveWalker(p, 0, -30, []);
  assert(Math.abs(p.y - FLOOR_Y - EYE_HEIGHT) < 0.01);
});
test("a closed or partly open door blocks the player until the gap is wide enough", () => {
  const door = { side: 1, z: 24, open: 0 };
  assert(blockedByDoor(34, 24, [door]));
  door.open = 0.05;
  assert(blockedByDoor(34, 24, [door]));
  door.open = 1;
  assert(!blockedByDoor(34, 24, [door]));
  assert(blockedByDoor(34, 26.2, [door]));
});
test("walking cannot tunnel through walls, doors or furniture and can slide along walls", () => {
  const p = { x: 30, z: 24 },
    doors = [{ side: 1, z: 24, open: 0 }];
  moveWalker(p, 15, 0, doors);
  assert(p.x < 34);
  doors[0].open = 1;
  moveWalker(p, 15, 0, doors);
  assert(p.x > 44);
  moveWalker(p, 30, 0, doors);
  assert(p.x < 54);
  const wall = { x: 32, z: 40 };
  moveWalker(wall, 10, 8, doors);
  assert(wall.x < 33.4);
  assert(wall.z > 47);
  const furniture = { x: 0, z: 0 };
  moveWalker(furniture, 10, 0, [], [{ x: 5, z: 0, hx: 1, hz: 1 }]);
  assert(furniture.x < 3.7);
});
