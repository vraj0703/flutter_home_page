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

    // 2. Base Metallic Shading (Cylindrical)
    // Darker edges to give 3D volume
    float edgeShadow = max(0.5, 1.0 - pow(abs(uv.y - 0.5) * 2.0, 3.0));
    vec3 baseColor = uBaseColor * edgeShadow;

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
    // Enough to see the metal texture
    float ambientGlow = 0.25; 

    // Pure White Light for Silver Effect
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    
    // Composite
    vec3 color = baseColor + (lightColor * (ambientGlow + glint));

    // 4. Tone Mapping
    vec4 finalResult = tanh_polyline(vec4(color, 1.0));
    fragColor = vec4(finalResult.rgb * uOpacity, uOpacity);
}
