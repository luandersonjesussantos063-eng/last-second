import { readFile, writeFile, readdir } from "node:fs/promises";
const root = new URL("../", import.meta.url);
const { version } = JSON.parse(
  await readFile(new URL("package.json", root), "utf8"),
);
for (const name of await readdir(root)) {
  if (!name.endsWith(".js")) continue;
  const file = new URL(name, root),
    source = await readFile(file, "utf8");
  const updated = source
    .replace(
      /((?:from\s*|import\s*\(\s*)["'])(\.\/(?!vendor\/)[^"'?]+\.js)(?:\?v=[^"']+)?(["'])/g,
      `$1$2?v=${version}$3`,
    )
    .replace(/LAST SECOND v\d+\.\d+(?:\.\d+)?/g, `LAST SECOND v${version}`);
  if (updated !== source) await writeFile(file, updated);
}
const index = new URL("index.html", root),
  source = await readFile(index, "utf8");
await writeFile(
  index,
  source
    .replace(/main\.js\?v=[^"']+/g, `main.js?v=${version}`)
    .replace(
      /v\d+\.\d+(?:\.\d+)? (?:BASE OPERACIONAL|PATRULHA ESPACIAL)/g,
      `v${version} PATRULHA ESPACIAL`,
    ),
);
console.log("Versão dos módulos sincronizada: " + version);
