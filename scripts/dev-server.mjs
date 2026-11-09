import http from "node:http";
import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = path.resolve(fileURLToPath(new URL("../", import.meta.url)));
const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".glb": "model/gltf-binary",
  ".wasm": "application/wasm",
};
http
  .createServer(async (req, res) => {
    try {
      const pathname = decodeURIComponent(
        new URL(req.url, "http://localhost").pathname,
      );
      if (
        pathname
          .split("/")
          .some((p) => p.startsWith(".") || p === "node_modules")
      ) {
        res.writeHead(403).end();
        return;
      }
      let file = path.resolve(root, "." + pathname);
      if (file !== root && !file.startsWith(root + path.sep)) {
        res.writeHead(403).end();
        return;
      }
      let info = await stat(file);
      if (info.isDirectory()) {
        file = path.join(file, "index.html");
        info = await stat(file);
      }
      if (!info.isFile()) throw Error();
      res.writeHead(200, {
        "Content-Type": mime[path.extname(file)] || "application/octet-stream",
        "Content-Length": info.size,
        "Cache-Control": "no-cache",
      });
      createReadStream(file).pipe(res);
    } catch {
      res.writeHead(404).end("Não encontrado");
    }
  })
  .listen(Number(process.env.PORT || 8080), "127.0.0.1", () =>
    console.log("PRF: servidor local iniciado."),
  );
