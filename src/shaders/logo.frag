precision highp float;

uniform vec2 uSize;
uniform sampler2D uLogoTexture;
uniform vec3 uTint;
uniform float uOpacity;

varying vec2 vUv;

float getAlphaSDF(vec2 uv) {
  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    return 0.0;
  }
  float d = texture2D(uLogoTexture, uv).a;
  float edgeWidth = 0.5;
  return smoothstep(0.5 - edgeWidth, 0.5 + edgeWidth, d);
}

void main() {
  float alpha = getAlphaSDF(vUv);
  gl_FragColor = vec4(uTint, 1.0) * alpha * uOpacity;
}
