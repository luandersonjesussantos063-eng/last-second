import { spawn } from "node:child_process";
import { readFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../", import.meta.url));
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  cwd: root,
  env: { ...process.env, PORT: "8775" },
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
  mkdirSync("/tmp/prf-avatar", { recursive: true });
  for (const mobile of [true, false]) {
    const c = await browser.newContext({
      viewport: mobile
        ? { width: 844, height: 390 }
        : { width: 1280, height: 720 },
      isMobile: mobile,
      hasTouch: mobile,
    });
    const p = await c.newPage();
    const errors = [],
      external = [];
    p.on("pageerror", (e) => errors.push(e.message));
    await p.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (url.hostname !== "127.0.0.1") {
        external.push(url.href);
        return route.abort();
      }
      if (url.pathname === "/main.js") {
        const source = readFileSync(root + "main.js", "utf8").replace(
          "// BROWSER_TEST_HOOK",
          `window.avatarTest={state(){return {status:world.avatar.status,error:world.avatar.error,stats:world.avatar.stats,animation:world.avatar.animation,visible:world.avatar.group.visible};},pose(name,time=0,back=false){sim.paused=true;sim.mode='foot';sim.reception.seated=false;sim.player.rifleEquipped=name.startsWith('Rifle');Object.assign(sim.player,{x:27,z:0,yaw:Math.PI,moving:false});world.update(sim,0,null,false);world.avatar.mixer.stopAllAction();world.avatar.actions[name].reset().play();world.avatar.mixer.update(time);world.avatar.group.updateMatrixWorld(true);world.avatar.group.traverse(o=>{if(o.isSkinnedMesh)o.computeBoundingBox();});const bounds=new T.Box3().setFromObject(world.avatar.group);camera.position.set(back?29:24,1.65,back?-3:3.3);camera.lookAt(27,1.0,0);renderer.render(scene,camera);const bones=[];world.avatar.group.traverse(o=>{if(o.isBone&&/Head$|Hand$|Foot$/.test(o.name))bones.push([o.name,...o.getWorldPosition(new T.Vector3()).toArray()]);});return {size:bounds.getSize(new T.Vector3()).toArray(),min:bounds.min.toArray(),bones};},tick(kind){sim.paused=false;sim.mode='foot';sim.reception.seated=kind==='Seated';sim.radar=false;sim.inspection=kind==='Documents';sim.player.gestureUntil=0;sim.player.rifleEquipped=kind.startsWith('Rifle');sim.player.moving=/Walk$|Run$/.test(kind);sim.player.running=kind.endsWith('Run');for(let i=0;i<30;i++){sim.player.distance+=kind==='Run'?.09:.05;world.avatar.update(sim,1/60,false);}return {animation:world.avatar.animation,visible:world.avatar.group.visible};},hide(kind){sim.mode=kind==='drive'?'drive':'foot';world.avatar.update(sim,0,kind==='first');return world.avatar.group.visible;}};`,
        );
        return route.fulfill({ contentType: "text/javascript", body: source });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8775/");
    await p.waitForFunction(
      () => window.avatarTest && window.avatarTest.state().status !== "loading",
      null,
      { timeout: 60000 },
    );
    const state = await p.evaluate(() => window.avatarTest.state());
    assert.equal(state.status, "ready", state.error);
    assert(state.stats.skinned >= 1);
    assert(state.stats.triangles < 20000);
    assert(state.stats.bones >= 40);
    await p.locator("#exploreBtn").click();
    await p.evaluate(() => {
      for (const id of [
        "hud",
        "toolbar",
        "interactions",
        "mobileControls",
        "notice",
        "targetMarker",
      ])
        document.getElementById(id).hidden = true;
    });
    for (const action of [
      "Idle",
      "Walk",
      "Run",
      "Documents",
      "Seated",
      "Signal",
      "RifleIdle",
      "RifleWalk",
      "RifleRun",
    ]) {
      const pose = await p.evaluate(
        (action) => window.avatarTest.pose(action, 0.4),
        action,
      );
      console.log(JSON.stringify({ mobile, action, ...pose }));
      assert(pose.size.every(Number.isFinite));
      assert(pose.size[1] > 0.8 && pose.size[1] < 2.7);
      assert(pose.size[0] < 2.5 && pose.size[2] < 2.5);
      await p.screenshot({
        path: `/tmp/prf-avatar/${action.toLowerCase()}-${mobile ? "mobile" : "desktop"}.png`,
      });
    }
    await p.evaluate(() => window.avatarTest.pose("Idle", 0.4, true));
    await p.screenshot({
      path: `/tmp/prf-avatar/back-${mobile ? "mobile" : "desktop"}.png`,
    });
    for (const kind of ["Walk", "Run", "Documents", "Seated", "Idle"])
      assert.equal(
        (await p.evaluate((kind) => window.avatarTest.tick(kind), kind))
          .animation,
        kind,
      );
    assert.equal(
      await p.evaluate(() => window.avatarTest.hide("drive")),
      false,
    );
    assert.equal(
      await p.evaluate(() => window.avatarTest.hide("first")),
      false,
    );
    assert.deepEqual(errors, []);
    assert.deepEqual(external, []);
    await c.close();
  }
  // Missing asset is a supported path: the procedural player remains usable.
  const p = await browser.newPage();
  await p.route("**/assets/models/prf-agent.glb*", (r) =>
    r.fulfill({ status: 404, body: "missing" }),
  );
  await p.goto("http://127.0.0.1:8775/");
  await p.waitForFunction(
    () => !document.getElementById("exploreBtn").disabled,
  );
  await p.waitForFunction(() =>
    document.getElementById("loadStatus").textContent.includes("leve ativo"),
  );
  await p.locator("#exploreBtn").click();
  assert(await p.locator("#hud").isVisible());
  await p.close();
} finally {
  await browser?.close();
  server.kill();
}
