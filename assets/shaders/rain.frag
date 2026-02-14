#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform float iIntensity;
uniform vec2 iMouse;
uniform float iOpacity; // Added to match Dart's setFloat(6, opacity)
uniform float iLightning; // Now at index 7, matching Dart
uniform sampler2D iChannel0; // Background
uniform sampler2D iChannel1; // Noise
uniform float iCrackStrength; // 8
uniform float iShatterProgress; // 9
uniform float uWaterY; // 10 - Horizon line for lightning
uniform float iStrikeSeed; // 11 - Randomize bolts
uniform float uPixelRatio; // 12 - DPR

out vec4 fragColor;

// --- NOISE FUNCTIONS ---
// High-quality hash for droplet variety
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec2 random2(vec2 st) {
    st = vec2(dot(st, vec2(127.1, 311.7)),
              dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123 * 0.7897);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(dot(random2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                   dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// --- HDR & REFLECTION HELPERS ---
// Reinhard tone mapping for HDR soft-clamp
vec3 reinhard(vec3 color) {
    return color / (1.0 + color);
}

// Calculate shard normal from fractional position within Voronoi cell
vec3 calculateShardNormal(vec2 fpos, float progress) {
    // Center of shard looks flat, edges look chamfered/curved
    // Z component decreases with progress to simulate forward tilt
    return normalize(vec3(fpos - 0.5, 1.0 - progress * 0.5));
}

// --- SHATTER LOGIC ---
// Enhanced ShatterUV returns fractional position for normal calculation
vec2 ShatterUV(vec2 uv, float progress, out vec2 fpos) {
    fpos = vec2(0.5); // Default center if no shatter
    if (progress <= 0.0) return uv;
    
    float cells = 6.0;
    vec2 gv = uv * cells;
    vec2 id = floor(gv);
    fpos = fract(gv); // Store fractional position for normal calc
    vec3 h = hash32(id); 
    vec2 center = id / cells + 0.5/cells;
    vec2 dir = normalize(center - 0.5);
    
    // 3D Perspective: Scale factor increases to simulate flying towards camera
    float z = 1.0 / (1.0 - progress * 0.95);
    
    vec2 offset = dir * progress * h.x * 2.0;
    
    // Apply 3D scaling (zoom) and offset
    vec2 transformedUV = (uv - center - offset) * z + center; 
    
    float angle = progress * h.z * 5.0;
    float s = sin(angle), c = cos(angle);
    transformedUV = mat2(c, -s, s, c) * (transformedUV - center) + center;
    
    return transformedUV;
}

// --- LIGHTNING LOGIC ---
// Adapted from user provided script for 'electric' feel
vec3 ProceduralLightning(vec2 uv, float strikeIntensity) {
    if (strikeIntensity <= 0.01) return vec3(0.0);

    // Map min/max dimensions
    // We want bolts to generally go top-down
    vec2 p = uv * 2.0 - 1.0;
    
    // Animate the noise with time so the bolt jitters
    float tOffset = iTime * 10.0; 
    
    // Randomize the horizontal position and path shape
    p.x += iStrikeSeed;

    // Domain distortion for the path
    // We disturb the X coordinate based on Y and FBM to make it jagged
    float pathWiggle = fbm(vec2(p.y * 1.5 + iStrikeSeed, tOffset)) * 1.5;
    
    // Distance field to the bolt center
    float d = abs(p.x - pathWiggle * 0.5 - iStrikeSeed); // Re-center somewhat
    // To properly center it, we should just use the wiggle. 
    // Let's refine:
    
    // Reset p.x for the distance calc relative to the wiggle
    // The previous p.x += seed was to move the domain. 
    // Let's rely on the seed inside the FBM to change shape, 
    // and use a separate offset to move the bolt.
    
    // Re-eval:
    vec2 p2 = uv * 2.0 - 1.0;
    
    // X-position offset (randomized)
    // Map seed 0..100 to -0.8..0.8 range
    float xOffset = sin(iStrikeSeed) * 0.8; 
    p2.x -= xOffset;
    
    // Path shape randomization (using seed in FBM)
    float shapeSeed = iStrikeSeed * 1.1;
    float wiggle = fbm(vec2(p2.y * 1.2, tOffset + shapeSeed)) * 1.0;
    
    float dist = abs(p2.x - wiggle * 0.4);
    
    // Glow calculation from user script: abs(0.1 / (radius - 0.25))
    // Remapped for our distance field:
    // We want a very sharp core (dist near 0) and soft falloff
    float glow = 0.02 / (dist + 0.01); 
    
    // Mask edges (fade out at sides)
    glow *= smoothstep(1.0, 0.0, abs(p2.x));
    
    // Vertical fade (Fade out at top/bottom edges)
    // AND fade out at horizon (uWaterY).
    // uWaterY is 0..1 (UV space).
    // We want lightning only ABOVE uWaterY.
    // 0.05 feathering to avoid hard cut
    float horizonMask = smoothstep(uWaterY, uWaterY + 0.1, uv.y);
    // Also fade at very top to avoid clipping
    float topMask = smoothstep(1.0, 0.9, uv.y);
    
    glow *= horizonMask; // * topMask; (Optional, maybe let it go off top)

    // Color Logic
    vec3 boltColor = vec3(0.7, 0.8, 1.0);
    return boltColor * glow * strikeIntensity;
}

void main() {
    vec2 c = FlutterFragCoord().xy / uPixelRatio;
    vec2 u = vec2(c.x, iResolution.y - c.y) / iResolution.xy;

    // 1. SHATTER: Distort UVs and capture fractional position for normals
    vec2 fpos; // Fractional position within shard
    vec2 shatteredUV = ShatterUV(u, iShatterProgress, fpos);
    
    // 2. Alpha Clipping for Shards
    float shardMask = 1.0;
    if (iShatterProgress > 0.0) {
        // Clip shards that fly out of bounds
        if (shatteredUV.x < -0.05 || shatteredUV.x > 1.05 || shatteredUV.y < -0.05 || shatteredUV.y > 1.05) {
           shardMask = 0.0;
        }
    }

    // 3. RAIN & MOUSE INTERACTION
    float distToMouse = distance(c, iMouse);
    float wipe = smoothstep(80.0, 220.0, distToMouse);

    vec2 refractionOffset = vec2(0.0);
    float dropMask = 0.0;
    float specular = 0.0;
    vec3 dropGlint = vec3(0.0);

    // Rain Loop
    for (float i = 1.0; i <= 3.0; i++) {
        vec2 grid = vec2(10.0, 5.0) * i;
        vec2 uv = shatteredUV * grid;
        uv.y += iTime * (0.15 * i);

        vec2 ipos = floor(uv);
        vec2 fpos = fract(uv);
        vec3 h = hash32(ipos);

        if (h.x < iIntensity * 0.4) {
            vec2 p = vec2(0.5) + (h.yz - 0.5) * 0.6;
            float d = distance(fpos, p);
            // Drop shape mask
            float mask = smoothstep(0.35, 0.05, d) * wipe;

            vec2 normal = (fpos - p) * 2.0;
            refractionOffset += normal * mask * 0.06;
            
            // Refined Lighting for drops
            vec3 lightDir = normalize(vec3(-0.5, 0.5, 1.0));
            // Specular boost when lightning strikes
            float specPower = mix(32.0, 64.0, iLightning); 
            float spec = pow(max(0.0, dot(normalize(vec3(normal, 1.0)), lightDir)), specPower);
            
            float rim = pow(1.0 - max(0.0, dot(vec3(normal, 1.0), vec3(0,0,1))), 3.0);
            
            specular = max(specular, (spec + rim * iLightning * 0.8) * mask);
            
            vec3 lightningTint = vec3(0.7, 0.8, 1.0);
            dropGlint += mix(vec3(1.0), lightningTint, iLightning) * specular;
        }
    }

    // 4. LIGHTNING (Backlight - Behind Shards)
    // Use screen UV 'u' so lightning stays continuously in the background
    vec3 backgroundLightning = ProceduralLightning(u, iLightning);
    
    // 5. SCENE (Shards)
    vec2 refractedUv = shatteredUV - refractionOffset;
    vec4 scene = texture(iChannel0, vec2(refractedUv.x, 1.0 - refractedUv.y));

    // 6. PHYSICALLY-BASED SHARD REFLECTIONS (HDR)
    // Calculate procedural normal from shard fractional position
    vec3 shardNormal = calculateShardNormal(fpos, iShatterProgress);
    
    // View direction (camera looking forward into screen)
    vec3 viewDir = vec3(0.0, 0.0, -1.0);
    
    // Light position synced with horizon lightning
    // Matches the procedural lightning position for coherent lighting
    vec3 lightPos = normalize(vec3(sin(iStrikeSeed) * 0.8, uWaterY, 2.0));
    
    // Reflection vector for view-dependent shimmer
    vec3 reflectDir = reflect(-viewDir, shardNormal);
    
    // Specular reflection (Phong model with high exponent for sharp highlight)
    float specReflection = pow(max(0.0, dot(reflectDir, lightPos)), 32.0);
    
    // Rim light for backside illumination (gives depth to shards)
    float rimReflection = pow(1.0 - abs(dot(shardNormal, viewDir)), 2.0);
    
    // Combine specular and rim, weighted toward specular
    float reflectionStrength = mix(rimReflection * 0.3, specReflection, 0.7);
    
    // Lightning color (blue-white) with HDR intensity
    vec3 shardReflection = vec3(0.7, 0.8, 1.0) * reflectionStrength * iLightning * 2.5;
    
    // HDR tone mapping to prevent blowout while keeping intensity
    shardReflection = reinhard(shardReflection);

    // 7. COMPOSITION
    vec3 finalRgb;
    
    if (shardMask < 0.5) {
        // Void/Gap: Fade from background lightning to clear/next level color
        vec3 clearColor = vec3(0.05, 0.05, 0.1); // Dark blue
        vec3 gapBackground = backgroundLightning * 0.8;
        finalRgb = mix(gapBackground, clearColor, iShatterProgress);
    } else {
        // Glass Shard: Scene Image + Shard Reflection + Rain Glints
        // Mix lightning slightly into the shard to make it look translucent
        vec3 translucentLightning = ProceduralLightning(shatteredUV, iLightning) * 0.3;
        
        finalRgb = scene.rgb + translucentLightning + shardReflection + dropGlint;
    }
    
    // Shatter fade (entire thing fades out eventually)
    float shatterFade = 1.0 - smoothstep(0.8, 1.0, iShatterProgress);

    // Apply global opacity
    fragColor = vec4(finalRgb * iOpacity * shatterFade, iOpacity * shatterFade);
}
