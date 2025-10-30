// god_rays_shaders.dart

import 'package:three_dart/three_dart.dart' as three;

// -----------------------------------------------------------------
// SHADER 1: GodRaysGenerateShader
// -----------------------------------------------------------------
// Takes the occlusion mask (black planet, white sun) and
// performs a radial blur from the sun's position to create the rays.

const String _generateVertexShader = """
varying vec2 vUv;

void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}
""";

const String _generateFragmentShader = """
varying vec2 vUv;
uniform sampler2D tDiffuse;
uniform vec2 vSunPositionScreen;
uniform float fDensity;
uniform float fWeight;
uniform float fDecay;
uniform float fExposure;
uniform float fClamp;

const int NUM_SAMPLES = 120;

void main() {
  vec2 delta = vSunPositionScreen - vUv;
  float dist = length(delta);
  vec2 step = delta / dist / float(NUM_SAMPLES);
  float illuminationDecay = 1.0;

  vec4 c = texture2D(tDiffuse, vUv);
  vec4 result = c * fWeight;

  for (int i = 0; i < NUM_SAMPLES; i++) {
    c = texture2D(tDiffuse, vUv + float(i) * step);
    c.rgb *= illuminationDecay * fWeight;
    result.rgb += c.rgb;
    illuminationDecay *= fDecay;
  }

  result = result * fExposure;
  result = clamp(result, 0.0, fClamp);
  gl_FragColor = result;
}
""";

final Map<String, dynamic> godRaysGenerateShader = {
  'uniforms': {
    'tDiffuse': {'value': three.Texture()},
    //'tOcclusion': {'value': godraysRenderTarget.texture},
    'vSunPositionScreen': {'value': three.Vector2(0.5, 0.5)},
    'fExposure': {'value': 0.1}, // Intensity
    'fDecay': {'value': 0.98},   // How fast rays decay
    'fDensity': {'value': 0.01}, // Density of rays
    'fWeight': {'value': 0.01},  // Weight of each sample
    'fClamp': {'value': 0.2},
  },
  'vertexShader': _generateVertexShader,
  'fragmentShader': _generateFragmentShader,
};


// -----------------------------------------------------------------
// SHADER 2: GodRaysCombineShader
// -----------------------------------------------------------------
// Additively blends the original scene (tDiffuse) with the
// generated god rays (tGodRays).

const String _combineVertexShader = """
varying vec2 vUv;

void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}
""";

const String _combineFragmentShader = """
varying vec2 vUv;
uniform sampler2D tDiffuse;
uniform sampler2D tGodRays;

void main() {
  vec4 sceneColor = texture2D(tDiffuse, vUv);
  vec4 godRayColor = texture2D(tGodRays, vUv);
  
  // Additive blending
  gl_FragColor = sceneColor + godRayColor;
}
""";

final Map<String, dynamic> godRaysCombineShader = {
  'uniforms': {
    'tDiffuse': {'value': null}, // This will be the main scene
    'tGodRays': {'value': null}, // This will be the output from the generate pass
  },
  'vertexShader': _combineVertexShader,
  'fragmentShader': _combineFragmentShader,
};