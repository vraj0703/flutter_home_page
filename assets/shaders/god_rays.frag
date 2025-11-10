#version 460 core

// Uniforms from Flame
uniform vec2 uFlutterCanvasSize;

// Custom uniforms for our shadow
uniform sampler2D uShadowTexture;
uniform vec2 uLightPosition;
uniform vec2 uObjectPosition;
uniform vec2 uObjectSize;

out vec4 fragColor;

// --- TWEAKABLE PARAMETERS ---

// == Banded Long Shadow Parameters ==
// CHANGED: Drastically reduced samples to create visible banding instead of a smooth gradient.
const int SAMPLES = 120;
// CHANGED: Increased step size to make each band in the shadow distinct.
const float STEP_SIZE = 0.01;
// Decay remains to create the fade-out effect over the shadow's length.
const float DECAY = 0.98;
// CHANGED: Reduced opacity to match the faint, subtle shadow in the target video.
const float OPACITY = 0.25;

// CHANGED: Shadow color is now a lighter grey to be more subtle.
const vec3 shadowColor = vec3(0.1, 0.1, 0.1);

void main() {
    // The Y coordinate was previously 'uFlutterCanvasSize.y - uFlutterCanvasSize.y', which is always 0.
    // This is the correct line to invert the Y-axis for Flame's coordinate system.
    vec2 fragCoord = vec2(gl_FragCoord.x, uFlutterCanvasSize.y - gl_FragCoord.y);

    // 1. Calculate the UN-NORMALIZED vector. Its length is the light's distance.
    vec2 lightOffset = uObjectPosition - uLightPosition;

    // 2. Get the pure direction of the shadow.
    vec2 shadowDirection = normalize(lightOffset);

    // 3. Convert the direction to the texture's UV-space.
    vec2 uvStep = shadowDirection / uObjectSize;

    // 4. Calculate the starting UV coordinate for the current pixel.
    vec2 startUV = (fragCoord - (uObjectPosition - uObjectSize / 2.0)) / uObjectSize;

    // --- Render the Banded Long Shadow ---
    float totalAlpha = 0.0;
    float currentDecay = 1.0;

    for (int i = 0; i < SAMPLES; i++) {
        // 5. Scale the shadow's length by the light's distance.
        // This creates the dynamic "jerk" effect.
        float dynamicStepScale = length(lightOffset) / 800.0;
        vec2 sampleUV = startUV - uvStep * float(i) * STEP_SIZE * length(uObjectSize) * dynamicStepScale;

        if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
            float sampleAlpha = texture(uShadowTexture, vec2(sampleUV.x, 1.0 - sampleUV.y)).a;
            totalAlpha += sampleAlpha * currentDecay;
        }
        currentDecay *= DECAY;
    }

    // --- Combine and Output ---
    float finalAlpha = clamp(totalAlpha * OPACITY, 0.0, 1.0);
    fragColor = vec4(shadowColor, finalAlpha);
}