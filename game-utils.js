export function frameStep(milliseconds) {
  return Math.min(
    0.05,
    Math.max(0, Number.isFinite(milliseconds) ? milliseconds / 1000 : 0),
  );
}
export class AdaptiveResolution {
  constructor(maximum) {
    this.maximum = maximum;
    this.level = 0;
    this.steps = [1, 0.85, 0.7, 0.55];
    this.elapsed = 0;
    this.frames = 0;
    this.total = 0;
    this.cooldown = 0;
  }
  get ratio() {
    return this.maximum * this.steps[this.level];
  }
  reset() {
    this.elapsed = 0;
    this.frames = 0;
    this.total = 0;
  }
  sample(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0 || seconds > 1) {
      this.reset();
      return false;
    }
    this.elapsed += seconds;
    this.total += seconds;
    this.frames++;
    this.cooldown = Math.max(0, this.cooldown - seconds);
    if (this.elapsed < 2) return false;
    const average = this.total / this.frames;
    this.reset();
    if (this.cooldown > 0) return false;
    const old = this.level;
    if (average > 1 / 42 && this.level < this.steps.length - 1) {
      this.level++;
      this.cooldown = 3;
    } else if (average < 1 / 59 && this.level > 0) {
      this.level--;
      this.cooldown = 8;
    }
    return old !== this.level;
  }
}
