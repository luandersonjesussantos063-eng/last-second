import test from "node:test";
import assert from "node:assert/strict";
import {
  ROOMS,
  inWalkableArea,
  blockedByDoor,
  moveWalker,
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
