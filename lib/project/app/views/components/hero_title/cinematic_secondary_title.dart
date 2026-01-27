import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Curves, Cubic, TextPainter, TextSpan;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class CinematicSecondaryTitleComponent extends PositionComponent
    with HasGameReference
    implements OpacityProvider {
  final String text;
  final FragmentShader shader;

  late PositionComponent _contentWrapper;

  // late FadeTextComponent _textComponent; // unused

  @override
  double get opacity =>
      _charComponents.isNotEmpty ? _charComponents.first.opacity : 1.0;

  @override
  set opacity(double value) {
    if (isLoaded) {
      for (final component in _charComponents) {
        component.opacity = value;
      }
    }
  }

  CinematicSecondaryTitleComponent({
    required this.text,
    required this.shader,
    super.position,
  }) : super(anchor: Anchor.center);

  void setParallaxOffset(Vector2 offset) {
    if (isLoaded) {
      _contentWrapper.position = offset;
    }
  }

  @override
  Future<void> onLoad() async {
    _contentWrapper = PositionComponent(anchor: Anchor.center);
    add(_contentWrapper);

    const style = TextStyle(
      fontSize: GameStyles.secondaryTitleFontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: GameStyles.secondaryTitleSpacing,
      color: Colors.white,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Measure and Center
    double totalWidth = 0;
    final List<double> charWidths = [];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      textPainter.text = TextSpan(text: char, style: style);
      textPainter.layout();
      final width = textPainter.width;
      charWidths.add(width);
      totalWidth += width;
    }

    // Adjust for letter spacing roughly (Flutter TextPainter includes it usually, but manual spacing might be needed)
    // We will just place them sequentially based on measured width.
    final spacing = style.letterSpacing ?? 0.0; // Use style directly

    double currentX = -(totalWidth + (text.length - 1) * spacing) / 2;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final width = charWidths[i];

      final charComponent = FadeTextComponent(
        text: char,
        textStyle: style,
        shader: shader,
        baseColor: GameStyles.secondaryTitleColor,
        anchor: Anchor.center,
        priority: 1,
      );

      // Position relative to wrapper center
      // x: currentX + half width (since anchor is center)
      // y: 40 (Initial state)
      charComponent.position = Vector2(currentX + width / 2, 40);
      charComponent.opacity = 0;
      charComponent.scale = Vector2.all(
        1.0,
      ); // Start normal? Or scaled? "Initial State... opacity 0, y 40".

      _contentWrapper.add(charComponent);
      _charComponents.add(charComponent);

      currentX += width + spacing;
    }
  }

  final List<FadeTextComponent> _charComponents = [];

  void show(VoidCallback showComplete) {
    if (_charComponents.isEmpty || _charComponents.first.opacity > 0) return;

    (game as MyGame).playSlideIn();

    final originalWrapperPos = _contentWrapper.position.clone();
    _contentWrapper.position.x -= 100; // Start 100px left
    _contentWrapper.add(
      MoveEffect.to(
        originalWrapperPos,
        EffectController(
          duration: 2,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
        ),
      ),
    );
    int completedChars = 0;

    for (int i = 0; i < _charComponents.length; i++) {
      final component = _charComponents[i];
      final delay = i * 0.05;

      // 1. Rise & Fade & Stretch

      // Opacity
      component.add(
        OpacityEffect.to(
          1.0,
          EffectController(
            duration: 0.1,
            curve: Curves.linear,
            startDelay: delay,
          ),
        ),
      );

      // Move (Rise)
      component.add(
        MoveEffect.to(
          Vector2(component.position.x, 0), // Target Y: 0
          EffectController(
            duration: 0.8,
            curve: Curves.easeOutCubic,
            startDelay: delay,
          ),
        ),
      );

      // Squash and Stretch: Stretch Vertically during rise
      component.add(
        ScaleEffect.to(
          Vector2(0.95, 1.1),
          EffectController(
            duration: 0.6,
            curve: Curves.easeOut,
            startDelay: delay,
          ),
          onComplete: () {
            // 2. Landing Bounce (Elastic restore to 1.0)
            // Note: onComplete will happen after delay+duration
            component.add(
              ScaleEffect.to(
                Vector2.all(1.0),
                EffectController(duration: 0.6, curve: Curves.elasticOut),
                onComplete: () {
                  completedChars++;
                  if (completedChars == _charComponents.length) {
                    showComplete();
                  }
                },
              ),
            );
          },
        ),
      );
    }
  }

  void hide() {
    for (final component in _charComponents) {
      component.add(
        OpacityEffect.to(
          0.0,
          EffectController(duration: 0.5, curve: Curves.easeIn),
        ),
      );
    }
  }
}
