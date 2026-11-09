export const CANOPY = { minX: -15, maxX: 24, minZ: -4, maxZ: 29, roofY: 9 };
export const BASE_COLUMNS = [-15, 23.5].flatMap((x) =>
  [-2, 13, 28].map((z) => ({ x, z, hx: 0.55, hz: 0.55 })),
);
export const BLITZ_UNITS = [
  { x: -8.7, z: -11, heading: 0, lights: true, plate: "PRF-0202" },
  { x: 8.8, z: -18, heading: Math.PI, lights: true, plate: "PRF-0203" },
  { x: 19, z: 32, heading: Math.PI, lights: false, plate: "PRF-0204" },
];
export const BLITZ_CONES = [
  ...[-44, -36, -28, -20, -12, -4].map((z) => ({ x: -6.5, z })),
  ...[6, 14, 22, 30].map((z) => ({ x: -11.5, z })),
  ...[-28, -20, -12].map((z) => ({ x: 6.5, z })),
];
export const CHECKPOINT = { stopZ: 0, bayX: -9, bayZ: 18, releaseZ: 49 };
