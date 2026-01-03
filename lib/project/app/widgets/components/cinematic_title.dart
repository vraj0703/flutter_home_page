import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Curves;
import 'package:flutter_home_page/project/app/utils/wait_effect.dart';

import 'fade_text.dart';

class CinematicTitleComponent extends PositionComponent with HasGameReference {
  final String primaryText;
  final String secondaryText;
  final FragmentShader shader;

  late FadeTextComponent _primaryTitle;
  late FadeTextComponent _secondaryTitle;

  CinematicTitleComponent({
    required this.primaryText,
    required this.secondaryText,
    required this.shader,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // --- 1. Initialize Primary Title ("VISHAL RAJ") ---
    const primaryStyle = TextStyle(
      fontSize: 54,
      letterSpacing: 28,
      fontWeight: FontWeight.w500,
      fontFamily: 'ModrntUrban',
    );

    _primaryTitle =
        FadeTextComponent(
            text: primaryText.toUpperCase(),
            textStyle: primaryStyle,
            shader: shader,
            baseColor: const Color(0xFFE3E4E5),
            // Gold/Copper
            anchor: Anchor.center,
            priority: 8,
          )
          ..opacity = 0
          ..scale = Vector2.zero();

    // --- 2. Initialize Secondary Title ("PORTFOLIO MMXXV") ---
    const secondaryStyle = TextStyle(
      fontSize: 14, // Smaller scale
      fontWeight: FontWeight.w400,
      letterSpacing: 4, // High spacing, but smaller than primary
      color: Colors.white, // Base color (shader overrides this)
    );

    _secondaryTitle =
        FadeTextComponent(
            text: secondaryText,
            textStyle: secondaryStyle,
            shader: shader,
            // Reuse the metallic shader logic
            baseColor: const Color(0xFFAAB0B5),
            // Muted Silver/Grey
            anchor: Anchor.center,
            priority: 1,
            position: Vector2(0, 48), // Positioned below primary title
          )
          ..opacity = 0
          ..scale = Vector2.zero();

    // Add both to the component tree
    addAll([_primaryTitle, _secondaryTitle]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
  }

  void show() {
    if (_primaryTitle.opacity > 0) return;
    // Primary reveal
    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(1),
        OpacityEffect.to(
          1.0,
          EffectController(duration: 4, curve: Curves.easeOut),
        ),
      ]),
    );

    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(1),
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 4, curve: Curves.fastLinearToSlowEaseIn),
        ),
      ]),
    );

    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(1),
        MoveByEffect(
          Vector2(0, -20), // Subtle upward "heat" drift
          EffectController(duration: 4, curve: Curves.easeInCubic),
        ),
      ]),
    );

    // Secondary reveal (Staggered)
    _secondaryTitle.add(
      SequenceEffect([
        WaitEffect(5.5), // Custom effect created earlier (1.2s delay)
        OpacityEffect.to(
          1.0,
          EffectController(duration: 2.0, curve: Curves.easeOut),
        ),
      ]),
    );

    _secondaryTitle.add(
      SequenceEffect([
        WaitEffect(5.5),
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 2, curve: Curves.fastLinearToSlowEaseIn),
        ),
      ]),
    );
  }

  void animateToHeader(Vector2 targetPosition, double scale) {
    // 0. Remove pending/running effects (like the initial delayed reveal)
    _secondaryTitle.removeWhere((c) => c is Effect);

    // 1. Fade out secondary text immediately
    _secondaryTitle.add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.1, curve: Curves.easeOut),
      ),
    );

    // 2. Move and Scale THIS component (the parent)
    add(
      MoveToEffect(
        targetPosition,
        EffectController(duration: 1.2, curve: Curves.easeInOutCubic),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(scale),
        EffectController(duration: 1.2, curve: Curves.easeInOutCubic),
      ),
    );
  }

  void updateLayout({
    required Vector2 targetPos,
    required double targetScale,
    bool showSecondary = true,
  }) {
    // 1. Clear existing move/scale effects to prevent "fighting"
    removeAll(children.query<Effect>());
    _secondaryTitle.removeAll(_secondaryTitle.children.query<Effect>());

    // 2. Animate Parent to position
    add(
      MoveToEffect(
        targetPos,
        EffectController(duration: 0.8, curve: Curves.easeInOutCubic),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(duration: 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Handle Secondary Text visibility (it's hidden in Header mode usually)
    _secondaryTitle.add(
      OpacityEffect.to(
        showSecondary ? 1.0 : 0.0,
        EffectController(duration: 0.4),
      ),
    );
  }
}
