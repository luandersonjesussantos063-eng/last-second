import * as T from "./vendor/engine.js?v=2.8.0";
const pending = new Map();
let prepare = async () => {};
export function setModelPreparation(callback) {
  prepare = callback ?? (async () => {});
}
export function loadModel(filename, limit = 5 * 1024 * 1024) {
  if (!pending.has(filename))
    pending.set(
      filename,
      (async () => {
        const abort = new AbortController(),
          timer = setTimeout(() => abort.abort(), 20000);
        try {
          const url = new URL(
              "./assets/models/" + filename + "?v=2.6.0",
              import.meta.url,
            ),
            response = await fetch(url, { signal: abort.signal });
          if (!response.ok) throw Error(filename + ": HTTP " + response.status);
          const data = await response.arrayBuffer();
          if (data.byteLength > limit)
            throw Error(filename + ": limite de tamanho");
          const gltf = await new T.GLTFLoader().parseAsync(
            data,
            new URL(".", url).href,
          );
          await prepare(gltf.scene);
          return { ...gltf, bytes: data.byteLength };
        } finally {
          clearTimeout(timer);
        }
      })(),
    );
  return pending.get(filename);
}
