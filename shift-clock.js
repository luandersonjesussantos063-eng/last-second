// One real second advances one game minute. Only simulation steps move the clock.
export const GAME_MINUTES_PER_SECOND = 1;
export function createShiftClock() {
  return { day: 1, minute: 16 * 60 + 30 };
}
export function updateShiftClock(clock, dt) {
  const minutes = clock.minute + Math.max(0, dt) * GAME_MINUTES_PER_SECOND;
  clock.day += Math.floor(minutes / 1440);
  clock.minute = minutes % 1440;
}
const smooth = (a, b, x) => {
  const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};
export function clockReading(clock) {
  const hour = clock.minute / 60;
  const daylight = smooth(5.5, 7, hour) * (1 - smooth(17.5, 19, hour));
  const hourText = String(Math.floor(hour)).padStart(2, "0");
  const minuteText = String(Math.floor(clock.minute % 60)).padStart(2, "0");
  return {
    text: `${hourText}:${minuteText}`,
    period: hour < 6 || hour >= 18 ? "NOITE" : hour < 12 ? "MANHÃ" : "TARDE",
    daylight,
    lamps: 1 - smooth(0.15, 0.7, daylight),
  };
}
