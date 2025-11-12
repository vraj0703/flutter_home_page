#version 460 core

// --- UNIFORMS ---
uniform vec2 uResolution;
uniform vec2 uLightPos;
uniform vec2 uLogoPos;
uniform vec2 uLogoSize;
uniform sampler2D uTexture;

out vec4 fragColor;

// --- SETTINGS ---
const int MAX_STEPS = 150;
const float DENSITY = 0.8;
const float STEP_SIZE = 0.002;
const float SHADOW_DECAY = 0.3;

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
    // Normalize screen coords
    vec2 uv = vec2(gl_FragCoord.x, uResolution.y - gl_FragCoord.y) / uResolution;
    vec2 lightUV = vec2(uLightPos.x, uLightPos.y) / uResolution;

    float aspect = uResolution.x / uResolution.y;

    // Correct aspect for math
    vec2 p = uv; p.x *= aspect;
    vec2 l = lightUV; l.x *= aspect;

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
            float blockage = objectAlpha * (1.0 - marchDist * SHADOW_DECAY);
            shadowAccum = max(shadowAccum, blockage);

            if(shadowAccum >= 1.0) break;
        }

        marchDist += STEP_SIZE;
        if(marchDist > distToLight) break;
    }

    shadowAccum = clamp(shadowAccum * DENSITY, 0.0, 1.0);

    // --- COMPOSITING ---
    vec3 finalColor = COLOR_BG;

    // Apply Shadow
    finalColor = mix(finalColor, COLOR_SHADOW, shadowAccum);

    // Draw Light/Glow
    float d = distance(p, l);

    // 1. REDUCED CORE RADIUS
    // Was smoothstep(0.04, 0.02, d). Changed to 0.02, 0.01 to make it half the size.
    float core = smoothstep(0.02, 0.01, d);

    // 2. REDUCED GLOW SPREAD
    // Was exp(-d * 6.0). Increased 6.0 to 12.0 to make the glow fade twice as fast.
    float glow = exp(-d * 12.0) * 0.8;

    finalColor += (COLOR_LIGHT * core) + (COLOR_GLOW * glow);

    fragColor = vec4(finalColor, 1.0);
}