precision highp float;

uniform vec2 uSize;           // Screen size in pixels
uniform vec2 uLightPos;       // Light position in pixels (Y=0 at top)
uniform vec2 uLogoPos;        // Logo center in pixels (Y=0 at top)
uniform vec2 uLogoSize;       // Logo dimensions in pixels
uniform sampler2D uLogoTexture;

varying vec2 vUv;

// Gold noise — jitter to hide ray march banding
float random(vec2 xy) {
  return fract(sin(dot(xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Sample logo alpha at a pixel-space position
float sampleAlpha(vec2 worldPos) {
  vec2 localPos = worldPos - (uLogoPos - uLogoSize * 0.5);
  vec2 uv = localPos / uLogoSize;

  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    return 0.0;
  }

  // Our pixel space has Y=0 at top, but WebGL textures have Y=0 at bottom
  uv.y = 1.0 - uv.y;
  float d = texture2D(uLogoTexture, uv).a;
  float edgeWidth = 0.5;
  return smoothstep(0.5 - edgeWidth, 0.5 + edgeWidth, d);
}

void main() {
  // Convert vUv to pixel coordinates matching Flutter's top-left origin
  vec2 pixelPos = vec2(vUv.x, 1.0 - vUv.y) * uSize;

  // --- COLORS ---
  vec3 floorColor = vec3(0.81, 0.66, 0.41);
  vec3 shadowColor = vec3(0.56, 0.3, 0.21);

  // Vector from pixel to light
  vec2 toLight = uLightPos - pixelPos;
  float distToLight = length(toLight);
  vec2 rayDir = normalize(toLight);

  // --- RAY MARCHING ---
  const int steps = 80;
  float stepSize = distToLight / float(steps);

  // Jitter start position
  float noise = random(pixelPos * 0.01);
  float currentDist = noise * stepSize;

  float shadowAccum = 0.0;
  float shadowSoftness = 6.0;

  for (int i = 0; i < steps; i++) {
    vec2 samplePos = pixelPos + rayDir * currentDist;
    float alpha = sampleAlpha(samplePos);

    if (alpha > 0.1) {
      float weight = 1.0 - (currentDist / distToLight);
      weight = pow(weight, 2.0);
      shadowAccum += alpha * weight * shadowSoftness / float(steps);
    }

    currentDist += stepSize;
  }

  float t = clamp(shadowAccum, 0.0, 1.0);

  // --- FINAL MIX ---
  vec3 noisyFloor = floorColor * (0.98 + 0.04 * noise);
  vec3 finalColor = mix(noisyFloor, shadowColor, t);

  // Sun glow
  float d = distToLight / uSize.y;
  float glow = exp(-d * 10.0) * 0.45;
  vec3 sunGlowColor = vec3(1.0, 0.75, 0.4);
  finalColor += sunGlowColor * glow;

  gl_FragColor = vec4(finalColor, 1.0);
}
