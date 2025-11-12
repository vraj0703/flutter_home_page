#version 460 core

// --- UNIFORMS ---
uniform vec2 uResolution;
uniform vec2 uLightPos;
uniform vec2 uLogoPos;
uniform vec2 uLogoSize;
uniform sampler2D uTexture;

out vec4 fragColor;

// --- SETTINGS ---
// --- FIX 1: INCREASED RAY MARCHING DISTANCE ---
const int MAX_STEPS = 200;   // Increased from 150
const float STEP_SIZE = 0.006; // Increased from 0.002
// Max distance is now 200 * 0.006 = 1.2, which is enough to cross the screen.

const float DENSITY = 0.8;

// --- FIX 2: WIDER, MORE AGGRESSIVE DECAY RANGE ---
// The decay rate when the light is at the screen edge (long shadows)
const float MIN_SHADOW_DECAY = 0.02; // Was 0.05
// The decay rate when the light is at the screen center (short shadows)
const float MAX_SHADOW_DECAY = 8.0;  // Was 0.5


// Colors
const vec3 COLOR_BG = vec3(0.85, 0.85, 0.83);
const vec3 COLOR_SHADOW = vec3(0.55, 0.55, 0.58);
const vec3 COLOR_LIGHT = vec3(1.0, 0.9, 0.6);
const vec3 COLOR_GLOW = vec3(1.0, 0.6, 0.2);

// Helper to check if a pixel hits the Logo
float getAlpha(vec2 uv) {
    vec2 pixelPos = uv * uResolution;
    vec2 offset = pixelPos - (uLogoPos - uLogoSize * 0.5);
    vec2 localUV = offset / uLogoSize;

    if (localUV.x < 0.0 || localUV.x > 1.0 || localUV.y < 0.0 || localUV.y > 1.0) {
        return 0.0;
    }

    return texture(uTexture, vec2(localUV.x, 1.0 - localUV.y)).a;
}

void main() {
    // Normalize screen coords (Y-flipped)
    vec2 uv = vec2(gl_FragCoord.x, uResolution.y - gl_FragCoord.y) / uResolution;
    vec2 lightUV = vec2(uLightPos.x, uResolution.y - uLightPos.y) / uResolution;

    float aspect = uResolution.x / uResolution.y;

    // Correct aspect for math
    vec2 p = uv; p.x *= aspect;
    vec2 l = lightUV; l.x *= aspect;

    // --- DYNAMIC SHADOW CALCULATION ---
    vec2 lightNDC = lightUV * 2.0 - 1.0;
    float distFromCenter = clamp(length(lightNDC), 0.0, 1.0);

    // Interpolate between max and min decay based on the distance from center.
    // The new, wider range will create a much more noticeable effect.
    float dynamicShadowDecay = mix(MAX_SHADOW_DECAY, MIN_SHADOW_DECAY, distFromCenter);


    // --- RAY MARCHING ---
    vec2 dir = l - p;
    float distToLight = length(dir);
    dir /= distToLight;

    float shadowAccum = 0.0;
    float marchDist = 0.0;
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);

    for(int i = 0; i < MAX_STEPS; i++) {
        vec2 samplePos = uv + (dir * (marchDist + noise * 0.005) / aspect);
        float objectAlpha = getAlpha(samplePos);

        if(objectAlpha > 0.05) {
            float blockage = objectAlpha * (1.0 - marchDist * dynamicShadowDecay);
            shadowAccum = max(shadowAccum, blockage);

            if(shadowAccum >= 1.0) break;
        }

        marchDist += STEP_SIZE;
        // This break condition is still important to prevent shadows appearing in front of the light
        if(marchDist > distToLight) break;
    }

    shadowAccum = clamp(shadowAccum * DENSITY, 0.0, 1.0);

    // --- COMPOSITING ---
    vec3 finalColor = COLOR_BG;
    finalColor = mix(finalColor, COLOR_SHADOW, shadowAccum);

    float d = distance(p, l);
    float core = smoothstep(0.02, 0.01, d);
    float glow = exp(-d * 12.0) * 0.8;

    finalColor += (COLOR_LIGHT * core) + (COLOR_GLOW * glow);
    fragColor = vec4(finalColor, 1.0);
}