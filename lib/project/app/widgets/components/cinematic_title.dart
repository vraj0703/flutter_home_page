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

  void animateToTab(
    Vector2 targetPos,
    double targetScale,
    VoidCallback onComplete,
  ) {
    // 1. Remove conflicting effects from Parent (just in case)
    removeAll(children.query<Effect>());

    // 2. Remove conflicting effects from Child
    _primaryTitle.removeAll(_primaryTitle.children.query<Effect>());

    // 3. Calculate Local Target for the Child
    // Global Target = ParentComp.position + ChildComp.position
    // ChildComp.target = Global Target - ParentComp.position
    final localTarget = targetPos - position;

    // 4. Move and Scale Child (_primaryTitle) directly
    _primaryTitle.add(
      MoveToEffect(
        localTarget,
        EffectController(duration: 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _primaryTitle.add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: 1.0,
          curve: Curves.easeInOutCubic,
          onMax: onComplete,
        ),
      ),
    );
  }

  void hide() {
    _primaryTitle.opacity = 0;
  }
}
