export const UNIFORMS = {
  police: {
    name: "POLÍCIA ESPACIAL",
    color: 0x172d50,
    trim: "#e5edf4",
    gear: "helmet",
    trousers: 0x15223b,
  },
  control: {
    name: "CONTROLE",
    color: 0x365a85,
    trim: "#8ddaf2",
    gear: "headset",
    trousers: 0x182b41,
  },
  mechanic: {
    name: "MANUTENÇÃO",
    color: 0xb76e2c,
    trim: "#e7db99",
    gear: "hardhat",
    trousers: 0x85512c,
  },
  medical: {
    name: "MEDICINA",
    color: 0xe0eeee,
    trim: "#39bca4",
    gear: "medical",
    trousers: 0x79a59f,
  },
  supplies: {
    name: "SUPRIMENTOS",
    color: 0x626f72,
    trim: "#d6d186",
    gear: "vest",
    trousers: 0x354348,
  },
};
export function uniformForRole(role) {
  if (role === "PILOTO") return "police";
  if (
    [
      "CONTROLE DE VOO",
      "NAVEGAÇÃO",
      "SENSORES",
      "SUPERVISÃO",
      "COMUNICAÇÕES",
    ].includes(role)
  )
    return "control";
  if (role === "MEDICINA") return "medical";
  if (role === "SUPRIMENTOS") return "supplies";
  return "mechanic";
}
