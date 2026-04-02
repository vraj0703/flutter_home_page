#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uPixelRatio;

out vec4 fragColor;

#define PI 3.14159265359
#define NUM_LIGHTS 1

float gradientNoise(vec2 uv) {
    const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

void main() {
    // FlutterFragCoord() returns logical coords in Flutter's shader pipeline
    vec2 fragCoord = FlutterFragCoord().xy;
    fragCoord.y = uSize.y - fragCoord.y; // Flip Y to match standard math coords

    // Standard UV normalization logic
    float minSize = min(uSize.x, uSize.y);
    vec2 uv = (2.0 * fragCoord - uSize.xy) / minSize;
    float time = uTime * 0.75;

    vec3 finalColor = vec3(0.0);
    float sumWeights = 0.0;

    vec3 bgColor = vec3(0.75);
    float bgWeight = 0.025;
    finalColor += bgColor * bgWeight;
    sumWeights += bgWeight;

    for (int i = 0; i < NUM_LIGHTS; i++) {
        float n = float(i) / float(NUM_LIGHTS);
        float wave = sin(n * PI + time) * 0.5 + 0.5;

        float distance = 0.6 + wave * 0.125;
        vec2 position = vec2(-uSize.x / minSize, 0.0);

        float d = 0.8;

        vec2 toLight = position - uv;
        float distFragLight = length(toLight);
        distFragLight = distFragLight < d ? 1000.0 : distFragLight;

        float angle = atan(toLight.y, toLight.x);
        angle = angle / (PI * 2.0) + 0.5; // normalize
        angle += time * 0.25;

        float decayRate = map(wave, 0.0, 1.0, 1.5, 4.5);

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

    finalColor = finalColor / sumWeights;
    finalColor = pow(finalColor, vec3(1.0 / 2.2)); // Gamma correction

    // Banding fix using noise
    finalColor += (1.0 / 255.0) * gradientNoise(fragCoord) - (0.5 / 255.0);

    fragColor = vec4(finalColor, 1.0);
}