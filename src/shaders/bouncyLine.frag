precision highp float;

uniform vec3 uColor;
uniform float uOpacity;

varying vec2 vUv;

void main() {
  // 5-stop opacity ramp: [0.2, 0.05, 0.7, 0.05, 0.2]
  float t = vUv.x;
  float alpha;
  if (t < 0.25) {
    alpha = mix(0.2, 0.05, t / 0.25);
  } else if (t < 0.5) {
    alpha = mix(0.05, 0.7, (t - 0.25) / 0.25);
  } else if (t < 0.75) {
    alpha = mix(0.7, 0.05, (t - 0.5) / 0.25);
  } else {
    alpha = mix(0.05, 0.2, (t - 0.75) / 0.25);
  }

  gl_FragColor = vec4(uColor, alpha * uOpacity);
}
