import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show TextStyle, FontWeight, Curves;
import 'package:flutter_home_page/project/app/utils/wait_effect.dart';

import 'fade_text.dart';

class CinematicTitleComponent extends PositionComponent with HasGameReference {
  final String primaryText;
  final FragmentShader shader;

  late FadeTextComponent _primaryTitle;

  CinematicTitleComponent({
    required this.primaryText,
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

    // Add both to the component tree
    add(_primaryTitle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
  }

  void show(VoidCallback showComplete) {
    if (_primaryTitle.opacity > 0) return;
    // Primary reveal
    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(.7),
        OpacityEffect.to(
          1.0,
          EffectController(duration: 4, curve: Curves.easeOut),
        ),
      ]),
    );

    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(.7),
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 4, curve: Curves.fastLinearToSlowEaseIn),
          onComplete: () {
            showComplete();
          },
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
  }

  void animateToHeader(Vector2 targetPosition, double scale) {
    // 0. Remove pending/running effects (like the initial delayed reveal)
    // 1. Fade out secondary text immediately

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
  }

  void animateToTab(
    Vector2 targetPos,
    double targetScale,
    VoidCallback onComplete,
  ) {
    // 1. Remove conflicting effects
    removeAll(children.query<Effect>());

    // 2. Fade out secondary text

    // 3. Calculate Parent Target
    // Primary Text is at (0, 17). We want Primary Text to be at targetPos.
    // So Parent should be at (targetPos.x, targetPos.y - 17).
    final parentTarget = targetPos - Vector2(0, 17);

    // 4. Move and Scale Parent
    add(
      MoveToEffect(
        parentTarget,
        EffectController(duration: 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: 1.0,
          curve: Curves.easeInOutCubic,
          onMax: onComplete, // Trigger callback when done
        ),
      ),
    );
  }

  void hide() {
    _primaryTitle.opacity = 0;
  }
}
