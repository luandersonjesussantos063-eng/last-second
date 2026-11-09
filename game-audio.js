export function acousticPosition(listener, source, yaw = 0) {
  const dx = source.x - listener.x,
    dy = (source.y ?? 0) - (listener.y ?? 0),
    dz = source.z - listener.z;
  const distance = Math.hypot(dx, dy, dz);
  return {
    gain: distance > 90 ? 0 : 1 / (1 + (distance / 12) ** 2),
    pan: Math.max(
      -1,
      Math.min(
        1,
        (dx * Math.cos(yaw) - dz * Math.sin(yaw)) / Math.max(5, distance),
      ),
    ),
  };
}

// One shared context, a bounded set of loops, and a cap on transient voices.
export class GameAudio {
  constructor() {
    this.ctx = null;
    this.output = null;
    this.loops = [];
    this.voices = 0;
    this.maxVoices = 24;
    this.volume = 0.55;
    this.muted = false;
    this.stepDistance = 0;
    this.previousPlayer = null;
    this.doors = new Map();
    this.ships = new Map();
    this.people = new Map();
    this.events = {};
    this.lastMix = -10;
    this.equipmentTime = 0;
    try {
      const saved = JSON.parse(localStorage.getItem("last-second-audio"));
      if (saved) {
        this.volume = Math.max(0, Math.min(1, saved.volume ?? 0.55));
        this.muted = !!saved.muted;
      }
    } catch {}
  }
  activate(ctx) {
    if (!ctx || this.ctx) return;
    try {
      this.ctx = ctx;
      this.output = ctx.createGain();
      const limiter = ctx.createDynamicsCompressor();
      limiter.threshold.value = -12;
      limiter.knee.value = 12;
      limiter.ratio.value = 6;
      this.output.connect(limiter);
      limiter.connect(ctx.destination);
      this.applyVolume();
      this.noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const data = this.noise.getChannelData(0);
      let previous = 0;
      for (let i = 0; i < data.length; i++) {
        previous = (previous + Math.random() * 0.12 - 0.06) / 1.02;
        data[i] = previous * 2;
      }
      this.ambient = this.loop(55, "sine", 180);
      this.vent = this.loop(0, "noise", 550);
      this.engine = this.loop(48, "sawtooth", 240);
      this.craft = Array.from({ length: 3 }, () =>
        this.loop(65, "sawtooth", 450),
      );
    } catch {
      for (const voice of this.loops) {
        try {
          voice.source.stop();
          voice.source.disconnect();
          voice.gain.disconnect();
        } catch {}
      }
      this.loops = [];
      this.ctx = null;
      this.output = null;
    }
  }
  loop(frequency, type, cutoff) {
    const ctx = this.ctx,
      source =
        type === "noise" ? ctx.createBufferSource() : ctx.createOscillator();
    if (type === "noise") {
      source.buffer = this.noise;
      source.loop = true;
    } else {
      source.type = type;
      source.frequency.value = frequency;
    }
    const filter = ctx.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = cutoff;
    const gain = ctx.createGain();
    gain.gain.value = 0;
    const pan = ctx.createStereoPanner();
    source.connect(filter);
    filter.connect(gain);
    gain.connect(pan);
    pan.connect(this.output);
    source.start();
    const voice = { source, filter, gain, pan };
    this.loops.push(voice);
    return voice;
  }
  applyVolume() {
    if (this.output)
      this.output.gain.setTargetAtTime(
        this.muted ? 0 : this.volume,
        this.ctx.currentTime,
        0.025,
      );
  }
  setVolume(value) {
    this.volume = Math.max(0, Math.min(1, Number(value) || 0));
    this.save();
  }
  toggleMute() {
    this.muted = !this.muted;
    this.save();
  }
  save() {
    this.applyVolume();
    try {
      localStorage.setItem(
        "last-second-audio",
        JSON.stringify({ volume: this.volume, muted: this.muted }),
      );
    } catch {}
  }
  emit(kind, volume = 1, spatial = { gain: 1, pan: 0 }) {
    if (
      !this.ctx ||
      this.ctx.state !== "running" ||
      this.muted ||
      this.volume === 0 ||
      this.voices >= this.maxVoices ||
      spatial.gain < 0.004
    )
      return;
    const presets = {
      step: [0.13, 110, 850, 0.13],
      servo: [0.55, 170, 1200, 0.07],
      latch: [0.1, 240, 1300, 0.1],
      hatch: [0.45, 140, 700, 0.1],
      repair: [0.18, 90, 1600, 0.06],
      scan: [0.12, 940, 2000, 0.035],
      ui: [0.06, 700, 1800, 0.025],
      impact: [0.7, 48, 600, 0.25],
      boarding: [0.16, 190, 1000, 0.09],
      siren: [0.65, 660, 1800, 0.04],
    };
    const [duration, freq, cutoff, level] = presets[kind] ?? presets.ui,
      ctx = this.ctx,
      t = ctx.currentTime;
    const noiseKinds = [
      "step",
      "servo",
      "latch",
      "hatch",
      "repair",
      "impact",
      "boarding",
    ];
    const source = noiseKinds.includes(kind)
      ? ctx.createBufferSource()
      : ctx.createOscillator();
    if (source.frequency) {
      source.type = "sine";
      source.frequency.setValueAtTime(freq, t);
      source.frequency.exponentialRampToValueAtTime(freq * 0.65, t + duration);
      if (kind === "siren")
        for (let i = 0; i < 4; i++)
          source.frequency.setValueAtTime(i % 2 ? 820 : 600, t + i * 0.15);
    } else {
      source.buffer = this.noise;
      source.playbackRate.value =
        kind === "step" ? 0.85 + Math.random() * 0.3 : 1;
    }
    const filter = ctx.createBiquadFilter();
    filter.type = "bandpass";
    filter.frequency.value = cutoff;
    filter.Q.value = 0.6;
    const gain = ctx.createGain(),
      pan = ctx.createStereoPanner();
    pan.pan.value = spatial.pan;
    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(
      Math.max(0.0002, level * volume * spatial.gain),
      t + 0.009,
    );
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    source.connect(filter);
    filter.connect(gain);
    gain.connect(pan);
    pan.connect(this.output);
    this.voices++;
    this.events[kind] = (this.events[kind] ?? 0) + 1;
    source.onended = () => {
      source.disconnect();
      filter.disconnect();
      gain.disconnect();
      pan.disconnect();
      this.voices--;
    };
    source.start(t);
    source.stop(t + duration + 0.02);
  }
  reset() {
    this.previousPlayer = null;
    this.stepDistance = 0;
    this.doors.clear();
    this.ships.clear();
    this.people.clear();
    this.lastGate = null;
  }
  update(
    dt,
    {
      active,
      foot,
      position,
      yaw,
      speed,
      turbo,
      parked,
      launching,
      health,
      station,
      gate,
    },
  ) {
    if (!this.ctx) return;
    const listener = position,
      spatial = (source) => acousticPosition(listener, source, yaw);
    if (active && foot) {
      if (this.previousPlayer) {
        const d = Math.hypot(
          position.x - this.previousPlayer.x,
          position.z - this.previousPlayer.z,
        );
        if (d < 2) this.stepDistance += d;
        else this.stepDistance = 0;
      }
      if (this.stepDistance > 0.8) {
        this.stepDistance %= 0.8;
        this.emit("step", 1);
      }
      this.previousPlayer = { x: position.x, z: position.z };
      for (const door of station.doors) {
        const key = `${door.side}:${door.z}`,
          previous = this.doors.get(key),
          moving = previous && Math.abs(door.open - previous.open) > 0.002;
        if (moving && !previous.moving)
          this.emit(
            "servo",
            1,
            spatial({ x: door.side * 34, y: -3, z: door.z }),
          );
        if (previous?.moving && !moving)
          this.emit(
            "latch",
            0.6,
            spatial({ x: door.side * 34, y: -3, z: door.z }),
          );
        this.doors.set(key, { open: door.open, moving });
      }
      station.crew.forEach((p, i) => {
        const previous = this.people.get(i),
          d = previous ? Math.hypot(p.x - previous.x, p.z - previous.z) : 0;
        const distance = previous && d < 2 ? previous.distance + d : 0;
        if (p.visible && distance > 0.9) this.emit("step", 0.55, spatial(p));
        this.people.set(i, { x: p.x, z: p.z, distance: distance % 0.9 });
      });
      this.equipmentTime += dt;
      if (this.equipmentTime > 3.5) {
        this.equipmentTime = 0;
        const worker = station.crew.find(
          (p) =>
            p.visible &&
            ["repair", "scan", "typing"].includes(p.action) &&
            Math.hypot(p.x - position.x, p.y - position.y, p.z - position.z) <
              13,
        );
        if (worker)
          this.emit(
            worker.action === "repair" ? "repair" : "scan",
            0.65,
            spatial(worker),
          );
      }
    } else {
      this.previousPlayer = null;
      this.stepDistance = 0;
    }
    for (const s of station.traffic.ships) {
      const previous = this.ships.get(s.id);
      if (
        active &&
        foot &&
        previous !== s.state &&
        ["embarking", "disembarking"].includes(s.state)
      )
        this.emit("hatch", 1, spatial(s));
      if (active && foot && previous !== s.state && s.state === "clearance")
        this.emit("siren", 0.6, spatial(s));
      this.ships.set(s.id, s.state);
    }
    if (
      active &&
      foot &&
      this.lastGate != null &&
      Math.abs(gate - this.lastGate) > 0.02 &&
      !this.gateMoving
    )
      this.emit("servo", 1.3, spatial({ x: 0, y: 3, z: 96 }));
    this.gateMoving =
      this.lastGate != null && Math.abs(gate - this.lastGate) > 0.02;
    this.lastGate = gate;
    // Parameter automation follows audio time, not accelerated simulation/test frames.
    const t = this.ctx.currentTime;
    if (t - this.lastMix < 0.04) return;
    this.lastMix = t;
    const nearBase = Math.hypot(position.x, position.z - 45) < 120;
    const inside = foot || parked || (nearBase && position.z < 100);
    this.ambient.gain.gain.setTargetAtTime(
      active && inside ? 0.014 : 0,
      t,
      0.2,
    );
    this.vent.gain.gain.setTargetAtTime(active && inside ? 0.028 : 0, t, 0.2);
    this.engine.gain.gain.setTargetAtTime(
      active && !foot && !parked && health > 0 ? (turbo ? 0.055 : 0.028) : 0,
      t,
      0.15,
    );
    this.engine.source.frequency.setTargetAtTime(
      48 + Math.min(100, speed) * 0.9 + (launching ? 18 : 0),
      t,
      0.12,
    );
    this.engine.filter.frequency.setTargetAtTime(turbo ? 750 : 280, t, 0.1);
    station.traffic.ships.forEach((s, i) => {
      const p = spatial(s),
        v = this.craft[i];
      v.gain.gain.setTargetAtTime(
        active && foot && s.z < 125 ? s.thruster * p.gain * 0.075 : 0,
        t,
        0.1,
      );
      v.pan.pan.setTargetAtTime(p.pan, t, 0.1);
      v.source.frequency.setTargetAtTime(50 + s.thruster * 110, t, 0.1);
    });
  }
  silence() {
    if (this.ctx)
      for (const v of this.loops)
        v.gain.gain.setTargetAtTime(0, this.ctx.currentTime, 0.02);
  }
}
