#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uReveal; // 0.0 to 1.0 for entry bloom pulse

out vec4 fragColor;

#define PI 3.14159265359
#define NUM_LIGHTS 4

// Banding reduction noise
float gradientNoise(vec2 uv) {
    const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}

// Color palette generator
vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

// Linear mapping function
float map(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

void main() {
    // 1. Get Flutter coordinates (Physical pixels)
    vec2 fragCoord = FlutterFragCoord().xy;

    // 2. Invert Y-axis to match Shadertoy's bottom-left origin logic
    vec2 shadertoyCoord = vec2(fragCoord.x, uSize.y - fragCoord.y);

    // 3. Normal UV calculation
    vec2 uv = (2.0 * shadertoyCoord - uSize.xy) / uSize.y;
    float time = uTime * 0.75;

    vec3 finalColor = vec3(0.0);
    float sumWeights = 0.0;

    vec3 bgColor = vec3(0.75);
    float bgWeight = 0.025;
    finalColor += bgColor * bgWeight;
    sumWeights += bgWeight;

    for (float i = 0.0; i < float(NUM_LIGHTS); i++) {
        float n = i / float(NUM_LIGHTS);
        float wave = sin(n * PI + time) * 0.5 + 0.5;

        float distance = 0.6 + wave * 0.125;
        vec2 position = vec2(
        cos(n * PI * 2.0 + time * 0.1) * distance,
        sin(n * PI * 2.0 + time * 0.1) * distance
        );

        float d = 0.2;

        vec2 toLight = position - uv;
        float distFragLight = length(toLight);

        // Conditional check for light center
        distFragLight = distFragLight < d ? 1000.0 : distFragLight;

        float angle = atan(toLight.y, toLight.x);
        angle = angle / (PI * 2.0) + 0.5; // normalize
        angle += time * 0.25;

        float decayRate = map(wave, 0.0, 1.0, 6.0, 16.0);
        float distanceFactor = exp(-1.0 * decayRate * distFragLight);

        vec3 color = palette(
        distanceFactor + angle,
        vec3(0.5, 0.5, 0.5),
        vec3(0.5, 0.5, 0.5),
        vec3(1.0, 1.0, 1.0),
        vec3(0.0, 0.10, 0.20)
        );

        vec3 lightColor = color * distFragLight * distanceFactor;

        finalColor += lightColor;
        sumWeights += distanceFactor * distFragLight;
    }

    // Normalization and Gamma Correction
    finalColor = finalColor / sumWeights;
    
    // **BLOOM REVEAL PULSE**: Intensify colors during entry (uReveal: 0.0 → 1.0)
    // Creates a "powering on" effect as the world materializes
    float bloomIntensity = mix(1.0, 1.5, uReveal);
    finalColor *= bloomIntensity;
    
    finalColor = pow(finalColor, vec3(1.0 / 2.2));

    // Banding Dither
    finalColor += (1.0/255.0) * gradientNoise(fragCoord) - (0.5/255.0);

    fragColor = vec4(finalColor, 1.0);
}