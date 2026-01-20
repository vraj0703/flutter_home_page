#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;            
uniform float uScrollProgress; 
uniform sampler2D uTexture;    
uniform vec2 uTextSize;        

out vec4 fragColor;

// Increased star count for density
#define NUM_STARS 800 
// Hex C78E53 to RGB normalized
const vec3 GOLD = vec3(0.78, 0.55, 0.32); 

float rand(float x) {
    return fract(sin(x) * 123.456);
}

float cross2(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

float getDistanceLP(vec2 s, vec2 t, vec2 p) {
    return abs(cross2(t - s, p - s) / distance(t, s));
}

float getDistanceSP(vec2 s, vec2 t, vec2 p) {
    if (dot(t - s, p - s) < 0.) return distance(p, s);
    if (dot(s - t, p - t) < 0.) return distance(p, t);
    return getDistanceLP(s, t, p);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = (fragCoord - .5 * uSize.xy) / uSize.y;
    
    vec3 starCol = vec3(0.0);
    float starAlpha = 0.0;
    
    // --- PROGRESS MAPPING ---
    float t = 0.0;
    // We create a "Snap" plateau between 0.4 and 0.6
    if (uScrollProgress < 0.4) {
        t = (uScrollProgress / 0.4) * 2.0;
    } else if (uScrollProgress <= 0.6) {
        t = 2.0; // The "Wait/Snap" state
    } else {
        t = 2.0 + ((uScrollProgress - 0.6) / 0.4) * 5.0;
    }
    float td = max(t - 1.5, 0.0);

    // Global visibility fades: In at start, Out at end
    float globalFade = smoothstep(0.0, 0.15, uScrollProgress) * (1.0 - smoothstep(0.9, 1.0, uScrollProgress));

    // --- STARFIELD GENERATION ---
    for (int i = 0; i < NUM_STARS; i++) {
        float fi = float(i);
        float x = rand(fi * 12.34) * 2. - 1.0;
        float y = rand(fi * 23.45) * 2. - 1.0;
        vec2 c = vec2(x, y);
        
        // Minimum stroke width: reduced radius and sharper falloff
        float r = rand(fi * 45.67) * 0.0005; 
        
        vec2 n = c * (exp(t * 1.3) - 1.0) * 0.0015; 
        float d = (getDistanceSP(c, c + n, uv) - r);
        
        // Sharper falloff (-1500.0) makes the stars look like thin needles
        float intensity = exp(-1500.0 * d);
        
        starCol += GOLD * intensity;
        starAlpha += intensity;
        
        // Central glow in GOLD
        float centerGlow = (exp(t * 0.00005) - 1.0) + (exp(td * td * 0.008) - 1.0) * (0.015 / length(uv));
        starCol += GOLD * centerGlow * 0.005;
        starAlpha += centerGlow * 0.05;
    }

    // --- TEXT INTEGRATION ---
    float xOffset = 0.0;
    float textOpacity = 0.0;
    float shine = 0.0;

    if (uScrollProgress < 0.4) {
        xOffset = mix(-0.4, 0.0, smoothstep(0.1, 0.4, uScrollProgress));
        textOpacity = smoothstep(0.1, 0.4, uScrollProgress);
    } else if (uScrollProgress <= 0.6) {
        xOffset = 0.0; // Perfect Center Snap
        textOpacity = 1.0;
        float shineP = (uScrollProgress - 0.4) / 0.2;
        shine = smoothstep(0.2, 0.0, abs((fragCoord.x / uSize.x) - mix(-0.2, 1.2, shineP)));
    } else {
        xOffset = mix(0.0, 0.5, smoothstep(0.6, 0.9, uScrollProgress));
        textOpacity = 1.0 - smoothstep(0.7, 1.0, uScrollProgress);
    }

    vec2 textPos = (uSize - uTextSize) * 0.5;
    vec2 textLocalUv = (fragCoord - textPos) / uTextSize;
    textLocalUv.x -= xOffset;

    vec4 textCol = vec4(0.0);
    if (textLocalUv.x >= 0.0 && textLocalUv.x <= 1.0 && textLocalUv.y >= 0.0 && textLocalUv.y <= 1.0) {
        textCol = texture(uTexture, textLocalUv);
        // Gold shine on text
        textCol.rgb += shine * GOLD * 0.8 * textCol.a;
        textCol *= textOpacity;
    }

    // --- COMPOSITING ---
    vec3 finalRGB = mix(starCol * globalFade, textCol.rgb, textCol.a);
    float finalAlpha = clamp((starAlpha * globalFade) + textCol.a, 0.0, 1.0);

    // Final Jump "Flash" - briefly goes to white then fades to 0
    if (uScrollProgress > 0.85) {
        float flash = smoothstep(0.85, 0.92, uScrollProgress) * (1.0 - smoothstep(0.92, 1.0, uScrollProgress));
        finalRGB = mix(finalRGB, vec3(1.0), flash);
        finalAlpha = mix(finalAlpha, 1.0, flash);
    }

    fragColor = vec4(finalRGB, finalAlpha);
}