import { spawn } from "node:child_process";
import { readFileSync, mkdirSync } from "node:fs";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  env: { ...process.env, PORT: "8779" },
  stdio: ["ignore", "pipe", "inherit"],
});
await new Promise((r) => server.stdout.once("data", r));
let browser;
try {
  browser = await chromium.launch({
    executablePath: "/usr/bin/chromium",
    headless: true,
    args: [
      "--no-sandbox",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
    ],
  });
  mkdirSync("/tmp/prf-world", { recursive: true });
  for (const mobile of [true, false]) {
    const ctx = await browser.newContext({
        viewport: mobile
          ? { width: 844, height: 390 }
          : { width: 1280, height: 720 },
        isMobile: mobile,
        hasTouch: mobile,
      }),
      p = await ctx.newPage(),
      errors = [];
    p.on("pageerror", (e) => errors.push(e.message));
    await p.route("**/*", (route) => {
      const u = new URL(route.request().url());
      if (u.hostname !== "127.0.0.1") return route.abort();
      if (u.pathname === "/main.js") {
        const s = readFileSync("main.js", "utf8").replace(
          "// BROWSER_TEST_HOOK",
          `window.worldTest={ready(){return ready&&world.avatar.status==='ready'&&world.crew.status==='ready'},tick(n){sim.paused=false;for(let i=0;i<n*20;i++)stepSimulation(sim,.05);world.update(sim,.05,null,false);updateHUD()},state(){return {weather:sim.operations.weather.kind,scale:sim.weighbridge.stage,weight:sim.weighbridge.report?.grossKg,stage:sim.incident.stage,completed:sim.copom.completed,save:sim.operations.saveStatus}},goScale(){sim.mode='foot';sim.car.speed=0;document.getElementById('weighDemoBtn').click();sim.paused=false;updateHUD()},goIncident(){sim.mode='foot';sim.car.speed=0;document.getElementById('incidentDemoBtn').click();sim.paused=false;updateHUD()},cityDrive(){sim.paused=false;sim.mode='drive';sim.escort.stage='idle';Object.assign(sim.car,{x:6,z:-500,heading:Math.PI/2,speed:8});const x=sim.car.x;for(let i=0;i<100;i++)stepSimulation(sim,.05,{throttle:1,steer:0});updateHUD();return sim.car.x-x},view(kind){sim.paused=true;environment.update(sim);weatherWorld.update(sim,.05);world.update(sim,0,null,false);if(kind==='city'){camera.position.set(75,20,-550);camera.lookAt(165,1,-500)}else if(kind==='scale'){camera.position.set(40,12,-87);camera.lookAt(65,1,-60)}else{camera.position.set(sim.incident.site.x-18,8,sim.incident.site.z-24);camera.lookAt(sim.incident.site.x,1,sim.incident.site.z)}renderer.render(scene,camera)},resume(){sim.paused=false},finish(){return sim.incident.stage==='resolved'}};`,
        );
        return route.fulfill({ contentType: "text/javascript", body: s });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8779/");
    await p.waitForFunction(() => window.worldTest?.ready(), null, {
      timeout: 120000,
    });
    await p.locator("#exploreBtn").click();
    await p.locator("#tabletBtn").click();
    await p.locator("#weatherSelect").selectOption("rain");
    await p.locator("#destinationSelect").selectOption("serra-fuel");
    await p.locator("#saveCareerBtn").click();
    assert.match(await p.locator("#saveStatus").textContent(), /salva/i);
    await p.screenshot({ path: `/tmp/prf-world/tablet-${mobile}.png` });
    await p.locator("#closeOperations").click();
    assert.equal(
      (await p.evaluate(() => window.worldTest.state())).weather,
      "rain",
    );
    const moved = await p.evaluate(() => window.worldTest.cityDrive());
    assert(moved > 35);
    await p.evaluate(() => window.worldTest.view("city"));
    await p.screenshot({ path: `/tmp/prf-world/city-${mobile}.png` });
    await p.evaluate(() => window.worldTest.goScale());
    await p.locator("#actionBtn").click();
    await p.evaluate(() => window.worldTest.tick(7));
    let w = await p.evaluate(() => window.worldTest.state());
    assert.equal(w.scale, "weighed");
    assert(w.weight > 50000);
    await p.evaluate(() => window.worldTest.view("scale"));
    await p.screenshot({ path: `/tmp/prf-world/scale-${mobile}.png` });
    await p.evaluate(() => window.worldTest.resume());
    await p.locator("#actionBtn").click();
    await p.evaluate(() => window.worldTest.tick(65));
    await p.evaluate(() => window.worldTest.goIncident());
    await p.locator("#actionBtn").click();
    await p.locator("#actionBtn").click();
    await p.evaluate(() => window.worldTest.tick(65));
    await p.locator("#actionBtn").click();
    await p.evaluate(() => window.worldTest.tick(20));
    await p.locator("#actionBtn").click();
    await p.evaluate(() => window.worldTest.tick(25));
    assert(await p.evaluate(() => window.worldTest.finish()));
    await p.evaluate(() => window.worldTest.view("incident"));
    await p.screenshot({ path: `/tmp/prf-world/incident-${mobile}.png` });
    await p.evaluate(() => window.worldTest.resume());
    await p.locator("#actionBtn").click();
    assert.equal(
      (await p.evaluate(() => window.worldTest.state())).completed,
      1,
    );
    assert.deepEqual(errors, []);
    console.log(JSON.stringify({ mobile, moved, scaleKg: w.weight, errors }));
    await ctx.close();
  }
} finally {
  await browser?.close();
  server.kill();
}
