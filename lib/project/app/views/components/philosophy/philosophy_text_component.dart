import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class PhilosophyTextComponent extends PositionComponent with HasPaint {
  final String text;
  final material.TextStyle style;
  final FragmentShader shader;
  late final FadeTextComponent _fadeText;

  /// Enable reflection rendering
  bool showReflection = false;

  /// Water line Y position for reflection (relative to parent)
  double waterLineY = 0.0;

  /// Reflection opacity multiplier
  double reflectionOpacity = 0.3;

  PhilosophyTextComponent({
    required this.text,
    required this.style,
    required this.shader,
    super.position,
    super.anchor,
  });

  @override
  Future<void> onLoad() async {
    _fadeText = FadeTextComponent(
      text: text,
      textStyle: style,
      shader: shader,
      baseColor: GameStyles.boldTextBase,
    );
    _fadeText.anchor = Anchor.center; // Changed from centerLeft to center
    _fadeText.opacity = 0.0; // Explicitly hide child on load
    add(_fadeText);
    opacity = 0.0; // Start Hidden
  }

  @override
  double get opacity => _fadeText.opacity;

  @override
  set opacity(double value) {
    if (value == super.opacity) return;
    if (isLoaded) {
      _fadeText.opacity = value;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render reflection if enabled
    if (showReflection && opacity > 0) {
      _renderReflection(canvas);
    }
  }

  void _renderReflection(Canvas canvas) {
    // Calculate reflection position - directly below the text
    final distanceFromWater = waterLineY - position.y;
    final reflectionY = waterLineY + distanceFromWater; // Direct mirror
    final reflectionOffset = reflectionY - position.y;

    canvas.save();

    // Translate to reflection position
    canvas.translate(0, reflectionOffset);

    // Flip vertically and scale down slightly
    canvas.scale(1.0, -0.7);

    // Apply reduced opacity for reflection
    final reflectionPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        Color.fromRGBO(255, 255, 255, opacity * reflectionOpacity),
        BlendMode.modulate,
      );

    canvas.saveLayer(null, reflectionPaint);
    _fadeText.render(canvas);
    canvas.restore();

    canvas.restore();
  }
}
