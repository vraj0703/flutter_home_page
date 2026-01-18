import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

/// Large impactful "WORK EXPERIENCE" title that scrolls up from bottom,
/// holds at center with subtle animation, then exits to top.
class WorkExperienceTitleComponent extends TextComponent
    with HasPaint, HasGameReference<MyGame> {
  final FragmentShader shader;
  final Color baseColor;
  double _time = 0.0;

  WorkExperienceTitleComponent({
    required String text,
    required TextStyle textStyle,
    required this.shader,
    this.baseColor = const Color(0xFFE3E4E5),
    super.position,
    super.anchor = Anchor.center,
    super.priority,
  }) : super(
          text: text,
          textRenderer: TextPaint(
            style: textStyle.copyWith(
              foreground: Paint()..shader = shader,
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    // Use god ray position for dynamic metallic lighting
    final dpr = game.canvasSize.x / game.size.x;
    final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
    final physicalSize = size * dpr;
    final physicalLightPos = game.godRay.position * dpr;

    // Metallic Shader Uniforms (matches hero title and bold text)
    // 0: uSize.x, 1: uSize.y
    // 2: uOffset.x, 3: uOffset.y
    // 4: uTime
    // 5,6,7: uBaseColor RGB (normalized)
    // 8: uOpacity
    // 9,10: uLightPos (god ray position)

    shader
      ..setFloat(0, physicalSize.x)
      ..setFloat(1, physicalSize.y)
      ..setFloat(2, physicalTopLeft.x)
      ..setFloat(3, physicalTopLeft.y)
      ..setFloat(4, _time)
      ..setFloat(5, baseColor.r / 255)
      ..setFloat(6, baseColor.g / 255)
      ..setFloat(7, baseColor.b / 255)
      ..setFloat(8, opacity)
      ..setFloat(9, physicalLightPos.x)
      ..setFloat(10, physicalLightPos.y);

    super.render(canvas);
  }

  /// Applies subtle scale pulse during hold phase
  /// Called by controller during hold phase
  void applyPulse(double pulseProgress) {
    // Subtle sine wave: 1.0 → 1.02 → 1.0
    final pulse = 1.0 + (0.02 * math.sin(pulseProgress * math.pi * 2));
    scale = Vector2.all(pulse);
  }
}
