import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { readFileSync, mkdirSync } from "node:fs";
import { chromium } from "playwright";
import assert from "node:assert/strict";
const captureHook =
  "window.__roadTest.installCapture=async()=>{\n  const processor=`class RecordedVoiceMeter extends AudioWorkletProcessor { constructor(){super();this.windows=0;this.peak=0;} process(inputs){const channels=inputs[0];if(channels&&channels.length){let energy=0,n=0;for(const ch of channels)for(const value of ch){energy+=value*value;n++;}this.windows++;this.peak=Math.max(this.peak,n?Math.sqrt(energy/n):0);if(this.windows%4===0)this.port.postMessage({windows:this.windows,peak:this.peak});}return true;}} registerProcessor('recorded-voice-meter',RecordedVoiceMeter);`;\n  const url=URL.createObjectURL(new Blob([processor],{type:'application/javascript'}));\n  await audio.ctx.audioWorklet.addModule(url);URL.revokeObjectURL(url);\n  window.__recordedVoices={};\n  const original=audio.command.bind(audio);let lastVoice=null;\n  audio.command=async(kind)=>{const ok=await original(kind),voice=audio.playback;if(ok&&voice&&voice.kind===kind&&voice!==lastVoice){lastVoice=voice;const node=new AudioWorkletNode(audio.ctx,'recorded-voice-meter'),silent=audio.ctx.createGain();silent.gain.value=0;window.__recordedVoices[kind]={peak:0,windows:0};node.port.onmessage=event=>{const stats=window.__recordedVoices[kind];stats.peak=Math.max(stats.peak,event.data.peak);stats.windows=Math.max(stats.windows,event.data.windows);};voice.gain.connect(node);node.connect(silent);silent.connect(audio.ctx.destination);}return ok;};\n};\nwindow.__roadTest.voiceCapture=kind=>window.__recordedVoices?.[kind]??{peak:0,windows:0};\n";
