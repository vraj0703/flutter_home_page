import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, TextStyle, FontWeight;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/utils/wait_effect.dart';
import '../fade_text.dart';

class CinematicSecondaryTitleComponent extends PositionComponent
    with HasGameReference
    implements OpacityProvider {
  final String text;
  final FragmentShader shader;

  late FadeTextComponent _textComponent;

  @override
  double get opacity => _textComponent.opacity;

  @override
  set opacity(double value) {
    _textComponent.opacity = value;
  }

  CinematicSecondaryTitleComponent({
    required this.text,
    required this.shader,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    const style = TextStyle(
      fontSize: GameStyles.secondaryTitleFontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: GameStyles.secondaryTitleSpacing,
      color: Colors.white,
    );

    _textComponent =
        FadeTextComponent(
            text: text,
            textStyle: style,
            shader: shader,
            baseColor: GameStyles.secondaryTitleColor,
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
        WaitEffect(2.5),
        OpacityEffect.to(
          1.0,
          EffectController(
            duration: GameStyles.secTitleAnimDuration,
            curve: GameCurves.titleEntry,
          ),
        ),
      ]),
    );

    // Animate Scale
    _textComponent.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 4, curve: GameCurves.titleScale),
          onComplete: showComplete,
        ),
      ]),
    );
  }

  void hide() {
    _textComponent.add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.5, curve: GameCurves.titleEntry),
      ),
    );
  }
}
