#version 460 core

// Uniforms
uniform vec2 uFlutterCanvasSize;
uniform sampler2D uShadowTexture; // This sampler now benefits from Linear Filtering
uniform vec2 uLightPosition;
uniform vec2 uObjectPosition;
uniform vec2 uObjectSize;

out vec4 fragColor;

// --- FINAL PARAMETERS FOR THE ACHIEVED THEME AND STYLE ---
const int SAMPLES = 200;              // Sufficient samples for smooth long shadow
const float STEP_SIZE = 0.005;       // Small steps for volumetric look
const float OPACITY = 0.2;          // CHANGED: Slightly increased overall shadow opacity for a bit more presence, still subtle.
// CHANGED: Shadow color to a very dark, desaturated blue-grey/purple-grey.
const vec3 shadowColor = vec3(0.22, 0.24, 0.33); // Much more subtle than previous 0.2,0.2,0.2

// Parameters for the centered "aura" effect
const int AURA_SAMPLES = 100;         // Increased samples for smoother aura
const float AURA_RADIUS = 0.07;      // CHANGED: Increased radius for a wider, more diffused central blur (in UV space)

void main() {
    // Invert the Y-axis for Flame's coordinate system.
    vec2 fragCoord = vec2(gl_FragCoord.x, uFlutterCanvasSize.y - gl_FragCoord.y);

    // Calculate light's offset and distance from the object's center.
    vec2 lightOffset = uObjectPosition - uLightPosition;
    float lightDistance = length(lightOffset);

    // Calculate the starting UV coordinate for the current pixel.
    vec2 startUV = (fragCoord - (uObjectPosition - uObjectSize / 2.0)) / uObjectSize;

    // --- 1. CALCULATE THE DIRECTIONAL LONG SHADOW ---
    vec2 shadowDirection = normalize(lightOffset);
    vec2 uvStep = shadowDirection / uObjectSize;
    float directionalTotalAlpha = 0.0;
    for (int i = 0; i < SAMPLES; i++) {
        // CHANGED: Increased the divisor for dynamicStepScale to make the shadow length less extreme when light is far.
        // This makes the 'jerk' effect more gentle and in line with the subtle theme.
        float dynamicStepScale = lightDistance / 1000.0; // Adjusted from 800.0
        vec2 sampleUV = startUV - uvStep * float(i) * STEP_SIZE * length(uObjectSize) * dynamicStepScale;
        if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
            directionalTotalAlpha += texture(uShadowTexture, vec2(sampleUV.x, 1.0 - sampleUV.y)).a;
        }
    }
    float normalizedDirectionalAlpha = directionalTotalAlpha / float(SAMPLES);

    // --- 2. CALCULATE THE CENTERED "AURA" SHADOW ---
    float auraTotalAlpha = 0.0;
    for (int i = 0; i < AURA_SAMPLES; i++) {
        float angle = float(i) / float(AURA_SAMPLES) * 6.28318; // 2 * PI
        vec2 offset = vec2(cos(angle), sin(angle)) * AURA_RADIUS;
        vec2 sampleUV = startUV + offset;
        if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
            auraTotalAlpha += texture(uShadowTexture, vec2(sampleUV.x, 1.0 - sampleUV.y)).a;
        }
    }
    float normalizedAuraAlpha = auraTotalAlpha / float(AURA_SAMPLES);

    // --- 3. BLEND THE TWO SHADOWS BASED ON DISTANCE ---
    // The transition distance remains the same, providing a smooth blend.
    float auraMixFactor = 1.0 - smoothstep(0.0, 200.0, lightDistance);

    float mixedAlpha = mix(normalizedDirectionalAlpha, normalizedAuraAlpha, auraMixFactor);

    // --- 4. APPLY FINAL SMOOTHING AND OUTPUT ---
    // CHANGED: Adjusted smoothstep to make the shadow's onset even softer.
    float smoothAlpha = smoothstep(0.0, 0.5, mixedAlpha); // Adjusted from 0.4
    float finalAlpha = smoothAlpha * OPACITY;
    fragColor = vec4(shadowColor, finalAlpha);
}