const root = fileURLToPath(new URL("../", import.meta.url));
const server = spawn(process.execPath, ["scripts/dev-server.mjs"], {
  cwd: root,
  env: { ...process.env, PORT: "8773" },
  stdio: ["ignore", "pipe", "inherit"],
});
await new Promise((resolve, reject) => {
  server.stdout.once("data", resolve);
  server.once("error", reject);
  server.once("exit", (code) => reject(Error("Servidor encerrou " + code)));
});
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
  mkdirSync("/tmp/prf-browser", { recursive: true });
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
      external = [],
      requests = [];
    p.on("pageerror", (e) => errors.push(e.message));
    p.on("console", (m) => {
      if (m.type() === "error") errors.push(m.text());
    });
    await p.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (url.hostname !== "127.0.0.1") {
        external.push(url.hostname);
        return route.abort();
      }
      requests.push(url.pathname);
      if (url.pathname === "/main.js") {
        let source = readFileSync(
          new URL("../main.js", import.meta.url),
          "utf8",
        );
        source = source.replace(
          "// BROWSER_TEST_HOOK",
          `window.__roadTest={state:()=>JSON.parse(JSON.stringify(sim)),advance(seconds){for(let i=0;i<Math.ceil(seconds*60);i++)update(1/60);updateHUD();},foot(x,z,yaw=Math.PI){sim.mode='foot';sim.player.x=x;sim.player.z=z;sim.player.yaw=yaw;sim.player.turnVelocity=0;cameraSnap=true;release();},car(x,z,heading=0){sim.mode='drive';sim.car.x=x;sim.car.z=z;sim.car.heading=heading;sim.car.steering=0;sim.car.speed=0;sim.car.condition=100;cameraSnap=true;release();},screenPoint(u,v){updateCamera(1/60);const m=world.base.computer.mesh;m.updateWorldMatrix(true,false);const p=m.localToWorld(new T.Vector3((u-.5)*1.3,(.5-v)*.74,0)).project(camera);return {x:(p.x*.5+.5)*innerWidth,y:(.5-p.y*.5)*innerHeight};},citizenPoint(){updateCamera(1/60);const v=sim.reception.visitors[sim.reception.active];const p=new T.Vector3(v.x,floorHeight(v.x,v.z)+1.31,v.z).project(camera);const x=(p.x*.5+.5)*innerWidth,y=(.5-p.y*.5)*innerHeight;return {x,y,occluded:!!world.base.computer.hit(camera,x,y,innerWidth,innerHeight)};},viewDetail(kind){sim.paused=true;if(kind==='uniform'){sim.reception.seated=false;sim.player.x=27;sim.player.z=0;sim.player.yaw=Math.PI;world.update(sim,0,null,false);camera.position.set(24,1.8,-3);camera.lookAt(27,1.1,0);}else if(kind==='bikes'){world.motorcycles.forEach((m,i)=>m.update({...sim.life.bikes[i],x:17+i*2.1,z:-23,stage:'ready'},sim.time));camera.position.set(23,2.8,-28);camera.lookAt(18,1,-23);}else{camera.position.set(56,7,-34);camera.lookAt(34,1.5,8);}renderer.render(scene,camera);},avatarState(){return {status:world.avatar.status,error:world.avatar.error,stats:world.avatar.stats};},baseStats(){return {support:world.support.length,people:world.people.count,shadows:renderer.shadowMap.enabled};},viewBase(){camera.position.set(-24,5.5,-52);camera.lookAt(8,3.8,12);renderer.render(scene,camera);return {...renderer.info.render};},roadSide(){updateCamera(1/60);return new T.Vector3(0,0,sim.car.z+25).project(camera).x;},render(){updateCamera(1/60);world.update(sim,0,radarReading(sim),effectiveFirst);renderer.render(scene,camera);return {...renderer.info.render};},audio:()=>({state:audio.ctx?.state,volume:audio.volume,muted:audio.muted,voices:audio.voices,loops:audio.loops.length,clips:Object.keys(audio.buffers),command:audio.playback?.kind,recordedDuration:audio.playback?.source.buffer.duration,loadError:audio.loadError,recordedVoices:audio.recordedVoices,events:{...audio.events}}),signalLevels(){return Object.fromEntries(Object.entries(audio.buffers).map(([kind,b])=>{const d=b.getChannelData(0);let sum=0;for(const v of d)sum+=v*v;return [kind,Math.sqrt(sum/d.length)];}));},recordedMeter(){const a=audio.ctx.createAnalyser(),g=audio.ctx.createGain();g.gain.value=0;audio.playback.gain.connect(a);a.connect(g);g.connect(audio.ctx.destination);window.__recordedMeter=a;},recordedRms(){const d=new Float32Array(window.__recordedMeter.fftSize);window.__recordedMeter.getFloatTimeDomainData(d);return Math.sqrt(d.reduce((s,v)=>s+v*v,0)/d.length);},meter(){const a=audio.ctx.createAnalyser(),g=audio.ctx.createGain();g.gain.value=0;audio.output.connect(a);a.connect(g);g.connect(audio.ctx.destination);window.__meter=a;},rms(){const d=new Float32Array(window.__meter.fftSize);window.__meter.getFloatTimeDomainData(d);return Math.sqrt(d.reduce((s,v)=>s+v*v,0)/d.length);}};`,
        );
        source += "\n" + captureHook;
        return route.fulfill({ contentType: "text/javascript", body: source });
      }
      return route.continue();
    });
    await p.goto("http://127.0.0.1:8773/");
    await p.waitForFunction(
      () => window.__roadTest && !document.getElementById("startBtn").disabled,
      null,
      { timeout: 60000 },
    );
    await p.waitForFunction(
      () => window.__roadTest.avatarState().status !== "loading",
      null,
      { timeout: 60000 },
    );
    assert.equal(
      (await p.evaluate(() => window.__roadTest.avatarState())).status,
      "ready",
    );
    assert.match(await p.title(), /PRF/);
    await p.locator("#helpBtn").click();
    await p.locator("#closeHelp").click();
    await p.locator("#qualityBtn").click();
    assert.match(await p.locator("#qualityBtn").textContent(), /ECONÔMICO/);
    await p.locator("#qualityBtn").click();
    await p.locator("#exploreBtn").click();
    await p.waitForFunction(
      () => window.__roadTest.audio().state === "running",
    );
    await p.evaluate(() => window.__roadTest.installCapture());
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mode,
      "foot",
    );
    await p.evaluate(() => window.__roadTest.render());
    await p.screenshot({
      path: `/tmp/prf-browser/posto-${mobile ? "mobile" : "desktop"}.png`,
    });
    const before = await p.evaluate(() => window.__roadTest.state());
    await p.keyboard.down("w");
    await p.evaluate(() => window.__roadTest.advance(0.6));
    await p.keyboard.up("w");
    assert(
      (await p.evaluate(() => window.__roadTest.state())).player.distance >
        before.player.distance + 1,
    );
    await p.keyboard.down("d");
    await p.evaluate(() => window.__roadTest.advance(0.5));
    await p.keyboard.up("d");
    assert(
      (await p.evaluate(() => window.__roadTest.state())).player.yaw <
        before.player.yaw - 0.4,
    );
    await p.evaluate(() => window.__roadTest.advance(1));
    await p.keyboard.press("p");
    const paused = await p.evaluate(() => window.__roadTest.state());
    await p.evaluate(() => window.__roadTest.advance(4));
    assert.deepEqual(await p.evaluate(() => window.__roadTest.state()), paused);
    await p.locator("#volumeRange").evaluate((el) => {
      el.value = "35";
      el.dispatchEvent(new Event("input", { bubbles: true }));
    });
    assert.equal(
      (await p.evaluate(() => window.__roadTest.audio())).volume,
      0.35,
    );
    assert.equal(
      (await p.evaluate(() => window.__roadTest.audio())).state,
      "suspended",
    );
    await p.locator("#resumeBtn").click();
    await p.evaluate(() => {
      window.__roadTest.foot(10, -10);
      window.__roadTest.advance(0.2);
    });
    await p.keyboard.press("j");
    await p.evaluate(() => window.__roadTest.advance(0.2));
    assert(await p.locator("#radarPanel").isVisible());
    assert.match(await p.locator("#radarValue").textContent(), /km\/h/);
    await p.keyboard.press("e");
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mode,
      "foot",
    );
    await p.evaluate(() => window.__roadTest.foot(21.9, -8));
    await p.keyboard.press("e");
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mode,
      "drive",
    );
    await p.evaluate(() => window.__roadTest.advance(36));
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).escort.stage,
      "aboard",
    );
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).escort.boarded.length,
      3,
    );
    if (mobile) {
      await p.evaluate(() => {
        window.__roadTest.car(-3.4, -150);
        window.__roadTest.advance(0.1);
      });
      await p.locator("#gasBtn").dispatchEvent("pointerdown", {
        pointerId: 91,
        pointerType: "touch",
        bubbles: true,
      });
      await p.evaluate(() => window.__roadTest.advance(1));
      assert((await p.evaluate(() => window.__roadTest.state())).car.speed > 3);
      const r = await p.locator("#walkPad").boundingBox();
      await p.locator("#walkPad").dispatchEvent("pointerdown", {
        pointerId: 92,
        pointerType: "touch",
        clientX: r.x + r.width - 6,
        clientY: r.y + r.height / 2,
        bubbles: true,
      });
      await p.evaluate(() => window.__roadTest.advance(0.5));
      assert(
        (await p.evaluate(() => window.__roadTest.state())).car.heading < 0,
      );
      await p
        .locator("#walkPad")
        .dispatchEvent("pointercancel", { pointerId: 92, bubbles: true });
      await p
        .locator("#gasBtn")
        .dispatchEvent("pointercancel", { pointerId: 91, bubbles: true });
      await p.locator("#brakeBtn").dispatchEvent("pointerdown", {
        pointerId: 93,
        pointerType: "touch",
        bubbles: true,
      });
      await p.evaluate(() => window.__roadTest.advance(0.7));
      assert(
        Math.abs(
          (await p.evaluate(() => window.__roadTest.state())).car.speed,
        ) < 2,
      );
      await p
        .locator("#brakeBtn")
        .dispatchEvent("pointercancel", { pointerId: 93, bubbles: true });
      await p.evaluate(() => window.__roadTest.car(20, -8));
    }
    await p.evaluate(() => window.__roadTest.car(-3.4, -150));
    await p.keyboard.down("w");
    await p.evaluate(() => window.__roadTest.advance(2.5));
    await p.keyboard.down("a");
    await p.evaluate(() => window.__roadTest.advance(0.6));
    await p.keyboard.up("a");
    await p.keyboard.up("w");
    let s = await p.evaluate(() => window.__roadTest.state());
    assert(s.car.speed > 8);
    assert(s.car.heading > 0.1);
    await p.keyboard.press("e");
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mode,
      "drive",
    );
    await p.keyboard.down("Space");
    await p.evaluate(() => window.__roadTest.advance(2));
    await p.keyboard.up("Space");
    assert(
      Math.abs((await p.evaluate(() => window.__roadTest.state())).car.speed) <
        0.1,
    );
    await p.keyboard.press("c");
    await p.evaluate(() => {
      window.__roadTest.advance(0.2);
      window.__roadTest.render();
    });
    assert((await p.evaluate(() => window.__roadTest.state())).car.interior);
    await p.screenshot({
      path: `/tmp/prf-browser/cabine-${mobile ? "mobile" : "desktop"}.png`,
    });
    await p.keyboard.press("c");
    await p.keyboard.press("e");
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mode,
      "foot",
    );
    if (mobile) {
      const r = await p.locator("#walkPad").boundingBox();
      await p.locator("#walkPad").dispatchEvent("pointerdown", {
        pointerId: 71,
        pointerType: "touch",
        clientX: r.x + r.width / 2,
        clientY: r.y + 8,
        bubbles: true,
      });
      const dist = (await p.evaluate(() => window.__roadTest.state())).player
        .distance;
      await p.evaluate(() => window.__roadTest.advance(0.6));
      assert(
        (await p.evaluate(() => window.__roadTest.state())).player.distance >
          dist + 1,
      );
      await p
        .locator("#walkPad")
        .dispatchEvent("pointercancel", { pointerId: 71, bubbles: true });
      const pos = (await p.evaluate(() => window.__roadTest.state())).player;
      await p.evaluate(() => window.__roadTest.advance(0.5));
      const after = (await p.evaluate(() => window.__roadTest.state())).player;
      assert.equal(after.x, pos.x);
      assert.equal(after.z, pos.z);
    }
    await p.evaluate(() => {
      const t = window.__roadTest.state().traffic[0];
      window.__roadTest.car(t.x, t.z - 22);
      window.__roadTest.advance(0.1);
    });
    assert((await p.evaluate(() => window.__roadTest.roadSide())) < 0);
    await p.keyboard.press("g");
    await p.keyboard.press("h");
    await p.waitForFunction(
      (kind) => {
        const capture = window.__roadTest.voiceCapture(kind);
        return (
          window.__roadTest.audio().events[kind] > 0 &&
          capture.windows >= 2 &&
          capture.peak > 0.005
        );
      },
      "perseguicao",
      { timeout: 15000 },
    );
    const capture_perseguicao = await p.evaluate(() =>
      window.__roadTest.voiceCapture("perseguicao"),
    );
    assert(
      capture_perseguicao.windows >= 2 && capture_perseguicao.peak > 0.005,
      "perseguicao: gravação sem sinal",
    );
    assert(
      (await p.evaluate(() => window.__roadTest.audio())).recordedDuration > 1,
    );
    await p.keyboard.press("b");
    await p.waitForFunction(
      (kind) => {
        const capture = window.__roadTest.voiceCapture(kind);
        return (
          window.__roadTest.audio().events[kind] > 0 &&
          capture.windows >= 2 &&
          capture.peak > 0.005
        );
      },
      "passagem",
      { timeout: 15000 },
    );
    const capture_passagem = await p.evaluate(() =>
      window.__roadTest.voiceCapture("passagem"),
    );
    assert(
      capture_passagem.windows >= 2 && capture_passagem.peak > 0.005,
      "passagem: gravação sem sinal",
    );
    await p.waitForFunction(
      () => window.__roadTest.audio().command === "perseguicao",
    );
    await p.evaluate(() => window.__roadTest.advance(0.2));
    assert.equal(
      await p.locator("#sirenBtn").getAttribute("aria-pressed"),
      "true",
    );
    assert(await p.locator("#actionBtn").isVisible());
    await p.locator("#actionBtn").click();
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mission.stage,
      "pullingOver",
    );
    await p.waitForFunction(
      (kind) => {
        const capture = window.__roadTest.voiceCapture(kind);
        return (
          window.__roadTest.audio().events[kind] > 0 &&
          capture.windows >= 2 &&
          capture.peak > 0.005
        );
      },
      "parada",
      { timeout: 15000 },
    );
    const capture_parada = await p.evaluate(() =>
      window.__roadTest.voiceCapture("parada"),
    );
    assert(
      capture_parada.windows >= 2 && capture_parada.peak > 0.005,
      "parada: gravação sem sinal",
    );
    assert(!(await p.evaluate(() => window.__roadTest.state())).car.siren);
    await p.evaluate(() => window.__roadTest.advance(6));
    s = await p.evaluate(() => window.__roadTest.state());
    assert.equal(s.mission.stage, "stopped");
    assert(s.driver.visible);
    await p.evaluate(() => {
      const t = window.__roadTest.state().traffic[0];
      window.__roadTest.car(t.x, t.z - 10);
      window.__roadTest.advance(0.1);
    });
    await p.keyboard.press("e");
    await p.evaluate(() => {
      const t = window.__roadTest.state().traffic[0];
      window.__roadTest.foot(-11.3, t.z - 8);
    });
    await p.keyboard.down("w");
    await p.evaluate(() => window.__roadTest.advance(2.3));
    await p.keyboard.up("w");
    assert(await p.locator("#actionBtn").isVisible());
    await p.locator("#actionBtn").click();
    assert(await p.locator("#inspectionDialog").isVisible());
    assert.match(
      await p.locator("#inspectionChecks").textContent(),
      /CRLV regular/,
    );
    const inspect = await p.evaluate(() => window.__roadTest.state());
    await p.evaluate(() => window.__roadTest.advance(4));
    assert.deepEqual(
      await p.evaluate(() => window.__roadTest.state()),
      inspect,
    );
    await p.locator("#cancelInspectionBtn").click();
    await p.locator("#actionBtn").click();
    await p.locator("#finishInspectionBtn").click();
    await p.evaluate(() => window.__roadTest.advance(4));
    s = await p.evaluate(() => window.__roadTest.state());
    assert.equal(s.completed, 1);
    assert.equal(s.mission.stage, "complete");
    await p.evaluate(() => {
      window.__roadTest.render();
      window.__roadTest.meter();
    });
    await p.waitForTimeout(150);
    assert((await p.evaluate(() => window.__roadTest.rms())) > 0.000001);
    assert.equal((await p.evaluate(() => window.__roadTest.audio())).loops, 6);
    assert((await p.evaluate(() => window.__roadTest.audio())).voices <= 16);
    assert.equal(
      (await p.evaluate(() => window.__roadTest.audio())).loadError,
      null,
    );
    const levels = await p.evaluate(() => window.__roadTest.signalLevels());
    for (const kind of ["perseguicao", "parada", "passagem"])
      assert(levels[kind] > 0.02, kind + " silenciosa");
    assert.deepEqual(
      (await p.evaluate(() => window.__roadTest.audio())).clips.sort(),
      ["parada", "passagem", "perseguicao"],
    );
    await p.screenshot({
      path: `/tmp/prf-browser/abordagem-${mobile ? "mobile" : "desktop"}.png`,
    });
    await p.keyboard.press("r");
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).mission.stage,
      "briefing",
    );
    const base = await p.evaluate(() => window.__roadTest.baseStats());
    assert.equal(base.support, 3);
    assert.equal(base.people, 23);
    assert.equal(base.shadows, !mobile);
    await p.evaluate(() => {
      for (
        let i = 0;
        i < 1800 && window.__roadTest.state().checkpoint.stage !== "checking";
        i++
      )
        window.__roadTest.advance(1 / 30);
    });
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).checkpoint.stage,
      "checking",
    );
    await p.keyboard.press("p");
    await p.locator("#pauseDialog").evaluate((d) => d.close());
    await p.evaluate(() => {
      for (const id of [
        "hud",
        "toolbar",
        "interactions",
        "mobileControls",
        "targetMarker",
        "notice",
      ])
        document.getElementById(id).hidden = true;
      window.__roadTest.viewBase();
    });
    await p.screenshot({
      path: `/tmp/prf-browser/base-reference-${mobile ? "mobile" : "desktop"}.png`,
    });
    await p.keyboard.press("p");
    await p.evaluate(() => window.__roadTest.advance(65));
    assert(
      (await p.evaluate(() => window.__roadTest.state())).checkpoint
        .completed >= 1,
    );
    await p.evaluate(() => window.__roadTest.foot(28.3, 16));
    await p.keyboard.press("f");
    await p.evaluate(() => window.__roadTest.advance(45));
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).reception.seated,
      true,
    );
    let point = await p.evaluate(() =>
      window.__roadTest.screenPoint(0.17, 0.85),
    );
    await p.mouse.click(point.x, point.y);
    await p.evaluate(() => window.__roadTest.advance(10));
    const visitor = await p.evaluate(() => window.__roadTest.citizenPoint());
    assert(!visitor.occluded, "monitor must leave the seated citizen visible");
    assert(
      visitor.x > 0 &&
        visitor.x < (mobile ? 844 : 1280) &&
        visitor.y > 0 &&
        visitor.y < (mobile ? 390 : 720),
    );
    await p.evaluate(() => window.__roadTest.render());
    await p.screenshot({
      path: `/tmp/prf-browser/service-active-${mobile ? "mobile" : "desktop"}.png`,
    });
    point = await p.evaluate(() => window.__roadTest.screenPoint(0.5, 0.5));
    await p.mouse.click(point.x, point.y);
    assert(
      (await p.evaluate(() => window.__roadTest.state())).reception
        .computerFocus,
    );
    await p.evaluate(() => window.__roadTest.render());
    await p.screenshot({
      path: `/tmp/prf-browser/computer-focus-${mobile ? "mobile" : "desktop"}.png`,
    });
    point = await p.evaluate(() => window.__roadTest.screenPoint(0.5, 0.5));
    await p.mouse.click(point.x, point.y);
    assert(
      !(await p.evaluate(() => window.__roadTest.state())).reception
        .computerFocus,
    );
    point = await p.evaluate(() => window.__roadTest.screenPoint(0.51, 0.85));
    await p.mouse.click(point.x, point.y);
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).reception.completed,
      1,
    );
    await p.evaluate(() => window.__roadTest.render());
    await p.screenshot({
      path: `/tmp/prf-browser/service-${mobile ? "mobile" : "desktop"}.png`,
    });
    point = await p.evaluate(() => window.__roadTest.screenPoint(0.84, 0.85));
    await p.mouse.click(point.x, point.y);
    assert.equal(
      (await p.evaluate(() => window.__roadTest.state())).reception.seated,
      false,
    );
    for (const kind of ["parking", "bikes", "uniform"]) {
      await p.evaluate((kind) => window.__roadTest.viewDetail(kind), kind);
      await p.screenshot({
        path: `/tmp/prf-browser/${kind}-${mobile ? "mobile" : "desktop"}.png`,
      });
    }
    assert(!requests.some((r) => /draco|hangar|station|space/.test(r)));
    assert.deepEqual(external, []);
    assert.deepEqual(errors, []);
    console.log(
      JSON.stringify({
        mobile,
        tests:
          "posto, agente, A/D, radar, embarque, direção, freio, câmeras, pausa, áudio, parada, documentos, liberação, reinício",
        render: await p.evaluate(() => window.__roadTest.render()),
        requests: [...new Set(requests)],
      }),
    );
    await c.close();
  }
} finally {
  try {
    if (browser) await browser.close();
  } finally {
    server.kill();
  }
}
