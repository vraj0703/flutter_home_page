import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

class FlashTransitionComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final VoidCallback? onPeakReached;
  final VoidCallback? onComplete;

  // Texture to use for chromatic aberration
  final Image? texture;

  double _timer = 0.0;
  final double duration =
      ScrollSequenceConfig.philosophyTransition.flashTotalDuration;
  bool _peakTriggered = false;

  FlashTransitionComponent({
    this.onPeakReached,
    this.onComplete,
    Image? texture,
  }) : texture = texture?.clone(),
       super(priority: 999); // Top layer

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
    final shader = game.flashShader;
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
      // Trigger the handoff (disposes original texture, but we have a clone)
      onPeakReached?.call();
    }

    // 4. Completion
    if (progress >= 1.0) {
      onComplete?.call();
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    texture?.dispose(); // Release our texture handle
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    // Only draw if we have intensity to show
    // Or if we are in the attack/decay phase
    final paint = Paint()..shader = game.flashShader;
    canvas.drawRect(size.toRect(), paint);
  }
}
