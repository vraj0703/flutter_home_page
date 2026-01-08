import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Curves;
import 'package:flutter_home_page/project/app/utils/wait_effect.dart';

import 'fade_text.dart';

class CinematicSecondaryTitleComponent extends PositionComponent
    with HasGameReference {
  final String text;
  final FragmentShader shader;

  late FadeTextComponent _textComponent;

  CinematicSecondaryTitleComponent({
    required this.text,
    required this.shader,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    const style = TextStyle(
      fontSize: 14, // Smaller scale
      fontWeight: FontWeight.w400,
      letterSpacing: 4, // High spacing
      color: Colors.white,
    );

    _textComponent =
        FadeTextComponent(
            text: text,
            textStyle: style,
            shader: shader,
            baseColor: const Color(0xFFAAB0B5), // Muted Silver/Grey
            anchor: Anchor.center,
            priority: 1,
          )
          ..opacity = 0
          ..scale = Vector2.zero();

    add(_textComponent);
  }

  void show(VoidCallback showComplete) {
    if (_textComponent.opacity > 0) return;

    // Animate Opacity
    _textComponent.add(
      SequenceEffect([
        OpacityEffect.to(
          1.0,
          EffectController(duration: 4, curve: Curves.easeOut),
        ),
      ]),
    );

    // Animate Scale
    _textComponent.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 4, curve: Curves.fastLinearToSlowEaseIn),
          onComplete: showComplete,
        ),
      ]),
    );
  }

  void hide() {
    _textComponent.add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.5, curve: Curves.easeOut),
      ),
    );
  }
}
