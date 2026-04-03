import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Curves, Cubic, TextPainter, TextSpan;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class CinematicSecondaryTitleComponent extends PositionComponent
    with HasGameReference
    implements OpacityProvider {
  final String text;
  final FragmentProgram shaderProgram;

  late PositionComponent _contentWrapper;

  double _currentOpacity = 0.0;

  /// When true, the show/hide animation owns per-character opacity.
  bool _isAnimating = false;

  @override
  double get opacity => _currentOpacity;

  @override
  set opacity(double value) {
    _currentOpacity = value;
    if (isLoaded && !_isAnimating) {
      for (final component in _charComponents) {
        component.opacity = value;
      }
    }
  }

  @override
  void onMount() {
    super.onMount();
    if (!_isAnimating) {
      opacity = _currentOpacity;
    }
  }

  CinematicSecondaryTitleComponent({
    required this.text,
    required this.shaderProgram,
    super.position,
  }) : super(anchor: Anchor.center) {
    opacity = 0.0;
  }

  void setParallaxOffset(Vector2 offset) {
    if (isLoaded) {
      _contentWrapper.position = offset;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2 + GameLayout.secTitleOffsetVector;
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

    // 1. Measure each character width
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

    final spacing = style.letterSpacing ?? 0.0;
    final totalSpan = totalWidth + (text.length - 1) * spacing;
    double currentX = -totalSpan / 2;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final width = charWidths[i];

      final charComponent = FadeTextComponent(
        text: char,
        textStyle: style,
        shaderProgram: shaderProgram,
        baseColor: GameStyles.secondaryTitleColor,
        anchor: Anchor.center,
        priority: 1,
      );

      charComponent.position = Vector2(currentX + width / 2, 40);
      charComponent.opacity = 0.0;
      charComponent.scale = Vector2.all(1.0);

      _contentWrapper.add(charComponent);
      _charComponents.add(charComponent);

      currentX += width;
      if (i < text.length - 1) {
        currentX += spacing;
      }
    }
  }

  final List<FadeTextComponent> _charComponents = [];

  void show(VoidCallback showComplete) {
    if (_charComponents.isEmpty) return;

    _isAnimating = true;
    (game as MyGame).audio.playSlideIn();

    final originalWrapperPos = _contentWrapper.position.clone();
    _contentWrapper.position.x -= 100;
    _contentWrapper.add(
      MoveEffect.to(
        originalWrapperPos,
        EffectController(
            duration: 2, curve: const Cubic(0.25, 0.1, 0.25, 1.0)),
      ),
    );
    int completedChars = 0;

    for (int i = 0; i < _charComponents.length; i++) {
      final component = _charComponents[i];
      final delay = i * 0.05;

      // Opacity fade in
      component.add(
        OpacityEffect.to(
          1.0,
          EffectController(
            duration: 0.4,
            curve: Curves.easeOut,
            startDelay: delay,
          ),
        ),
      );

      // Rise from y=40 to y=0
      component.add(
        MoveEffect.to(
          Vector2(component.position.x, 0),
          EffectController(
            duration: 0.8,
            curve: Curves.easeOutCubic,
            startDelay: delay,
          ),
        ),
      );

      // Squash & stretch → elastic settle
      component.add(
        ScaleEffect.to(
          Vector2(0.95, 1.1),
          EffectController(
            duration: 0.6,
            curve: Curves.easeOut,
            startDelay: delay,
          ),
          onComplete: () {
            component.add(
              ScaleEffect.to(
                Vector2.all(1.0),
                EffectController(duration: 0.6, curve: Curves.elasticOut),
                onComplete: () {
                  completedChars++;
                  if (completedChars == _charComponents.length) {
                    _isAnimating = false;
                    _currentOpacity = 1.0;
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
    _isAnimating = true;
    int completedChars = 0;
    for (final component in _charComponents) {
      component.add(
        OpacityEffect.to(
          0.0,
          EffectController(duration: 0.5, curve: Curves.easeIn),
          onComplete: () {
            completedChars++;
            if (completedChars == _charComponents.length) {
              _isAnimating = false;
              _currentOpacity = 0.0;
            }
          },
        ),
      );
    }
  }
}
