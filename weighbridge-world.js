import * as T from "./vendor/engine.js?v=2.22.0";
import { createFreightTruck } from "./freight-world.js?v=2.22.0";
const TYPES = ["semi", "boxTruck", "bitrem", "bus"];
export function createWeighbridgeWorld(scene) {
  const root = new T.Group();
  scene.add(root);
  const steel = new T.MeshStandardMaterial({
      color: 0x42515b,
      metalness: 0.6,
      roughness: 0.45,
    }),
    road = new T.MeshStandardMaterial({ color: 0x39434a, roughness: 0.83 }),
    gold = new T.MeshBasicMaterial({ color: 0xffd054 }),
    border = new T.MeshStandardMaterial({ color: 0xd9d5c1, roughness: 0.7 });
  function box(m, x, y, z, w, h, d) {
    const o = new T.Mesh(new T.BoxGeometry(w, h, d), m);
    o.position.set(x, y, z);
    o.receiveShadow = true;
    root.add(o);
    return o;
  }
  box(road, 0, 0.02, -13, 60, 0.06, 150);
  box(steel, 0, 0.14, 0, 3.5, 0.2, 34);
  for (const x of [-1.8, 1.8]) box(gold, x, 0.26, 0, 0.12, 0.03, 34);
  for (let z = -32; z < 34; z += 8) box(gold, -11, 0.065, z, 0.12, 0.02, 4);
  box(border, 2.7, 1.05, 5, 1.9, 2.1, 1.5);
  box(steel, 2.7, 2.17, 5, 2.3, 0.24, 1.9);
  for (const x of [-2.5, 2.5])
    for (const z of [-19, 19]) box(steel, x, 3, z, 0.15, 6, 0.15);
  box(steel, 0, 6.1, 0, 6, 0.18, 42);
  const canvas = document.createElement("canvas");
  canvas.width = 768;
  canvas.height = 384;
  const texture = new T.CanvasTexture(canvas);
  texture.colorSpace = T.SRGBColorSpace;
  const sign = new T.Mesh(
    new T.PlaneGeometry(4.6, 2.3),
    new T.MeshBasicMaterial({
      map: texture,
      side: T.DoubleSide,
      toneMapped: false,
    }),
  );
  sign.position.set(2.5, 4.2, -16);
  root.add(sign);
  const red = new T.Mesh(
      new T.SphereGeometry(0.18, 10, 6),
      new T.MeshBasicMaterial({ color: 0xee4540 }),
    ),
    green = new T.Mesh(
      new T.SphereGeometry(0.18, 10, 6),
      new T.MeshBasicMaterial({ color: 0x4ada86 }),
    );
  red.position.set(2.4, 2.8, 19);
  green.position.set(2.4, 2.35, 19);
  root.add(red, green);
  const models = new Map(
    TYPES.map((type) => {
      const m = createFreightTruck(0x2e7382, type);
      scene.add(m.group);
      m.group.visible = false;
      return [type, m];
    }),
  );
  const stored = Array.from({ length: 3 }, () => {
    const variants = new Map(
      TYPES.map((type) => {
        const m = createFreightTruck(0x688b98, type);
        scene.add(m.group);
        m.group.visible = false;
        return [type, m];
      }),
    );
    return variants;
  });
  let key = "",
    lastDisplay = -10;
  return {
    group: root,
    truck: models.get("semi"),
    models,
    red,
    green,
    update(s) {
      const w = s.weighbridge;
      root.position.set(w.x, 0, w.z);
      red.visible = w.signal === "red";
      green.visible = !red.visible;
      for (const [type, m] of models) {
        m.group.visible =
          w.truck.visible && type === (w.truck.freightType ?? "semi");
        if (m.group.visible) m.update(w.truck, s.time);
      }
      stored.forEach((variants, i) => {
        const c = w.retained[i];
        for (const [type, m] of variants) {
          m.group.visible = !!c && type === (c.freightType ?? "semi");
          if (m.group.visible) m.update(c, s.time);
        }
      });
      const next = [w.stage, w.readingKg, w.completed, w.sequence].join("|");
      if (next === key || s.time - lastDisplay < 0.12) return;
      key = next;
      lastDisplay = s.time;
      const x = canvas.getContext("2d");
      x.fillStyle = "#102b35";
      x.fillRect(0, 0, 768, 384);
      x.strokeStyle = "#f3bf40";
      x.lineWidth = 8;
      x.strokeRect(4, 4, 760, 376);
      x.textAlign = "center";
      x.fillStyle = "#f3da91";
      x.font = "bold 36px Arial";
      x.fillText("BALANÇA RODOVIÁRIA", 384, 53);
      x.font = "bold 66px monospace";
      x.fillStyle = w.report?.differenceKg ? "#f8ad65" : "#a8ecc7";
      const kg =
        w.stage === "weighing" ? w.readingKg : w.report ? w.grossKg : 0;
      x.fillText(kg.toLocaleString("pt-BR") + " KG", 384, 141);
      x.font = "27px Arial";
      x.fillText(
        (kg / 1000).toFixed(2) + " t · " + w.truck.axles + " eixos",
        384,
        189,
      );
      x.fillStyle = "#d6e9ef";
      x.font = "23px Arial";
      x.fillText(
        {
          ready: "INICIE PESAGEM [F]",
          weighing: "VEÍCULO IMÓVEL · LEITURA EM CURSO",
          weighed: w.report?.differenceKg
            ? "EXCESSO · REGISTRAR / PÁTIO [F]"
            : "REGULAR · REGISTRAR / LIBERAR [F]",
          released: "VEÍCULO SAINDO DA PLATAFORMA",
          waiting: "AGUARDANDO PRÓXIMA CARGA",
          approach: "VEÍCULO ENTRANDO",
        }[w.stage] ?? "",
        384,
        243,
        735,
      );
      x.font = "19px Arial";
      x.fillText(
        w.report
          ? "EIXOS: " +
              w.report.axleKg
                .map((v) => v.toLocaleString("pt-BR"))
                .join(" / ") +
              " kg"
          : "Valores e referências fictícios do simulador",
        384,
        294,
        730,
      );
      x.fillText(w.completed + " PESAGEM(NS) REGISTRADA(S)", 384, 341);
      texture.needsUpdate = true;
    },
  };
}
