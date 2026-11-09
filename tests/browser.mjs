import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import fs from "node:fs";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../", import.meta.url));
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  cwd: root,
  env: { ...process.env, PORT: "8773" },
  stdio: ["ignore", "pipe", "inherit"],
});
await new Promise((resolve, reject) => {
  server.stdout.once("data", resolve);
  server.once("error", reject);
  server.once("exit", (code) => reject(Error("Servidor encerrou: " + code)));
});
let b;
try {
  b = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || "/usr/bin/chromium",
    headless: true,
    args: [
      "--no-sandbox",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
    ],
  });
  let results = [];
  for (const mobile of [true, false]) {
    const c = await b.newContext({
      viewport: mobile
        ? { width: 844, height: 390 }
        : { width: 1280, height: 720 },
      isMobile: mobile,
      hasTouch: mobile,
    });
    const p = await c.newPage(),
      errors = [],
      external = [];
    p.on("pageerror", (e) => errors.push(e.message));
    p.on("console", (m) => {
      if (m.type() === "error") errors.push(m.text());
    });
    await p.route("**/*", async (route) => {
      const url = new URL(route.request().url());
      if (url.hostname !== "127.0.0.1") {
        external.push(url.hostname);
        return route.abort();
      }
      if (url.pathname === "/main.js") {
        let src = fs.readFileSync(
          new URL("../main.js", import.meta.url),
          "utf8",
        );
        src = src.replace(
          'const versionLabel = document.createElement("div");',
          `window.__gameTest={state:()=>({gameTime,gameStarted,gameOver,manualControl,launchState,landingState,health,speed,yaw,paused,turbo,canRequestLanding,touchPointerId,touchSteerX,touchSteerY,keys:[...keys],position:shipRig.position.toArray()}),render:()=>({...renderer.info.render,memory:{...renderer.info.memory}}),advance(seconds){const raf=window.requestAnimationFrame,render=renderer.render;window.requestAnimationFrame=()=>0;renderer.render=()=>{};try{let t=previousTime??performance.now();if(previousTime===null)animate(t);for(let i=0;i<Math.ceil(seconds*60);i++){t+=1000/60;animate(t);}}finally{window.requestAnimationFrame=raf;renderer.render=render;}},safeRocks(){for(const a of asteroids){a.userData.fixedBelt=true;a.position.set(10000,10000,10000);}},rockAtShip(){asteroids[0].userData.fixedBelt=true;asteroids[0].position.copy(shipRig.position);},landing(){shipRig.position.set(0,0,280);hasLeftBase=true;updateLandingAvailability();},destroy(){health=10;gameTime+=2000;hitPlayer();},viewPlanet(){shipRig.position.set(-120,85,500);yaw=0;pitch=0;roll=0;shipRig.rotation.set(0,0,0);renderer.render(scene,camera);}};const versionLabel = document.createElement("div");`,
        );
        return route.fulfill({ contentType: "text/javascript", body: src });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8773/");
    await p.waitForFunction(
      () => window.__gameTest && !document.querySelector("#startBtn").disabled,
      null,
      { timeout: 60000 },
    );
    await p.locator("#howBtn").click();
    assert(
      await p.locator("#howTo").evaluate((e) => e.classList.contains("show")),
    );
    await p.locator("#closeHowBtn").click();
    await p.locator("#qualityBtn").click();
    assert.match(await p.locator("#qualityBtn").textContent(), /ECONÔMICO/);
    await p.locator("#qualityBtn").click();
    await p.locator("#startBtn").click();
    await p.evaluate(() => {
      window.__gameTest.safeRocks();
      window.__gameTest.rockAtShip();
      window.__gameTest.advance(2);
    });
    assert.equal(
      (await p.evaluate(() => window.__gameTest.state())).health,
      100,
    );
    await p.locator("#pauseBtn").click();
    const before = await p.evaluate(() => window.__gameTest.state());
    await p.evaluate(() => window.__gameTest.advance(10));
    let state = await p.evaluate(() => window.__gameTest.state());
    assert.equal(state.gameTime, before.gameTime);
    assert.deepEqual(state.position, before.position);
    await p.locator("#resumeBtn").click();
    await p.evaluate(() => {
      window.__gameTest.safeRocks();
      window.__gameTest.advance(12);
    });
    state = await p.evaluate(() => window.__gameTest.state());
    assert.equal(state.manualControl, true);
    assert(state.position[2] > 100);
    assert.equal(state.health, 100);
    if (mobile) {
      await p.locator("#mobileTurbo").dispatchEvent("pointerdown", {
        pointerId: 11,
        pointerType: "touch",
        bubbles: true,
      });
      await p.evaluate(() => window.__gameTest.advance(2));
      assert((await p.evaluate(() => window.__gameTest.state())).speed > 50);
      await p.locator("#mobileTurbo").dispatchEvent("pointercancel", {
        pointerId: 11,
        pointerType: "touch",
        bubbles: true,
      });
      assert(
        !(await p.evaluate(() => window.__gameTest.state())).keys.includes(
          "ShiftLeft",
        ),
      );
      await p.locator("canvas").first().dispatchEvent("pointerdown", {
        pointerId: 21,
        pointerType: "touch",
        clientX: 200,
        clientY: 150,
        bubbles: true,
      });
      await p.locator("canvas").first().dispatchEvent("pointermove", {
        pointerId: 21,
        pointerType: "touch",
        clientX: 250,
        clientY: 130,
        bubbles: true,
      });
      assert(
        (await p.evaluate(() => window.__gameTest.state())).touchSteerX > 0,
      );
      await p.locator("canvas").first().dispatchEvent("pointerdown", {
        pointerId: 22,
        pointerType: "touch",
        clientX: 400,
        clientY: 150,
        bubbles: true,
      });
      assert.equal(
        (await p.evaluate(() => window.__gameTest.state())).touchPointerId,
        21,
      );
      await p.locator("canvas").first().dispatchEvent("pointercancel", {
        pointerId: 21,
        pointerType: "touch",
        bubbles: true,
      });
      assert.equal(
        (await p.evaluate(() => window.__gameTest.state())).touchSteerX,
        0,
      );
    } else {
      await p.keyboard.down("ArrowRight");
      await p.keyboard.down("Shift");
      await p.evaluate(() => window.__gameTest.advance(2));
      state = await p.evaluate(() => window.__gameTest.state());
      assert(state.yaw < -0.1);
      assert(state.speed > 50);
      await p.keyboard.up("ArrowRight");
      await p.keyboard.up("Shift");
      await p.keyboard.press("p");
      assert((await p.evaluate(() => window.__gameTest.state())).paused);
      await p.keyboard.press("p");
      assert(!(await p.evaluate(() => window.__gameTest.state())).paused);
    }
    await p.evaluate(() => window.__gameTest.landing());
    assert(
      (await p.evaluate(() => window.__gameTest.state())).canRequestLanding,
    );
    await p.locator("#landingButton").dispatchEvent("pointerdown", {
      pointerId: 30,
      pointerType: mobile ? "touch" : "mouse",
      bubbles: true,
    });
    assert.equal(
      (await p.evaluate(() => window.__gameTest.state())).landingState,
      "approach",
    );
    await p.evaluate(() => {
      window.__gameTest.rockAtShip();
      window.__gameTest.advance(12);
    });
    state = await p.evaluate(() => window.__gameTest.state());
    assert.equal(state.landingState, "parked");
    assert.equal(state.health, 100);
    assert.equal(state.speed, 0);
    await p.locator("#landingButton").dispatchEvent("pointerdown", {
      pointerId: 31,
      pointerType: mobile ? "touch" : "mouse",
      bubbles: true,
    });
    assert.equal(
      (await p.evaluate(() => window.__gameTest.state())).launchState,
      "launching",
    );
    await p.evaluate(() => {
      window.__gameTest.safeRocks();
      window.__gameTest.advance(12);
      window.__gameTest.rockAtShip();
      window.__gameTest.advance(0.1);
    });
    assert((await p.evaluate(() => window.__gameTest.state())).health < 100);
    await p.evaluate(() => window.__gameTest.destroy());
    assert((await p.evaluate(() => window.__gameTest.state())).gameOver);
    assert(await p.locator("#retryBtn").isVisible());
    await p.locator("#retryBtn").click();
    state = await p.evaluate(() => window.__gameTest.state());
    assert.equal(state.health, 100);
    assert(!state.gameOver);
    assert.equal(state.launchState, "launching");
    await p.evaluate(() => {
      window.__gameTest.safeRocks();
      window.__gameTest.advance(12);
      window.__gameTest.viewPlanet();
    });
    await p.waitForTimeout(1000);
    assert.deepEqual(external, []);
    assert.deepEqual(errors, []);
    results.push({
      mobile,
      tests:
        "loading, help, quality, takeoff, pause/resume, steering, turbo, input cancel, landing, relaunch, collision, mobile restart, offline dependencies",
      errors,
    });
    console.log(JSON.stringify(results.at(-1)));
    await c.close();
  }
} finally {
  try {
    if (b) await b.close();
  } finally {
    server.kill();
  }
}
