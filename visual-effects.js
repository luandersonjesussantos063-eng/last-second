import * as T from "./vendor/engine.js?v=2.22.0";

// Passes pesados só no modo Cinemático do computador; render direto nos demais.
// O motor do jogo continua totalmente local, sem CDN ou novas bibliotecas pagas.
export function createVisualEffects(renderer, scene, camera, reflectors = [], mobile = false) {
  let composer = null;
  let bloom = null;
  let ao = null;
  let reflections = null;
  let enabled = false;
  let unavailable = false;
  let width = Math.max(1, window.innerWidth);
  let height = Math.max(1, window.innerHeight);
  let ratio = renderer.getPixelRatio();

  function build() {
    if (composer || mobile || unavailable) return;
    const pipeline = new T.EffectComposer(renderer);
    pipeline.addPass(new T.RenderPass(scene, camera));

    // SSR seletivo, em meia resolução e somente durante chuva.
    if (reflectors.length) {
      reflections = new T.SSRPass({
        renderer, scene, camera, width, height, selects: reflectors
      });
      reflections.selective = true;
      reflections.resolutionScale = 0.5;
      reflections.maxDistance = 18;
      reflections.opacity = 0.18;
      reflections.blur = true;
      reflections.enabled = false;
      pipeline.addPass(reflections);
    }

    // Oclusão por espaço de tela: junta rodas, paredes e objetos ao chão.
    ao = new T.SSAOPass(scene, camera, width, height, 16);
    ao.kernelRadius = 5;
    ao.minDistance = 0.005;
    ao.maxDistance = 0.08;
    pipeline.addPass(ao);

    // Luzes fortes recebem um halo suave, preservando os detalhes do cenário.
    bloom = new T.UnrealBloomPass(new T.Vector2(width, height), 0.28, 0.38, 0.88);
    pipeline.addPass(bloom);
    pipeline.addPass(new T.OutputPass());
    pipeline.setPixelRatio(Math.min(1, ratio));
    pipeline.setSize(width, height);
    composer = pipeline;
  }

  function setEnabled(next) {
    enabled = Boolean(next) && !mobile && !unavailable;
    if (enabled && !composer) {
      try {
        build();
      } catch (error) {
        enabled = false;
        unavailable = true;
        console.warn("Efeitos avançados indisponíveis; renderização padrão mantida.", error);
      }
    }
    if (enabled && !composer) enabled = false;
    renderer.domElement.style.filter = enabled
      ? "contrast(1.055) saturate(1.12)"
      : "contrast(1.025) saturate(1.045)";
    return enabled;
  }

  function update(s, environment) {
    const wet = s.operations?.weather?.kind === "rain";
    const night = Math.max(0, Math.min(1, environment?.night ?? 0));
    // Color grading com exposição suave: faróis legíveis sem estourar o céu.
    renderer.toneMappingExposure = 1.14 - night * 0.16 - (wet ? 0.035 : 0);
    if (bloom) bloom.strength = 0.22 + night * 0.24 + (wet ? 0.08 : 0);
    if (reflections) reflections.enabled = enabled && wet;
  }

  function render(deltaSeconds = 0) {
    if (!enabled || !composer) {
      renderer.render(scene, camera);
      return;
    }
    try {
      composer.render(deltaSeconds);
    } catch (error) {
      enabled = false;
      unavailable = true;
      renderer.setRenderTarget(null);
      renderer.domElement.style.filter = "none";
      console.warn("Pós-processamento desativado após erro; cena preservada.", error);
      renderer.render(scene, camera);
    }
  }

  function resize(w, h) {
    width = Math.max(1, w);
    height = Math.max(1, h);
    composer?.setSize(width, height);
  }

  function setPixelRatio(value) {
    ratio = Math.max(0.5, value);
    // Evita multiplicar o custo dos buffers de SSR e SSAO em telas HiDPI.
    composer?.setPixelRatio(Math.min(1, ratio));
  }

  return { setEnabled, update, render, resize, setPixelRatio,
    get enabled() { return enabled; } };
}
