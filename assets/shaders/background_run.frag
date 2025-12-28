#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

vec4 tanh_polyline(vec4 x) {
    vec4 ex = exp(x);
    vec4 emx = exp(-x);
    return (ex - emx) / (ex + emx);
}

void main() {
    vec2 u = FlutterFragCoord().xy;
    vec4 o = vec4(0.0);

    // Initialize variables
    float d = 0.0;
    float s = 0.0;
    float t = uTime * 2.0;

    vec3 p_res = vec3(uResolution, 0.0);
    vec3 q = vec3(0.0);
    vec3 p = vec3(0.0);

    // Normalize coordinates
    u = (u - p_res.xy / 2.0) / p_res.y;

    // Raymarching loop
    // Using simple for-loop with integer index which is generally safe
    for(int loop_i = 0; loop_i < 100; loop_i++) {
        p = vec3(u * d, d + t);
        q = p;

        // start noise loop
        // Fixed iteration loop (7 steps covers 0.03 to ~2.0 with doubling)
        s = 0.03;
        for (int k = 0; k < 7; k++) {
            p += abs(dot(sin(p * s * 4.0), vec3(0.035))) / s;
            s += s;
        }

        // Fix vector arithmetic: Use explicit construction
        float cosVal = cos(p.x) * 0.2;
        vec3 term1 = vec3(0.2) - q - vec3(cosVal);
        vec3 term2 = vec3(2.5) + p;

        vec3 minVal = min(term1, term2);
        float valY = minVal.y;

        s = 0.04 + 0.6 * abs(valY);
        d += s;

        o += 1.0 / s;
    }

    float len = length(u - vec2(0.1));
    vec4 col = vec4(4.0, 2.0, 1.0, 1.0) * o / 4000.0 / len;
    o = tanh_polyline(col);

    fragColor = o;
}
