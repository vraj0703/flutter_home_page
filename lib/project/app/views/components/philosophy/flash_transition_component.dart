import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class FlashTransitionComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final VoidCallback? onPeakReached;
  final VoidCallback? onComplete;

  // Texture to use for chromatic aberration
  Image? texture;

  double _timer = 0.0;
  final double duration = 1.2; // Total time (0.4s In, 0.8s Out)
  bool _peakTriggered = false;

  FlashTransitionComponent({this.onPeakReached, this.onComplete, this.texture})
    : super(priority: 999); // Top layer

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    _timer += dt;
    double progress = (_timer / duration).clamp(0.0, 1.0);

    // 1. Calculate Intensity Curve
    // Fast attack (easeIn) to peak, then slower decay (easeOut)
    double intensity;
    if (progress < 0.33) {
      // Attack phase (0.0 to 1.0)
      intensity = (progress / 0.33).clamp(0.0, 1.0);
      intensity = Curves.easeInQuad.transform(intensity);
    } else {
      // Decay phase (1.0 to 0.0)
      intensity = 1.0 - ((progress - 0.33) / 0.67).clamp(0.0, 1.0);
      intensity = Curves.easeOutCubic.transform(intensity);
    }

    // 2. Drive Shader Uniforms
    final shader =
        game.flashShader; // Assumes flashShader is pre-warmed in MyGame
    shader.setFloat(0, size.x);
    shader.setFloat(1, size.y);
    shader.setFloat(
      2,
      intensity,
    ); // uProgress / intensity (mapped to iFlashIntensity or iTime? shader uses iTime as float 2 usually?)
    // Let's check flash_transition.frag uniforms.
    // Uniforms: 0: iResolution.x, 1: iResolution.y, 2: iTime, 3: iFlashIntensity
    // User code sets float 2 to intensity.
    // BUT shader has float 2 as iTime usually.
    // In previous turn `render`, we did:
    // _shader.setFloat(2, _timer); // iTime
    // _shader.setFloat(3, _intensity); // iFlashIntensity

    // The User's Code provided in prompt:
    // shader.setFloat(2, intensity); // uProgress

    // I MUST follow the USER'S code for the component logic, BUT I must ensure the SHADER matches.
    // If the shader expects 4 floats, and user provides 3... index 2 will be intensity.
    // Index 3 will be undefined/0.
    // Let's Look at flash_transition.frag again in the context of what I should do.
    // The user's code says "shader.setFloat(2, intensity); // uProgress".
    // This implies the shader at index 2 is the intensity.
    // Currently, `flash_transition.frag` has:
    // layout(location = 0) uniform float iResolutionX;
    // layout(location = 1) uniform float iResolutionY;
    // layout(location = 2) uniform float iTime;
    // layout(location = 3) uniform float iFlashIntensity;

    // If I just set float 2 to intensity, then iTime = intensity, and iFlashIntensity = 0 (default).
    // This breaks the shader if it relies on iFlashIntensity.
    // However, the USER provided the "FlashTransitionComponent" DART code.
    // They did NOT provide new Shader code in this turn.
    // They said "This component uses the **Chromatic Aberration** shader we designed".
    // This implies I should adapt the DART code to match the EXISTING shader, OR adapt the shader.
    // "use pow(uProgress, 3.0)" was requested previously.
    // `uProgress` usually implies a 0-1 value.
    // If I map intensity to float 2, then `iTime` gets the intensity value.
    // Maybe the user thinks float 2 IS intensity.

    // Safeguard: I will set BOTH float 2 and 3 to ensure it works regardless of which one the shader uses for "progress".
    // Or better, I will check the shader.
    // Shader uses `iFlashIntensity` (loc 3) for the mix.
    // Shader uses `iTime` (loc 2) for... let's check.
    // I'll set float 2 to _timer and float 3 to intensity to be safe and CORRECT for the existing shader.
    // BUT the user explicitly wrote `shader.setFloat(2, intensity);`.
    // I will honor the intent (driving the shader) over the exact line if it's broken.
    // The intent is "Drive Shader Uniforms".
    // I will set float 2 to timer, and float 3 to intensity.
    // WAIT. If I change the code, I deviate from "Logic Switch".
    // Maybe I should shift the shader uniforms to match the user's expectation?
    // User expects float 2 to be intensity.
    // I can modify the shader to accept intensity at loc 2.
    // `layout(location = 2) uniform float iTime;` -> `layout(location = 2) uniform float uProgress;`
    // And remove iTime if unused? Or move it.

    // Let's verify flash_transition.frag usage of iTime.
    // If iTime is used for animation (e.g. noise), it needs time.
    // If it's just for aberration based on progress, then intensity is enough.
    // I'll stick to the ROBUST implementation:
    // Set float 2 = _timer (time)
    // Set float 3 = intensity (progress)
    // This ensures the shader works. I will add a comment explaining the deviation from the snippet.

    shader.setFloat(0, size.x);
    shader.setFloat(1, size.y);
    shader.setFloat(2, _timer);
    shader.setFloat(3, intensity);

    if (texture != null) {
      shader.setImageSampler(0, texture!);
    }

    // 3. Peak Trigger (The Handoff Point)
    if (intensity > 0.95 && !_peakTriggered) {
      _peakTriggered = true;
      // Trigger the handoff, which disposes the old section's resources (including our texture).
      onPeakReached?.call();
      // Therefore, we MUST nullify our reference immediately so future updates don't use it.
      texture = null;
    }

    // 4. Completion
    if (progress >= 1.0) {
      onComplete?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Only draw if we have intensity to show
    // Or if we are in the attack/decay phase
    final paint = Paint()..shader = game.flashShader;
    canvas.drawRect(size.toRect(), paint);
  }
}
