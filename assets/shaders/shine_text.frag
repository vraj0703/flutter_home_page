#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uOffset;
uniform float uTime;
uniform vec3 uBaseColor;
uniform float uOpacity;
uniform vec2 uLightPos;

out vec4 fragColor;

vec4 tanh_polyline(vec4 x) {
    vec4 val = clamp(x, -20.0, 20.0);
    vec4 ex = exp(val);
    vec4 emx = exp(-val);
    return (ex - emx) / (ex + emx);
}

void main() {
    // 1. Coordinates
    vec2 fragCoord = FlutterFragCoord().xy; // Screen Pixels
    vec2 localCoord = fragCoord - uOffset;
    vec2 uv = localCoord / uSize;
    
    // FIX: Restore Clamp to avoid edge artifacts
    uv = clamp(uv, 0.0, 1.0);

    // 2. CHROME HORIZON SHADING
    // Metal looks like metal because of high contrast reflections.
    // We create a "Fake Horizon" at Y=0.5.
    
    float horizon = 0.0;
    
    // Smooth Horizon transition
    // Top Half (Sky): Gradients from Dark (Horiz) to Light (Top)
    // Bottom Half (Ground): Gradients from Dark (Horiz) to Lighter (Bot)
    
    float y = uv.y;
    
    // Hard Cut Horizon for Chrome look
    if (y < 0.5) {
       // TOP HALF (0.0 to 0.5)
       // 0.0 (Top Edge) -> Bright (0.8)
       // 0.5 (Horizon) -> Dark (0.2)
       horizon = mix(0.8, 0.2, smoothstep(0.0, 0.5, y));
    } else {
       // BOTTOM HALF (0.5 to 1.0)
       // 0.5 (Horizon) -> Pitch Black (0.0)
       // 1.0 (Bot Edge) -> Grey (0.5)
       // This hard black edge at 0.5 creates the "Chrome" feel
       horizon = mix(0.0, 0.5, smoothstep(0.5, 1.0, y));
    }

    vec3 baseColor = uBaseColor * horizon;

    // 3. DYNAMIC LIGHTING - LOCAL SPACE
    // Calculate distance to light position (Local Coords)
    float dx = abs(localCoord.x - uLightPos.x); 
    float dy = abs(localCoord.y - uLightPos.y);

    // Weighted distance (Tall Light Beam)
    float dist = sqrt(dx*dx + (dy*dy * 0.1)); // 0.1 = Even Taller Beam (Vertical Bar)

    // Light Radius
    // Increased to 1200.0 for much wider gradient falloff
    float lightRadius = 1200.0;
    float glow = smoothstep(lightRadius, 0.0, dist);

    // SHINE LOGIC:
    // BROADER BEAM:
    // Decreased Power from 20.0 to 6.0 = Much wider peak
    // Adjusted multiplier to keep it bright but not blown out
    float glint = pow(glow, 6.0) * 12.0; 

    // Ambient Glow
    // Reduced to 0.1 to allow the deep blacks to show through (Contrast)
    float ambientGlow = 0.1; 

    // Pure White Light for Silver Effect
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    
    // Composite
    vec3 color = baseColor + (lightColor * (ambientGlow + glint));

    // 4. Tone Mapping
    vec4 finalResult = tanh_polyline(vec4(color, 1.0));
    fragColor = vec4(finalResult.rgb * uOpacity, uOpacity);
}
