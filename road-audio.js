import { SIREN_COMMANDS } from "./siren-config.js?v=2.5.0";
export function footstepSamples(rate, variant = 0) {
  const samples = new Float32Array(Math.ceil(rate * 0.25));
  let seed = 83 + variant * 917,
    low = 0;
  const alpha = 1 - Math.exp((-Math.PI * 2 * 550) / rate);
  for (let i = 0; i < samples.length; i++) {
    const t = i / rate;
    seed = (seed * 1664525 + 1013904223) >>> 0;
    const white = seed / 2147483648 - 1;
    low += (white - low) * alpha;
    const heel = Math.min(1, t / 0.022) * Math.exp(-t / 0.055),
      toe =
        t > 0.065
          ? Math.min(1, (t - 0.065) / 0.04) * Math.exp(-(t - 0.065) / 0.065)
          : 0;
    samples[i] = low * (0.32 * heel + 0.2 * toe) + white * 0.012 * toe;
  }
  return samples;
}
export class RoadAudio {
  constructor() {
    this.ctx = null;
    this.volume = 0.5;
    this.muted = false;
    this.voices = 0;
    this.maxVoices = 16;
    this.loops = [];
    this.events = {};
    this.lastMix = -1;
    this.lastStep = 0;
    this.stepIndex = 0;
    this.lastDoor = 0;
    this.lastImpact = 0;
    this.buffers = {};
    this.samplePromise = null;
    this.pendingCommand = null;
    this.playback = null;
    this.commandSerial = 0;
    this.recordedVoices = 0;
    this.loadError = null;
    try {
      const p = JSON.parse(localStorage.getItem("prf-audio"));
      if (p) {
        this.volume = Math.max(0, Math.min(1, p.volume ?? 0.5));
        this.muted = !!p.muted;
      }
    } catch {}
  }
  async unlock(paused = false) {
    try {
      if (!this.ctx) {
        const C = window.AudioContext || window.webkitAudioContext;
        if (!C) return;
        this.ctx = new C();
        this.output = this.ctx.createGain();
        const compressor = this.ctx.createDynamicsCompressor();
        compressor.threshold.value = -14;
        compressor.ratio.value = 5;
        this.output.connect(compressor);
        compressor.connect(this.ctx.destination);
        this.noise = this.ctx.createBuffer(
          1,
          this.ctx.sampleRate,
          this.ctx.sampleRate,
        );
        const d = this.noise.getChannelData(0);
        let low = 0;
        for (let i = 0; i < d.length; i++) {
          low = (low + Math.random() * 0.12 - 0.06) / 1.02;
          d[i] = low;
        }
        this.steps = Array.from({ length: 3 }, (_, i) => {
          const b = this.ctx.createBuffer(
            1,
            Math.ceil(this.ctx.sampleRate * 0.25),
            this.ctx.sampleRate,
          );
          b.getChannelData(0).set(footstepSamples(this.ctx.sampleRate, i));
          return b;
        });
        this.engine = this.loop("triangle", 48, 450);
        this.tyres = this.loop("noise", 0, 1000);
        this.ambient = this.loop("noise", 0, 1100);
        this.door = this.loop("noise", 0, 600);
        this.applyVolume();
        void this.loadClips();
      }
      if (!paused && this.ctx.state === "suspended") await this.ctx.resume();
    } catch {
      for (const l of this.loops) {
        try {
          l.source.stop();
        } catch {}
      }
      this.ctx = null;
      this.output = null;
      this.loops = [];
    }
  }
  loop(type, frequency, cutoff) {
    const c = this.ctx,
      source = type === "noise" ? c.createBufferSource() : c.createOscillator();
    if (type === "noise") {
      source.buffer = this.noise;
      source.loop = true;
    } else {
      source.type = type;
      source.frequency.value = frequency;
    }
    const filter = c.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = cutoff;
    const gain = c.createGain();
    gain.gain.value = 0;
    source.connect(filter);
    filter.connect(gain);
    gain.connect(this.output);
    source.start();
    const voice = { source, filter, gain };
    this.loops.push(voice);
    return voice;
  }
  loadClips() {
    if (this.samplePromise) return this.samplePromise;
    if (!this.ctx) return Promise.resolve(false);
    const ctx = this.ctx;
    this.samplePromise = Promise.all(
      Object.entries(SIREN_COMMANDS).map(async ([kind, config]) => {
        const response = await fetch(config.url);
        if (!response.ok) throw Error(`Áudio ${kind}: ${response.status}`);
        const buffer = await ctx.decodeAudioData(await response.arrayBuffer());
        return [kind, buffer];
      }),
    )
      .then((entries) => {
        this.buffers = Object.fromEntries(entries);
        this.loadError = null;
        return true;
      })
      .catch((error) => {
        this.loadError = error.message;
        return false;
      });
    return this.samplePromise;
  }
  fadeRecorded() {
    const voice = this.playback;
    this.playback = null;
    if (!voice || !this.ctx) return;
    const t = this.ctx.currentTime;
    voice.gain.gain.cancelScheduledValues(t);
    voice.gain.gain.setTargetAtTime(0, t, 0.012);
    try {
      voice.source.stop(t + 0.05);
    } catch {}
  }
  stopCommand() {
    this.commandSerial++;
    this.pendingCommand = null;
    this.fadeRecorded();
  }
  async command(kind) {
    if (!this.ctx || !SIREN_COMMANDS[kind]) return false;
    this.fadeRecorded();
    const serial = ++this.commandSerial;
    this.pendingCommand = { kind, serial };
    const loaded = await this.loadClips();
    if (this.pendingCommand?.serial !== serial) return true;
    this.pendingCommand = null;
    if (!loaded) return false;
    const ctx = this.ctx,
      config = SIREN_COMMANDS[kind],
      source = ctx.createBufferSource(),
      gain = ctx.createGain();
    source.buffer = this.buffers[kind];
    source.loop = config.loop;
    gain.gain.value = 0;
    source.connect(gain);
    gain.connect(this.output);
    gain.gain.setTargetAtTime(0.25, ctx.currentTime, 0.025);
    const voice = { source, gain, kind };
    this.playback = voice;
    this.recordedVoices++;
    this.events[kind] = (this.events[kind] ?? 0) + 1;
    source.onended = () => {
      source.disconnect();
      gain.disconnect();
      this.recordedVoices--;
      if (this.playback === voice) this.playback = null;
    };
    source.start();
    if (config.seconds) source.stop(ctx.currentTime + config.seconds);
    return true;
  }
  applyVolume() {
    if (this.output)
      this.output.gain.setTargetAtTime(
        this.muted ? 0 : this.volume,
        this.ctx.currentTime,
        0.03,
      );
  }
  save() {
    this.applyVolume();
    try {
      localStorage.setItem(
        "prf-audio",
        JSON.stringify({ volume: this.volume, muted: this.muted }),
      );
    } catch {}
  }
  toggle() {
    this.muted = !this.muted;
    this.save();
  }
  setVolume(value) {
    this.volume = Math.max(0, Math.min(1, Number(value) || 0));
    this.save();
  }
  pause(value) {
    if (!this.ctx) return;
    if (value) void this.ctx.suspend().catch(() => {});
    else void this.ctx.resume().catch(() => {});
  }
  emit(kind) {
    if (
      !this.ctx ||
      this.ctx.state !== "running" ||
      this.muted ||
      this.volume === 0 ||
      this.voices >= this.maxVoices
    )
      return;
    const c = this.ctx,
      t = c.currentTime,
      noise = ["step", "impact", "door", "enter"].includes(kind),
      source = noise ? c.createBufferSource() : c.createOscillator();
    const duration = kind === "step" ? 0.25 : kind === "impact" ? 0.45 : 0.16;
    if (noise)
      source.buffer =
        kind === "step" ? this.steps[this.stepIndex++ % 3] : this.noise;
    else {
      source.type = "sine";
      source.frequency.setValueAtTime(kind === "radio" ? 840 : 620, t);
      source.frequency.exponentialRampToValueAtTime(480, t + duration);
    }
    const filter = c.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = kind === "step" ? 1100 : 1800;
    const gain = c.createGain();
    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(
      kind === "step" ? 0.12 : kind === "impact" ? 0.22 : 0.07,
      t + 0.025,
    );
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    source.connect(filter);
    filter.connect(gain);
    gain.connect(this.output);
    this.voices++;
    this.events[kind] = (this.events[kind] ?? 0) + 1;
    source.onended = () => {
      source.disconnect();
      filter.disconnect();
      gain.disconnect();
      this.voices--;
    };
    source.start();
    source.stop(t + duration + 0.02);
  }
  update(s) {
    if (!this.ctx) return;
    if (s.mode === "foot") {
      if (s.player.distance - this.lastStep > 1.05) {
        this.lastStep = s.player.distance;
        this.emit("step");
      }
    } else this.lastStep = s.player.distance;
    if (s.impactSerial !== this.lastImpact) {
      this.lastImpact = s.impactSerial;
      this.emit("impact");
    }
    const roomMoving = Math.abs(s.roomDoor - (this.lastRoomDoor ?? 0)) > 0.002;
    this.lastRoomDoor = s.roomDoor;
    const doorMoving = Math.abs(s.door - this.lastDoor) > 0.002 || roomMoving;
    this.lastDoor = s.door;
    const t = this.ctx.currentTime;
    if (
      !s.car.siren &&
      (this.playback?.kind === "perseguicao" ||
        this.pendingCommand?.kind === "perseguicao")
    )
      this.stopCommand();
    if (
      s.car.siren &&
      !this.playback &&
      !this.pendingCommand &&
      !this.loadError
    )
      void this.command("perseguicao");
    if (t - this.lastMix < 0.05) return;
    this.lastMix = t;
    const speed = Math.abs(s.car.speed),
      near = Math.hypot(s.player.x - s.car.x, s.player.z - s.car.z);
    const engineLevel =
      s.mode === "drive" ? 0.035 : 0.015 / (1 + (near / 8) ** 2);
    this.engine.gain.gain.setTargetAtTime(engineLevel, t, 0.15);
    this.engine.source.frequency.setTargetAtTime(42 + speed * 3.2, t, 0.12);
    this.tyres.gain.gain.setTargetAtTime(
      s.mode === "drive" ? Math.min(0.045, speed * 0.0012) : 0,
      t,
      0.15,
    );
    this.ambient.gain.gain.setTargetAtTime(
      s.mode === "foot" ? 0.018 : 0.006,
      t,
      0.3,
    );
    if (this.playback) {
      const level = s.mode === "drive" ? 0.25 : 0.32 / (1 + (near / 18) ** 2);
      this.playback.gain.gain.setTargetAtTime(level, t, 0.05);
    }
    const listener = s.mode === "drive" ? s.car : s.player,
      doorDistance = Math.min(
        Math.hypot(listener.x - 35, listener.z - 10),
        Math.hypot(listener.x - 33, listener.z - 16),
      );
    this.door.gain.gain.setTargetAtTime(
      doorMoving ? 0.12 / (1 + (doorDistance / 16) ** 2) : 0,
      t,
      0.08,
    );
  }
  reset() {
    this.lastStep = 0;
    this.lastImpact = 0;
    this.lastDoor = 0;
    this.stopCommand();
  }
}
