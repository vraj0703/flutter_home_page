import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/widgets/components/fade_text.dart';

class PhilosophyTextComponent extends PositionComponent {
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
    add(_fadeText);
  }

  double get opacity => _fadeText.opacity;

  set opacity(double value) {
    if (isLoaded) {
      _fadeText.opacity = value;
    }
  }
}
