#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec2 uMouse;
uniform sampler2D uNoiseTexture; // Index 0

out vec4 fragColor;

// --- CAMERA SETUP ---
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

// --- NOISE SAMPLING (Using your PNG) ---
float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);

    // Using the 2D texture as a 3D volume source
    vec2 uv = (p.xy + vec2(37.0, 239.0) * p.z) + f.xy;
    // Normalized by 256.0 (standard noise texture size)
    vec2 rg = texture(uNoiseTexture, (uv + 0.5) / 256.0).yx;
    return mix(rg.x, rg.y, f.z) * 2.0 - 1.0;
}

float map(in vec3 p) {
    // Moves clouds over time
    vec3 q = p - vec3(0.0, 0.1, 1.0) * uTime;

    float f;
    f  = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q); q = q * 2.01;
    f += 0.06250 * noise(q);

    // Height and density calculation
    return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

const vec3 sundir = vec3(-0.7071, 0.0, -0.7071);

// --- RAYMARCHING ENGINE ---
vec4 raymarch(in vec3 ro, in vec3 rd, in vec3 bgcol) {
    vec4 sum = vec4(0.0);
    float t = 0.05;

    // 80 steps - balanced for Flutter Web/Mobile
    for (int i = 0; i < 80; i++) {
        vec3 pos = ro + t * rd;
        if (pos.y < -3.0 || pos.y > 2.0 || sum.a > 0.99) break;

        float den = map(pos);
        if (den > 0.01) {
            float dif = clamp((den - map(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
            vec3 lin = vec3(1.0, 0.6, 0.3) * dif + vec3(0.91, 0.98, 1.05);
            vec4 col = vec4(mix(vec3(1.0, 0.95, 0.8), vec3(0.25, 0.3, 0.35), den), den);
            col.xyz *= lin;
            col.xyz = mix(col.xyz, bgcol, 1.0 - exp(-0.003 * t * t));
            col.w *= 0.4;
            col.rgb *= col.a;
            sum += col * (1.0 - sum.a);
        }
        t += max(0.06, 0.05 * t);
    }
    return clamp(sum, 0.0, 1.0);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 p = (2.0 * fragCoord - uSize.xy) / uSize.y;
    vec2 m = uMouse.xy / uSize.xy;

    // Camera Pos
    vec3 ro = 4.0 * normalize(vec3(sin(3.0 * m.x), 0.8 * m.y, cos(3.0 * m.x))) - vec3(0.0, 0.1, 0.0);
    vec3 ta = vec3(0.0, -1.0, 0.0);
    mat3 ca = setCamera(ro, ta, 0.07 * cos(0.25 * uTime));

    // Ray Dir
    vec3 rd = ca * normalize(vec3(p.xy, 1.5));

    // Sky Colors
    float sun = clamp(dot(sundir, rd), 0.0, 1.0);
    vec3 col = vec3(0.6, 0.71, 0.75) - rd.y * 0.2 * vec3(1.0, 0.5, 1.0) + 0.075;
    col += 0.2 * vec3(1.0, 0.6, 0.1) * pow(sun, 8.0);

    // Clouds Overlay
    vec4 res = raymarch(ro, rd, col);
    col = col * (1.0 - res.w) + res.xyz;

    // Sun Glare
    col += vec3(0.2, 0.08, 0.04) * pow(sun, 3.0);

    fragColor = vec4(col, 1.0);
}
