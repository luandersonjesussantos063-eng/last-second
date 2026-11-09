import { readFile, writeFile, mkdir, copyFile, cp, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";
const root = fileURLToPath(new URL("../", import.meta.url));
const output = path.join(root, "dist");
const modules = new Set();
async function visit(name) {
  if (modules.has(name)) return;
  if (path.isAbsolute(name) || name.startsWith(".."))
    throw Error("Módulo fora da raiz: " + name);
  modules.add(name);
  const source = await readFile(path.join(root, name), "utf8");
  for (const match of source.matchAll(
    /(?:from\s*|import\s*\(\s*)["'](\.\/[^"']+)["']/g,
  ))
    await visit(
      path.normalize(path.join(path.dirname(name), match[1].split("?")[0])),
    );
}
await visit("main.js");
const { version } = JSON.parse(
  await readFile(path.join(root, "package.json"), "utf8"),
);
const html = await readFile(path.join(root, "index.html"), "utf8");
if (!html.includes("main.js?v=" + version) || !html.includes("v" + version))
  throw Error("HTML fora da versão atual");
const manifest = JSON.parse(
  await readFile(path.join(root, "assets/models/manifest.json"), "utf8"),
);
const officer = JSON.parse(
  await readFile(
    path.join(root, "assets/models/officer-manifest.json"),
    "utf8",
  ),
);
const fleet = JSON.parse(
  await readFile(path.join(root, "assets/models/fleet-manifest.json"), "utf8"),
);
const modelHashes = {};
for (const entry of [
  manifest,
  officer,
  ...Object.entries(fleet.files).map(([file, data]) => ({ file, ...data })),
]) {
  const bytes = await readFile(path.join(root, "assets/models", entry.file));
  if (createHash("sha256").update(bytes).digest("hex") !== entry.sha256)
    throw Error("Modelo GLB não corresponde ao manifesto: " + entry.file);
  modelHashes[entry.file] = entry.sha256;
}
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const name of [
  ...modules,
  "index.html",
  "icon.svg",
  "vendor/LICENSE-three.txt",
  "vendor/manifest.json",
]) {
  const destination = path.join(output, name);
  await mkdir(path.dirname(destination), { recursive: true });
  await copyFile(path.join(root, name), destination);
}
await cp(path.join(root, "assets"), path.join(output, "assets"), {
  recursive: true,
});
await writeFile(path.join(output, ".nojekyll"), "");
await writeFile(
  path.join(output, "release.json"),
  JSON.stringify(
    {
      version,
      commit: process.env.GITHUB_SHA ?? null,
      model_sha256: manifest.sha256,
      model_hashes: modelHashes,
    },
    null,
    2,
  ) + "\n",
);
console.log(
  `Site estático ${version}: ${modules.size} módulos locais, áudio, GLB e licenças preparados em dist/.`,
);
