import { spawn } from "node:child_process";
import { readFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../", import.meta.url));
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  cwd: root,
  env: { ...process.env, PORT: "8777" },
  stdio: ["ignore", "pipe", "inherit"],
});
await new Promise((r) => server.stdout.once("data", r));
let browser;
try {
  browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || "/usr/bin/chromium",
    headless: true,
    args: [
      "--no-sandbox",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
    ],
  });
  mkdirSync("/tmp/prf-command", { recursive: true });
  for (const mobile of [true, false]) {
    const context = await browser.newContext({
      viewport: mobile
        ? { width: 844, height: 390 }
        : { width: 1280, height: 720 },
      isMobile: mobile,
      hasTouch: mobile,
    });
    const p = await context.newPage(),
      errors = [];
    p.on("pageerror", (e) => errors.push(e.message));
    await p.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (url.hostname !== "127.0.0.1") return route.abort();
      if (url.pathname === "/main.js") {
        const src = readFileSync(root + "main.js", "utf8").replace(
          "// BROWSER_TEST_HOOK",
          `window.commandTest={
          ready(){return world.avatar.status==='ready'&&world.crew.status==='ready'},
          snapshot(){return {time:sim.time,paused:sim.paused,hidden:document.hidden,clock:{...sim.clock},player:{...sim.player},mission:JSON.parse(JSON.stringify(sim.command.mission)),agents:sim.command.agents.map(a=>({id:a.id,name:a.name,x:a.x,z:a.z,task:a.task,visible:a.visible})),lights:environment.lights.map(l=>l.light.intensity),night:environment.night,radio:world.radio.group.visible||world.radio.view.visible,calls:renderer.info.render.calls}},
          near(){const a=sim.command.agents.find(a=>a.id===5);Object.assign(sim.player,{x:a.x,z:a.z-2,yaw:Math.PI});updateHUD()},
          advance(seconds){for(let i=0;i<seconds*20;i++)stepSimulation(sim,.05);environment.update(sim);world.update(sim,.05,null,false);updateHUD()},
          view(hour,inside=false){sim.clock.minute=hour*60;sim.paused=true;environment.update(sim);sim.player.usingRadio=false;sim.player.radioUntil=0;world.update(sim,0,null,false);updateHUD();camera.position.set(inside?27:-24,inside?2.15:5.5,inside?15:-52);camera.lookAt(inside?35:8,inside?1.8:3.8,inside?18:12);renderer.render(scene,camera);return this.snapshot()},
          fresh(){reset()}, freeze(){sim.paused=true}, resume(){sim.paused=false},
          removeHud(){for(const id of ['hud','toolbar','interactions','mobileControls','notice','targetMarker'])document.getElementById(id).hidden=true}
        };`,
        );
        return route.fulfill({ contentType: "text/javascript", body: src });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8777/");
    await p.waitForFunction(() => window.commandTest?.ready(), null, {
      timeout: 90000,
    });
    await p.locator("#exploreBtn").click();
    await p.locator("#radioBtn").click();
    await p.locator("#startCommandMission").click();
    await p.locator("#agentSelect").selectOption("5");
    await p
      .getByRole("button", { name: "Intensificar fiscalização", exact: true })
      .click();
    await p.locator("#agentSelect").selectOption("6");
    await p
      .getByRole("button", { name: "Intensificar fiscalização", exact: true })
      .click();
    const before = await p.evaluate(() => window.commandTest.snapshot());
    await p.keyboard.down("w");
    await p.waitForTimeout(500);
    await p.keyboard.up("w");
    await p.waitForFunction(
      (t) => window.commandTest.snapshot().time > t,
      before.time,
      { timeout: 15000 },
    );
    const after = await p.evaluate(() => window.commandTest.snapshot());
    assert.equal(after.player.x, before.player.x);
    assert.equal(after.player.z, before.player.z);
    assert(after.time > before.time);
    assert(after.radio);
    await p.screenshot({
      path: `/tmp/prf-command/command-${mobile ? "mobile" : "desktop"}.png`,
    });
    await p.locator("#closeCommand").click();
    await p.evaluate(() => window.commandTest.advance(180));
    const mission = await p.evaluate(
      () => window.commandTest.snapshot().mission,
    );
    assert.equal(mission.stage, "complete");
    await p.evaluate(() => window.commandTest.near());
    await p.locator("#actionBtn").click();
    assert.match(
      await p.locator("#commandChannel").textContent(),
      /PRESENCIAL.*Silva/,
    );
    await p
      .getByRole("button", {
        name: "Informar situação pelo rádio",
        exact: true,
      })
      .click();
    await p.locator("#closeCommand").click();
    await p.keyboard.press("t");
    assert(await p.locator("#commandDialog").isVisible());
    await p.keyboard.press("Escape");
    assert(!(await p.locator("#commandDialog").isVisible()));
    await p.evaluate(() => window.commandTest.fresh());
    await p.locator("#radioBtn").click();
    await p.locator("#agentSelect").selectOption("8");
    await p
      .getByRole("button", {
        name: "Inspecionar perímetro da base",
        exact: true,
      })
      .click();
    await p.locator("#closeCommand").click();
    const start = await p.evaluate(() =>
      window.commandTest.snapshot().agents.find((a) => a.id === 8),
    );
    await p.evaluate(() => window.commandTest.advance(8));
    const moved = await p.evaluate(() =>
      window.commandTest.snapshot().agents.find((a) => a.id === 8),
    );
    assert(Math.hypot(moved.x - start.x, moved.z - start.z) > 2);
    const day = await p.evaluate(() => window.commandTest.view(12));
    assert(day.lights.every((v) => v === 0));
    await p.evaluate(() => window.commandTest.removeHud());
    await p.screenshot({
      path: `/tmp/prf-command/day-${mobile ? "mobile" : "desktop"}.png`,
    });
    const night = await p.evaluate(() => window.commandTest.view(21));
    assert(night.lights.every((v) => v > 0));
    assert.equal(night.night, 1);
    assert(night.calls < 700);
    await p.screenshot({
      path: `/tmp/prf-command/night-${mobile ? "mobile" : "desktop"}.png`,
    });
    await p.evaluate(() => window.commandTest.view(21, true));
    await p.screenshot({
      path: `/tmp/prf-command/office-night-${mobile ? "mobile" : "desktop"}.png`,
    });
    const clock = await p.evaluate(
      () => window.commandTest.snapshot().clock.minute,
    );
    await p.waitForTimeout(300);
    assert.equal(
      await p.evaluate(() => window.commandTest.snapshot().clock.minute),
      clock,
    );
    assert.deepEqual(errors, []);
    console.log(
      JSON.stringify({
        mobile,
        mission,
        dayLights: day.lights,
        nightLights: night.lights,
        calls: night.calls,
        agentMovement: Math.hypot(moved.x - start.x, moved.z - start.z),
        errors,
      }),
    );
    await context.close();
  }
} finally {
  await browser?.close();
  server.kill();
}
