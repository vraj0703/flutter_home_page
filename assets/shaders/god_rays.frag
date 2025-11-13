#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;// Screen Size
uniform vec2 uLightPos;// Light Position
uniform vec2 uLogoPos;// Logo Center
uniform vec2 uLogoSize;// Logo Size
uniform vec2 uCursorPos;
uniform sampler2D uLogoTexture;// Your current logo image

out vec4 fragColor;

// Random Noise Generator (Gold Noise)
float random(vec2 xy) {
    return fract(tan(distance(xy * 1.61803398874989484820459, xy) * 1.41421356237309504880169));
}

// Simple texture sampler
float sampleAlpha(vec2 worldPos) {
    vec2 localPos = worldPos - (uLogoPos - uLogoSize * 0.5);
    vec2 uv = localPos / uLogoSize;

    // If outside the logo box, return 0 (No object)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return 0.0;
    }

    // Sample Alpha
    return texture(uLogoTexture, uv).a;
}

void main() {
    vec2 pixelPos = FlutterFragCoord().xy;

    // --- COLORS ---
    // Adjust these to match your video reference exactly
    vec4 floorColor = vec4(0.85, 0.85, 0.85, 1.0);// Light Grey Base
    vec4 shadowColor = vec4(0.50, 0.50, 0.50, 1.0);// Darker Shadow

    // Vector from pixel to light
    vec2 toLight = uLightPos - pixelPos;
    float distToLight = length(toLight);
    vec2 rayDir = normalize(toLight);

    // --- OPTIMIZATION ---
    // 1. If pixel is inside the light radius, no shadow
    if (distToLight < 20.0) {
        fragColor = floorColor;
        return;
    }

    // --- RAY MARCHING SETUP ---
    const int steps = 40;// Lower steps = more performance. Jitter hides the low count.
    float stepSize = distToLight / float(steps);

    // --- THE SECRET SAUCE: JITTER ---
    // We offset the start position by a random amount (0.0 to 1.0)
    // This turns "Banding Artifacts" into "Cinematic Grain"
    float noise = random(pixelPos);
    float currentDist = noise * stepSize;

    float shadowAccumulation = 0.0;
    float shadowSoftness = 6.0;// Controls how "foggy" the shadow looks

    // --- THE LOOP ---
    for (int i = 0; i < steps; i++) {
        vec2 samplePos = pixelPos + rayDir * currentDist;

        float alpha = sampleAlpha(samplePos);

        if (alpha > 0.1) {
            // Distance Weighting:
            // Objects close to pixel (small currentDist) = Sharp Shadow
            // Objects far from pixel (large currentDist) = Soft/No Shadow
            float weight = 1.0 - (currentDist / distToLight);
            weight = pow(weight, 2.0);// Curve the falloff for realism

            shadowAccumulation += alpha * weight * shadowSoftness / float(steps);
        }

        // Move ray forward
        currentDist += stepSize;
    }

    // Clamp shadow intensity
    float t = clamp(shadowAccumulation, 0.0, 1.0);

    // --- FINAL MIX ---
    // Apply the shadow to the floor color
    // We also add a tiny bit of noise to the floor itself for texture
    vec4 noisyFloor = floorColor * (0.98 + 0.04 * noise);

    vec4 finalColor = mix(noisyFloor, shadowColor, t);

    float d = distToLight / uSize.y;

    // 2. The Core (The physical light bulb)
    // 0.015 = roughly 1.5% of screen height
    // We invert smoothstep to make the center solid and edge transparent
    float core = 1.0 - smoothstep(0.0, 0.015, d);

    // 3. The Glow (The Atmosphere)
    // exp() creates that beautiful "Dune" bloom
    float glow = exp(-d * 30.0) * 0.85;

    // 4. Define Colors
    //vec3 sunCoreColor = vec3(1.0, 1.0, 0.9);// White-hot center
    vec3 sunGlowColor = vec3(1.0, 0.7, 0.3);// Golden orange halo

    // 5. Additive Blending (Physics)
    // We add the core and glow on top of the shadowed floor
    finalColor += vec4(sunGlowColor * glow, 1.0);
    fragColor = finalColor;
}

