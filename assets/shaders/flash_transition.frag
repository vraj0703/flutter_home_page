#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform float iFlashIntensity; // 0.0 = no flash, 1.0 = full white
uniform sampler2D iChannel0; // Scene beneath

out vec4 fragColor;

void main() {
    vec2 c = FlutterFragCoord().xy;
    vec2 uv = vec2(c.x, iResolution.y - c.y) / iResolution.xy;
    
    // Center distance for chromatic aberration
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    
    // Chromatic aberration strength based on flash intensity and distance from center
    float aberration = iFlashIntensity * dist * 0.015;
    
    // Sample RGB channels with offset for chromatic effect
    vec2 uvR = uv + (uv - center) * aberration * 1.0;
    vec2 uvG = uv + (uv - center) * aberration * 0.5;
    vec2 uvB = uv + (uv - center) * aberration * 0.0;
    
    float r = texture(iChannel0, vec2(uvR.x, 1.0 - uvR.y)).r;
    float g = texture(iChannel0, vec2(uvG.x, 1.0 - uvG.y)).g;
    float b = texture(iChannel0, vec2(uvB.x, 1.0 - uvB.y)).b;
    
    vec3 sceneColor = vec3(r, g, b);
    
    // Pure white flash color
    vec3 flashColor = vec3(1.0);
    
    // Mix scene with flash based on intensity
    vec3 finalColor = mix(sceneColor, flashColor, iFlashIntensity);
    
    // Vignette effect during flash (darker edges)
    float vignette = 1.0 - (dist * iFlashIntensity * 0.3);
    finalColor *= vignette;
    
    fragColor = vec4(finalColor, 1.0);
}
