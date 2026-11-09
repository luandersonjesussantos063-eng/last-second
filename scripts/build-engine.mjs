import { build } from "esbuild";
import { mkdir, copyFile, readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
const root = new URL("../", import.meta.url),
  vendor = new URL("vendor/", root);
await mkdir(new URL("draco/", vendor), { recursive: true });
await build({
  stdin: {
    contents: `export * from 'three'; export {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js'; export {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js'; export {mergeVertices,mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js'; export {RoundedBoxGeometry} from 'three/addons/geometries/RoundedBoxGeometry.js';`,
    resolveDir: new URL(".", root).pathname,
  },
  bundle: true,
  format: "esm",
  minify: true,
  legalComments: "eof",
  outfile: new URL("engine.js", vendor).pathname,
});
for (const file of ["draco_wasm_wrapper.js", "draco_decoder.wasm"])
  await copyFile(
    new URL("node_modules/three/examples/jsm/libs/draco/gltf/" + file, root),
    new URL("draco/" + file, vendor),
  );
await copyFile(
  new URL("node_modules/three/LICENSE", root),
  new URL("LICENSE-three.txt", vendor),
);
const hashes = { version: "three@0.186.0", files: {} };
for (const file of [
  "engine.js",
  "draco/draco_wasm_wrapper.js",
  "draco/draco_decoder.wasm",
  "LICENSE-three.txt",
])
  hashes.files[file] = createHash("sha256")
    .update(await readFile(new URL(file, vendor)))
    .digest("hex");
await writeFile(
  new URL("manifest.json", vendor),
  JSON.stringify(hashes, null, 2) + "\n",
);
console.log("Engine local e decoder Draco preparados com hashes SHA-256.");
