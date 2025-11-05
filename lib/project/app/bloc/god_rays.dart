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
uniform float fTime; 
uniform float fAspect;

const int NUM_SAMPLES = 50;

// Simple pseudo-random noise function
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
  // --- ADD NOISE ---
  // Create a random offset based on screen position and time
  float dither = rand(vUv + fTime);
 
  vec2 delta = vSunPositionScreen - vUv;
  delta.x *= fAspect;
  
  float dist = length(delta);
  vec2 step = delta / dist / float(NUM_SAMPLES);
  step.x /= fAspect;
  
  // Apply the random offset to the starting position
  vec2 uv = vUv + dither * step; 

  float illuminationDecay = 1.0;
  vec4 c = texture2D(tDiffuse, uv); // Use the new 'uv'
  vec4 result = c * fWeight;

  for (int i = 0; i < NUM_SAMPLES; i++) {
    // Use the new 'uv' here as well
    c = texture2D(tDiffuse, uv + float(i) * step); 
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
    'tDiffuse': {'value': null},
    'vSunPositionScreen': {'value': three.Vector2(0.5, 0.5)},
    'fDensity': {'value': 0.96},
    'fWeight': {'value': 0.1},
    'fDecay': {'value': 0.98},
    'fExposure': {'value': 0.1},
    'fClamp': {'value': .6},
    'fTime': {'value': 0.0},
    'fAspect': {'value': 1.0},
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
  // vec4 screenColor = sceneColor + godRayColor;
  
  // Linear Interpolation (Mix)
  // vec4 screenColor = mix(sceneColor, godRayColor, 0.1);
  
  // Screen Blending (A softer alternative)
  // vec4 screenColor = 1.0 - (1.0 - sceneColor) * (1.0 - godRayColor);
  
  // Luminance Masking (a better solution)
  // 1. Calculate the brightness of the main scene
  float sceneLuminance = dot(sceneColor.rgb, vec3(0.299, 0.587, 0.114));
  
  // 2. Create a mask that is 1.0 in dark areas and 0.0 in bright areas
  //    (You can tweak 0.1 and 0.4 to change the fade-off)
  float rayMask = 1.0 - smoothstep(0.1, 0.9, sceneLuminance);
  
  // 3. Apply the mask to the god rays before adding them
  vec4 screenColor = sceneColor + godRayColor * rayMask;
  
  gl_FragColor = screenColor;
}
""";

final Map<String, dynamic> godRaysCombineShader = {
  'uniforms': {
    'tDiffuse': {'value': null},
    // This will be the main scene
    'tGodRays': {'value': null},
    // This will be the output from the generate pass
  },
  'vertexShader': _combineVertexShader,
  'fragmentShader': _combineFragmentShader,
};
