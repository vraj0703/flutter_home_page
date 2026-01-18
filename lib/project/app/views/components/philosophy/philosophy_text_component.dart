import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class PhilosophyTextComponent extends PositionComponent with HasPaint {
  final String text;
  final material.TextStyle style;
  final FragmentShader shader;
  late final FadeTextComponent _fadeText;

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
      baseColor: const Color(0xFFE3E4E5),
    );
    _fadeText.anchor = Anchor.centerLeft;
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
}
