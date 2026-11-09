// Small procedural textures are created once; no extra image downloads or frame-time noise.
export function planetTexture(THREE, mobile = false) {
  const canvas = document.createElement("canvas");
  canvas.width = mobile ? 256 : 512;
  canvas.height = canvas.width / 2;
  const ctx = canvas.getContext("2d"),
    image = ctx.createImageData(canvas.width, canvas.height),
    pixels = image.data;
  for (let y = 0; y < canvas.height; y++) {
    const latitude = (y / canvas.height - 0.5) * Math.PI,
      sinLat = Math.sin(latitude),
      cosLat = Math.cos(latitude);
    for (let x = 0; x < canvas.width; x++) {
      const longitude = (x / canvas.width) * Math.PI * 2,
        nx = cosLat * Math.cos(longitude),
        nz = cosLat * Math.sin(longitude);
      const terrain =
        Math.sin(nx * 5 + nz * 3) * Math.cos(sinLat * 6 - nz * 2) +
        0.4 * Math.sin(nx * 17 + sinLat * 11 + nz * 13);
      const ice = Math.abs(sinLat) > 0.87,
        land = terrain > 0.25,
        shade = terrain * 0.1,
        offset = (y * canvas.width + x) * 4;
      const color = ice
        ? [170, 210, 220]
        : land
          ? [36 + shade * 40, 105 + shade * 80, 91 + shade * 50]
          : [13, 48 + shade * 35, 102 + shade * 50];
      pixels[offset] = color[0];
      pixels[offset + 1] = color[1];
      pixels[offset + 2] = color[2];
      pixels[offset + 3] = 255;
    }
  }
  ctx.putImageData(image, 0, 0);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
export function moonTexture(THREE) {
  const canvas = document.createElement("canvas");
  canvas.width = 256;
  canvas.height = 128;
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "#9696a0";
  ctx.fillRect(0, 0, 256, 128);
  let seed = 1729;
  const random = () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  for (let i = 0; i < 80; i++) {
    const x = random() * 256,
      y = random() * 128,
      r = 1 + random() * 8,
      g = ctx.createRadialGradient(
        x - r * 0.15,
        y - r * 0.15,
        r * 0.2,
        x,
        y,
        r,
      );
    g.addColorStop(0, "#6b6a75");
    g.addColorStop(0.75, "#868590");
    g.addColorStop(0.9, "#b0afb8");
    g.addColorStop(1, "#9696a0");
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
export function atmosphereMaterial(THREE) {
  return new THREE.ShaderMaterial({
    uniforms: { tint: { value: new THREE.Color(0x4aa9ff) } },
    side: THREE.BackSide,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    vertexShader:
      "varying vec3 normalView; varying vec3 viewPosition; void main(){vec4 p=modelViewMatrix*vec4(position,1.0);normalView=normalize(normalMatrix*normal);viewPosition=-p.xyz;gl_Position=projectionMatrix*p;}",
    fragmentShader:
      "uniform vec3 tint;varying vec3 normalView;varying vec3 viewPosition;void main(){float rim=pow(1.0-abs(dot(normalize(normalView),normalize(viewPosition))),3.0);gl_FragColor=vec4(tint,rim*.65);\n#include <colorspace_fragment>\n}",
  });
}
