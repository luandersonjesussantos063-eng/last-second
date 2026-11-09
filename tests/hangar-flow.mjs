import assert from "node:assert/strict";
import fs from "node:fs/promises";
import { ROOMS } from "../station-layout.js";

async function face(p, yaw) {
  await p.evaluate((target) => {
    const canvas = document.querySelector("canvas");
    const dx = (window.__stationTest.state().cameraYaw - target) / 0.003;
    canvas.dispatchEvent(
      new PointerEvent("pointerdown", {
        pointerId: 81,
        pointerType: "touch",
        clientX: 500,
        clientY: 180,
      }),
    );
    canvas.dispatchEvent(
      new PointerEvent("pointermove", {
        pointerId: 81,
        pointerType: "touch",
        clientX: 500 + dx,
        clientY: 180,
      }),
    );
    canvas.dispatchEvent(
      new PointerEvent("pointerup", { pointerId: 81, pointerType: "touch" }),
    );
    window.__gameTest.advance(0.05);
  }, yaw);
  assert(
    Math.abs(
      (await p.evaluate(() => window.__stationTest.state())).cameraYaw - yaw,
    ) < 0.001,
  );
}

export async function testHangarFlow(p, mobile) {
  await p.locator("#exploreBtn").click();
  await p.evaluate(() => window.__gameTest.advance(0.1));
  let state = await p.evaluate(() => window.__stationTest.state());
  assert(state.active);
  assert.deepEqual([...new Set(state.profiles)].sort(), [
    "control",
    "mechanic",
    "medical",
    "police",
    "supplies",
  ]);
  assert.equal(state.cameraParent, "scene");
  assert(!state.shipVisible);
  assert(await p.locator("#interactButton").isVisible());
  assert.equal(await p.locator("#walkPad").isVisible(), mobile);
  await p.waitForFunction(
    () =>
      getComputedStyle(document.getElementById("menu")).visibility === "hidden",
  );
  await fs.mkdir("/tmp/last-second-hangar", { recursive: true });
  await p.screenshot({
    path: `/tmp/last-second-hangar/start-${mobile ? "mobile" : "desktop"}.png`,
  });
  // Exercise the same drag-to-look input as the player before walking.
  await face(p, -Math.PI / 2);
  const crew = state.crew;
  // Walking is a separate mode: no takeoff from the floor.
  await p.keyboard.press("l");
  assert.equal(
    (await p.evaluate(() => window.__gameTest.state())).landingState,
    "parked",
  );
  await p.keyboard.down("w");
  await p.evaluate(() => window.__gameTest.advance(1));
  await p.keyboard.up("w");
  state = await p.evaluate(() => window.__stationTest.state());
  assert(state.position[0] > 10);
  assert.notDeepEqual(state.crew, crew);
  await p.keyboard.press("e");
  assert((await p.evaluate(() => window.__stationTest.state())).active);
  await p.locator("#pauseBtn").click();
  const paused = await p.evaluate(() => window.__stationTest.state());
  await p.evaluate(() => window.__gameTest.advance(5));
  assert.deepEqual(
    await p.evaluate(() => window.__stationTest.state()),
    paused,
  );
  await p.locator("#volumeRange").evaluate((el) => {
    el.value = "35";
    el.dispatchEvent(new Event("input", { bubbles: true }));
  });
  assert.equal(
    (await p.evaluate(() => window.__audioTest.state())).volume,
    0.35,
  );
  assert.equal(
    (await p.evaluate(() => window.__audioTest.state())).context,
    "suspended",
  );
  await p.locator("#volumeRange").evaluate((el) => {
    el.value = "55";
    el.dispatchEvent(new Event("input", { bubbles: true }));
  });
  await p.locator("#resumeBtn").click();
  if (mobile) {
    const rect = await p.locator("#walkPad").boundingBox();
    await p.locator("#walkPad").dispatchEvent("pointerdown", {
      pointerId: 51,
      pointerType: "touch",
      clientX: rect.x + rect.width / 2,
      clientY: rect.y + 8,
      bubbles: true,
    });
    const before = (await p.evaluate(() => window.__stationTest.state()))
      .position;
    await p.evaluate(() => window.__gameTest.advance(1));
    assert(
      (await p.evaluate(() => window.__stationTest.state())).position[0] >
        before[0] + 2,
    );
    await p
      .locator("#walkPad")
      .dispatchEvent("pointercancel", { pointerId: 51, bubbles: true });
    const after = (await p.evaluate(() => window.__stationTest.state()))
      .position;
    await p.evaluate(() => window.__gameTest.advance(1));
    assert.deepEqual(
      (await p.evaluate(() => window.__stationTest.state())).position,
      after,
    );
  }
  for (const room of ROOMS) {
    await p.evaluate(
      ({ side, z }) => window.__stationTest.warp(side * 30, z),
      room,
    );
    const key = room.side > 0 ? "w" : "s";
    await p.keyboard.down(key);
    await p.evaluate(() => window.__gameTest.advance(3));
    await p.keyboard.up(key);
    state = await p.evaluate(() => window.__stationTest.state());
    assert(
      state.position[0] * room.side > 38,
      room.name + " must be accessible",
    );
    assert.equal(await p.locator("#walkZone").textContent(), room.name);
    if (room.kind === "command") {
      await p.evaluate(() => window.__stationTest.render());
      await p.screenshot({
        path: `/tmp/last-second-hangar/command-${mobile ? "mobile" : "desktop"}.png`,
      });
    }
    assert(
      state.doors.find((d) => d.side === room.side && d.z === room.z).open >
        0.95,
    );
    // Player standing in the passage prevents closing, even after many seconds.
    await p.evaluate(
      ({ side, z }) => window.__stationTest.warp(side * 34, z),
      room,
    );
    await p.evaluate(() => window.__gameTest.advance(4));
    assert(
      (await p.evaluate(() => window.__stationTest.state())).doors.find(
        (d) => d.side === room.side && d.z === room.z,
      ).open > 0.99,
    );
  }
  await p.evaluate(() => {
    window.__stationTest.warp(15, 35);
    window.__gameTest.advance(6);
  });
  assert(
    (await p.evaluate(() => window.__stationTest.state())).doors.every(
      (d) => d.open < 0.01,
    ),
  );
  // Reach the upper command centre through the actual ramp using player inputs.
  await p.evaluate(() => {
    window.__stationTest.warp(29.5, -11);
    window.__gameTest.advance(0.05);
  });
  await face(p, Math.PI);
  await p.keyboard.down("w");
  await p.evaluate(() => window.__gameTest.advance(23));
  await p.keyboard.up("w");
  state = await p.evaluate(() => window.__stationTest.state());
  assert(state.position[2] > 62);
  assert(Math.abs(state.position[1] - 4.45) < 0.02);
  assert.match(
    await p.locator("#walkZone").textContent(),
    /CENTRAL DE COMANDO/,
  );
  await p.keyboard.down("w");
  await p.evaluate(() => window.__gameTest.advance(6));
  await p.keyboard.up("w");
  await p.evaluate(() => window.__stationTest.render());
  await p.screenshot({
    path: `/tmp/last-second-hangar/upper-${mobile ? "mobile" : "desktop"}.png`,
  });
  // Continue for enough simulated time to observe full autonomous flight cycles.
  await p.evaluate(() => window.__gameTest.advance(220));
  state = await p.evaluate(() => window.__stationTest.state());
  assert(state.completedFlights >= 3);
  assert(state.traffic.every((s) => s.cycles >= 1));
  await p.locator("#pauseBtn").click();
  const trafficBefore = await p.evaluate(() => window.__stationTest.state());
  await p.evaluate(() => window.__gameTest.advance(20));
  assert.deepEqual(
    await p.evaluate(() => window.__stationTest.state()),
    trafficBefore,
  );
  await p.locator("#resumeBtn").click();
  await face(p, 0);
  await p.keyboard.down("w");
  await p.evaluate(() => window.__gameTest.advance(35));
  await p.keyboard.up("w");
  state = await p.evaluate(() => window.__stationTest.state());
  assert(state.position[2] < -10);
  assert(Math.abs(state.position[1] + 3.55) < 0.02);
  // Actual render/screenshot, separate from accelerated simulation steps.
  await p.evaluate(() => window.__stationTest.warp(18, 16));
  await p.evaluate(() => window.__gameTest.advance(0.1));
  await face(p, -Math.PI * 0.85);
  const render = await p.evaluate(() => window.__stationTest.render());
  await fs.mkdir("/tmp/last-second-hangar", { recursive: true });
  await p.screenshot({
    path: `/tmp/last-second-hangar/${mobile ? "mobile" : "desktop"}.png`,
  });
  console.log(
    JSON.stringify({
      mobile,
      hangar:
        "rooms, proximity doors, crew, walking, pause, collision boundaries",
      render,
    }),
  );
  await p.evaluate(() => {
    window.__stationTest.warp(7.4, 10);
    window.__gameTest.advance(0.1);
  });
  await p.locator("#interactButton").click();
  state = await p.evaluate(() => window.__stationTest.state());
  assert(!state.active);
  assert.equal(state.cameraParent, "ship");
  assert(state.shipVisible);
  // Exit again using E, then board with the visible touch-compatible button.
  await p.keyboard.press("e");
  assert((await p.evaluate(() => window.__stationTest.state())).active);
  await p.locator("#interactButton").click();
  await p.keyboard.press("l");
  await p.evaluate(() => {
    for (
      let i = 0;
      i < 3000 && window.__gameTest.state().launchState === "queued";
      i++
    )
      window.__gameTest.advance(1 / 60);
  });
  assert.equal(
    (await p.evaluate(() => window.__gameTest.state())).launchState,
    "launching",
  );
}
