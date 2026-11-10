import * as T from "./vendor/engine.js?v=2.13.0";
import { currentReport } from "./reception-sim.js?v=2.13.0";
export const COMPUTER = {
  x: 29.93,
  y: 1.25,
  z: 16.85,
  width: 1.3,
  height: 0.74,
};
export function createComputerScreen(root) {
  const canvas = document.createElement("canvas");
  canvas.width = 1024;
  canvas.height = 576;
  const map = new T.CanvasTexture(canvas);
  map.colorSpace = T.SRGBColorSpace;
  const mesh = new T.Mesh(
    new T.PlaneGeometry(COMPUTER.width, COMPUTER.height),
    new T.MeshBasicMaterial({ map, toneMapped: false }),
  );
  mesh.position.set(COMPUTER.x, COMPUTER.y, COMPUTER.z);
  mesh.rotation.y = -Math.PI / 2;
  root.add(mesh);
  let previous = "";
  return {
    mesh,
    hit(camera, x, y, width, height) {
      mesh.updateWorldMatrix(true, false);
      const a = mesh.worldToLocal(camera.position.clone()),
        b = mesh.worldToLocal(
          new T.Vector3(
            (x / width) * 2 - 1,
            1 - (y / height) * 2,
            0.5,
          ).unproject(camera),
        );
      const dz = b.z - a.z;
      if (Math.abs(dz) < 1e-6) return null;
      const t = -a.z / dz;
      if (t < 0) return null;
      const px = a.x + (b.x - a.x) * t,
        py = a.y + (b.y - a.y) * t;
      const u = px / COMPUTER.width + 0.5,
        v = 0.5 - py / COMPUTER.height;
      if (u < 0 || u > 1 || v < 0 || v > 1) return null;
      if (v > 0.78 && v < 0.92)
        return u < 0.34 ? "call" : u < 0.68 ? "register" : "leave";
      return "screen";
    },
    update(s) {
      const r = s.reception,
        report = currentReport(s),
        queue = r.visitors.filter((v) => v.state === "queue").length;
      const key = JSON.stringify([
        queue,
        r.active,
        report,
        r.completed,
        r.agentCompleted,
        r.records,
      ]);
      if (key === previous) return;
      previous = key;
      const c = canvas.getContext("2d");
      c.fillStyle = "#0b1c2c";
      c.fillRect(0, 0, 1024, 576);
      c.fillStyle = "#cfb65f";
      c.fillRect(0, 0, 1024, 70);
      c.fillStyle = "#102332";
      c.font = "bold 32px Arial";
      c.fillText("PRF | REGISTRO DE OCORRÊNCIAS", 26, 46);
      c.fillStyle = "#a9c9d8";
      c.font = "24px Arial";
      c.fillText(
        `FILA: ${queue}    REGISTROS: ${r.completed}    RECEPÇÃO: ${r.agentCompleted}`,
        26,
        108,
      );
      c.fillStyle = "#ffffff";
      c.font = "bold 29px Arial";
      c.fillText(
        report
          ? `SENHA ${report.ticket} • ${report.name}`
          : r.active !== null
            ? "Cidadão a caminho da sala…"
            : "Pronto para o próximo atendimento",
        26,
        160,
      );
      c.font = "bold 28px Arial";
      c.fillStyle = "#f1d475";
      c.fillText(report?.type ?? "Atendimento presencial", 26, 205);
      c.font = "26px Arial";
      c.fillStyle = "#e2edf1";
      const words = (
        report?.description ??
        "Chame a próxima pessoa e aguarde sua chegada para registrar a ocorrência."
      ).split(" ");
      let line = "",
        y = 248;
      for (const word of words) {
        if (c.measureText(line + word).width > 955) {
          c.fillText(line, 26, y);
          y += 34;
          line = "";
        }
        line += word + " ";
      }
      c.fillText(line, 26, y);
      c.font = "22px Arial";
      c.fillStyle = "#9eb9c8";
      c.fillText("ÚLTIMOS REGISTROS NESTE TURNO", 26, 350);
      c.fillText(
        r.records
          .slice(0, 2)
          .map((v) => `#${v.number} ${v.type}`)
          .join("  |  "),
        26,
        385,
        970,
      );
      for (const [i, label, enabled] of [
        [0, "CHAMAR PRÓXIMO", r.active === null && queue > 0],
        [1, "REGISTRAR / LIBERAR", !!report],
        [2, "LEVANTAR [E]", true],
      ]) {
        c.fillStyle = enabled ? "#cfb65f" : "#354653";
        c.fillRect(i * 348 + 8, 450, 326, 80);
        c.fillStyle = enabled ? "#102332" : "#8194a0";
        c.font = "bold 22px Arial";
        c.fillText(label, i * 348 + 20, 498, 300);
      }
      c.fillStyle = "#92a5b4";
      c.font = "19px Arial";
      c.fillText(
        "Clique no relato para ampliar/voltar • Histórico do turno",
        26,
        561,
      );
      map.needsUpdate = true;
    },
  };
}
