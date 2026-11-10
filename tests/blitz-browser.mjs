import { spawn } from "node:child_process";
import { readFileSync, mkdirSync } from "node:fs";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  env: { ...process.env, PORT: "8783" },
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
  mkdirSync("/tmp/prf-blitz", { recursive: true });
  for (const mobile of [true, false]) {
    const c = await browser.newContext({
        viewport: mobile
          ? { width: 844, height: 390 }
          : { width: 1280, height: 720 },
        isMobile: mobile,
        hasTouch: mobile,
      }),
      p = await c.newPage(),
      errors = [];
    p.on("pageerror", (e) => errors.push(e.message));
    await p.route("**/*", (route) => {
      if (new URL(route.request().url()).pathname === "/main.js") {
        const body = readFileSync("main.js", "utf8").replace(
          "// BROWSER_TEST_HOOK",
          `window.blitzTest={ready(){return ready&&world.crew.status==='ready'&&world.avatar.status==='ready'},setup(){sim.mode='foot';sim.paused=false;Object.assign(sim.player,{x:-11,z:20,yaw:0});const t=sim.traffic[2];Object.assign(t,{x:-9,z:20,speed:0,stopped:true});Object.assign(sim.checkpoint,{phase:'active',operationUntil:1000,stage:'checking',vehicleId:2,driverVisible:true});updateHUD()},tick(n){for(let i=0;i<n*20;i++)stepSimulation(sim,.05);world.update(sim,.05,null,false);updateHUD()},state(){return {stage:sim.checkpoint.stage,hold:sim.checkpoint.manualHold,actors:[...world.crew.actors.values()].filter(a=>a.group.visible).map(a=>({weapon:a.weapon?.name??a.group.getObjectByName('Fuzil de serviço')?.name})),log:sim.operations.records,agents:sim.command.agents.map(a=>({id:a.id,task:a.task,duty:a.duty})),search:sim.blitzSearch}},};`,
        );
        return route.fulfill({ contentType: "text/javascript", body });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8783/");
    await p.waitForFunction(() => window.blitzTest?.ready(), null, {
      timeout: 120000,
    });
    await p.locator("#exploreBtn").click();
    await p.evaluate(() => window.blitzTest.setup());
    await p.locator("#actionBtn").click();
    assert(await p.locator("#searchDialog").isVisible());
    await p.locator("#searchCargo").click();
    assert.match(await p.locator("#searchResult").textContent(), /documentos/);
    await p.locator("#searchDocuments").click();
    await p.locator("#searchCabin").click();
    await p.locator("#searchCargo").click();
    await p.evaluate(() => window.blitzTest.tick(15));
    let s = await p.evaluate(() => window.blitzTest.state());
    assert.equal(s.stage, "checking");
    assert(s.hold);
    assert.equal(s.search.checks.length, 3);
    assert(s.actors.length > 0 && s.actors.every((a) => a.weapon));
    await p.screenshot({ path: `/tmp/prf-blitz/search-${mobile}.png` });
    await p.locator("#releaseSearch").click();
    s = await p.evaluate(() => window.blitzTest.state());
    assert.equal(s.stage, "release");
    assert.equal(s.log[0].type, "blitz");
    await p.locator("#agentOrdersBtn").click();
    assert(await p.locator("#commandDialog").isVisible());
    await p.locator("#agentSelect").selectOption("6");
    await p
      .getByRole("button", { name: "Trabalhar na administração", exact: true })
      .click();
    s = await p.evaluate(() => window.blitzTest.state());
    assert.equal(s.agents.find((a) => a.id === 6).duty, "dutyAdmin");
    await p.screenshot({ path: `/tmp/prf-blitz/orders-${mobile}.png` });
    await p.locator("#closeCommand").click();
    assert.deepEqual(errors, []);
    console.log(
      JSON.stringify({ mobile, actors: s.actors.length, checks: 3, errors }),
    );
    await c.close();
  }
} finally {
  await browser?.close();
  server.kill();
}
