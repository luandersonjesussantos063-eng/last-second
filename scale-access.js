// One source of truth for the paved scale apron and its road connection.
export const SCALE_ENTRY = [
  [-3.4, -155],
  [-3.4, -125],
  [65, -125],
  [65, -60],
];
export const SCALE_EXIT = [
  [65, -10],
  [105, -10],
  [105, -130],
  [3.4, -130],
  [3.4, -155],
];
export function scalePaved(x, z) {
  return (
    Math.abs(x) <= 11 ||
    (x >= 20 && x <= 125 && z >= -155 && z <= 10) ||
    (x >= -11 && x <= 35 && z >= -145 && z <= -110)
  );
}
