import { build } from "esbuild";
import { mkdir, copyFile, readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
const root = new URL("../", import.meta.url),
  vendor = new URL("vendor/", root);
await mkdir(vendor, { recursive: true });
await build({
  stdin: {
    contents: `export {Scene,Color,Fog,Vector2,MeshPhysicalMaterial,PCFSoftShadowMap,AnimationMixer,Box3,PerspectiveCamera,WebGLRenderer,Group,Mesh,BoxGeometry,InstancedMesh,Object3D,PlaneGeometry,SphereGeometry,CylinderGeometry,TorusGeometry,CapsuleGeometry,ConeGeometry,CircleGeometry,IcosahedronGeometry,Vector3,CanvasTexture,MeshStandardMaterial,MeshBasicMaterial,HemisphereLight,DirectionalLight,PointLight,SRGBColorSpace,ACESFilmicToneMapping,DoubleSide,BackSide,RepeatWrapping,DynamicDrawUsage,MathUtils} from 'three'; export {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js'; export {RoundedBoxGeometry} from 'three/addons/geometries/RoundedBoxGeometry.js'; export {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js'; export {clone as cloneRig} from 'three/addons/utils/SkeletonUtils.js'; export {EffectComposer} from 'three/addons/postprocessing/EffectComposer.js'; export {RenderPass} from 'three/addons/postprocessing/RenderPass.js'; export {UnrealBloomPass} from 'three/addons/postprocessing/UnrealBloomPass.js'; export {SSAOPass} from 'three/addons/postprocessing/SSAOPass.js'; export {SSRPass} from 'three/addons/postprocessing/SSRPass.js'; export {OutputPass} from 'three/addons/postprocessing/OutputPass.js';`,
    resolveDir: new URL(".", root).pathname,
  },
  bundle: true,
  format: "esm",
  minify: true,
  legalComments: "eof",
  outfile: new URL("engine.js", vendor).pathname,
});
await copyFile(
  new URL("node_modules/three/LICENSE", root),
  new URL("LICENSE-three.txt", vendor),
);
const hashes = { version: "three@0.186.0", files: {} };
for (const file of ["engine.js", "LICENSE-three.txt"])
  hashes.files[file] = createHash("sha256")
    .update(await readFile(new URL(file, vendor)))
    .digest("hex");
await writeFile(
  new URL("manifest.json", vendor),
  JSON.stringify(hashes, null, 2) + "\n",
);
console.log("Engine rodoviário local preparado com hashes SHA-256.");
