import { spawn } from "node:child_process";
import { readFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../", import.meta.url));
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  cwd: root,
  env: { ...process.env, PORT: "8776" },
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
  mkdirSync("/tmp/prf-fleet", { recursive: true });
  for (const mobile of [true, false]) {
    const context = await browser.newContext({
      viewport: mobile
        ? { width: 844, height: 390 }
        : { width: 1280, height: 720 },
      isMobile: mobile,
      hasTouch: mobile,
    });
    const p = await context.newPage(),
      errors = [],
      requests = [];
    p.on("pageerror", (e) => errors.push(e.message));
    await p.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (url.hostname !== "127.0.0.1") return route.abort();
      requests.push(url.pathname);
      if (url.pathname === "/main.js") {
        let src = readFileSync(root + "main.js", "utf8").replace(
          "// BROWSER_TEST_HOOK",
          `window.fleetTest={
      status(){return {avatar:{status:world.avatar.status,error:world.avatar.error},crew:{status:world.crew.status,error:world.crew.error},vehicles:[world.patrol,...world.support,...world.motorcycles].map(m=>m.asset),civilianUnchanged:[...world.traffic,...world.visitorCars].every(m=>!m.asset)};},
      snapshot(kind){sim.paused=true;sim.mode='foot';sim.inspection=false;sim.radar=false;sim.reception.seated=false;sim.player.gestureUntil=0;Object.assign(sim.player,{x:27,z:0,yaw:Math.PI,moving:false,running:false});
        for(const id of ['hud','toolbar','interactions','mobileControls','notice','targetMarker'])document.getElementById(id).hidden=true;
        if(kind==='rider'){sim.life.bikes[0].stage='pursuit';sim.life.bikes[0].x=17;sim.life.bikes[0].z=-23;}
        if(kind==='signal')sim.checkpoint.stage='signal';
        for(let i=0;i<30;i++)world.update(sim,1/30,null,false);
        camera.position.set(25,1.65,2.9);camera.lookAt(27,1.15,0);
        if(kind==='suv'){camera.position.set(24,2.3,-3.5);camera.lookAt(20,1.05,-8);}
        if(kind==='officer'){camera.position.set(13,1.8,-9);camera.lookAt(10.4,1.05,-12);}
        if(kind==='signal'){camera.position.set(-2,1.8,-7);camera.lookAt(-5.7,1.1,-4);}
        if(kind==='bikes'||kind==='rider'){camera.position.set(22,2.4,-27);camera.lookAt(18.2,1.0,-23);}
        if(kind==='first'){sim.firstPerson=true;cameraSnap=true;updateCamera(1/30);world.update(sim,1/30,null,true);}else sim.firstPerson=false;
        renderer.render(scene,camera);const bones={};world.avatar.group.traverse(o=>{if(o.isBone&&/R_Hand$|L_Hand$/.test(o.name))bones[o.name]=o.getWorldPosition(new T.Vector3()).toArray();});
        const gunBounds=[];world.avatar.group.traverse(o=>{if(o.isSkinnedMesh&&o.name.startsWith("HeldRifle")){o.computeBoundingBox();const b=new T.Box3().setFromObject(o);gunBounds.push({name:o.name,min:b.min.toArray(),size:b.getSize(new T.Vector3()).toArray()});}});const fpBounds=new T.Box3();world.avatar.viewArms?.group.traverse(o=>{if(o.isSkinnedMesh&&o.name.startsWith('HeldRifle')){o.computeBoundingBox();fpBounds.union(new T.Box3().setFromObject(o));}});const fpNdc=fpBounds.isEmpty()?null:fpBounds.getCenter(new T.Vector3()).project(camera).toArray();return {fpNdc,gunBounds,armTriangles:world.avatar.viewArms?.armTriangles,animation:world.avatar.animation,held:world.avatar.rifle.held.some(o=>o.visible),slung:world.avatar.rifle.slung.some(o=>o.visible),first:world.avatar.viewArms?.group.visible,bones,stats:{...renderer.info.render},actors:[...world.crew.actors.values()].map(a=>({id:a.id,visible:a.group.visible,animation:a.animation,vest:a.parts.vest.some(o=>o.visible),helmet:a.parts.helmet.some(o=>o.visible)}))};
      },
      lights(time){world.patrol.update({...sim.car,lights:true,wheelSpin:1.3,steering:.2},time);const model=world.patrol.group;const visible=[];model.traverse(o=>{if(o.name.startsWith('Flash')&&o.visible)visible.push(o.name);});return {visible,wheel:model.getObjectByName('WheelFL')?.rotation.x,steering:model.getObjectByName('SteerFL')?.rotation.y};},
      readyForKey(){sim.paused=false;sim.firstPerson=false;sim.reception.seated=false;sim.mode='foot';},equipped(){return sim.player.rifleEquipped;}
    };`,
        );
        return route.fulfill({ contentType: "text/javascript", body: src });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8776/");
    await p.waitForFunction(
      () =>
        window.fleetTest &&
        window.fleetTest.status().avatar.status !== "loading" &&
        window.fleetTest.status().crew.status !== "loading" &&
        window.fleetTest.status().vehicles.every((v) => v.status !== "loading"),
      null,
      { timeout: 90000 },
    );
    const status = await p.evaluate(() => window.fleetTest.status());
    assert.equal(status.avatar.status, "ready", status.avatar.error);
    assert.equal(status.crew.status, "ready", status.crew.error);
    assert(status.vehicles.every((v) => v.status === "ready"));
    assert(status.civilianUnchanged);
    assert.equal(status.vehicles[0].wheels, 4);
    assert.equal(status.vehicles[4].wheels, 2);
    await p.locator("#exploreBtn").click();
    for (const kind of [
      "hero",
      "officer",
      "signal",
      "suv",
      "bikes",
      "rider",
      "first",
    ]) {
      const result = await p.evaluate(
        (kind) => window.fleetTest.snapshot(kind),
        kind,
      );
      console.log(JSON.stringify({ mobile, kind, result }));
      await p.screenshot({
        path:
          "/tmp/prf-fleet/" +
          kind +
          "-" +
          (mobile ? "mobile" : "desktop") +
          ".png",
      });
      assert.equal(result.actors.length, 8);
      if (kind === "hero") {
        assert(result.held);
        assert(
          result.gunBounds.some(
            (b) => Math.max(...b.size) > 0.5 && Math.max(...b.size) < 1.5,
          ),
          "rifle must have a visible, human-scale mesh",
        );
        assert(!result.slung);
        const right = Object.entries(result.bones).find(([n]) =>
            n.includes("R_Hand"),
          )[1],
          left = Object.entries(result.bones).find(([n]) =>
            n.includes("L_Hand"),
          )[1];
        assert(
          right[0] < left[0],
          "carry must not cross the left and right wrists",
        );
      }
      if (kind === "first") {
        assert(result.first);
        assert(result.armTriangles > 500);
        assert(
          result.fpNdc &&
            Math.abs(result.fpNdc[0]) < 1 &&
            Math.abs(result.fpNdc[1]) < 1,
          "first-person rifle must be inside the viewport",
        );
      }
      if (kind === "rider")
        assert.equal(
          result.actors.find((a) => a.id === 16).animation,
          "Riding",
        );
      for (const a of result.actors.filter((a) => a.visible)) {
        assert.equal(a.vest, [5, 6].includes(a.id));
        assert.equal(a.helmet, a.id >= 16);
      }
    }
    const red = await p.evaluate(() => window.fleetTest.lights(0)),
      blue = await p.evaluate(() => window.fleetTest.lights(0.2));
    assert(red.visible.some((n) => n.startsWith("FlashRed")));
    assert(blue.visible.some((n) => n.startsWith("FlashBlue")));
    assert.equal(red.wheel, -1.3);
    assert.equal(red.steering, 0.2);
    await p.evaluate(() => window.fleetTest.readyForKey());
    await p.keyboard.press("v");
    assert.equal(await p.evaluate(() => window.fleetTest.equipped()), false);
    const slung = await p.evaluate(() => window.fleetTest.snapshot("hero"));
    assert(slung.slung && !slung.held);
    await p.screenshot({
      path: "/tmp/prf-fleet/slung-" + (mobile ? "mobile" : "desktop") + ".png",
    });
    for (const file of [
      "prf-agent.glb",
      "prf-officer.glb",
      "prf-suv.glb",
      "prf-motorcycle.glb",
    ])
      assert.equal(
        requests.filter((r) => r.endsWith(file)).length,
        1,
        file + " must download once",
      );
    assert.deepEqual(errors, []);
    await context.close();
  }
} finally {
  await browser?.close();
  server.kill();
}
