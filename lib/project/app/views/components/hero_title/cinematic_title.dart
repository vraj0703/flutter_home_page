import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show TextStyle, FontWeight;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/utils/wait_effect.dart';

import '../fade_text.dart';

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
      fontSize: GameStyles.primaryTitleFontSize,
      letterSpacing: GameStyles.primaryTitleLetterSpacing,
      fontWeight: FontWeight.w500,
      fontFamily: GameStyles.fontModernUrban,
    );

    _primaryTitle =
        FadeTextComponent(
            text: primaryText.toUpperCase(),
            textStyle: primaryStyle,
            shader: shader,
            baseColor: GameStyles.boldTextBase,
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
        WaitEffect(ScrollSequenceConfig.titleRevealDelay),
        OpacityEffect.to(
          1.0,
          EffectController(
            duration: ScrollSequenceConfig.titleAnimDuration,
            curve: GameCurves.titleEntry,
          ),
        ),
      ]),
    );

    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(ScrollSequenceConfig.titleRevealDelay),
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(
            duration: ScrollSequenceConfig.titleAnimDuration,
            curve: GameCurves.titleScale,
          ),
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
          Vector2(0, GameLayout.titleHeatDriftY), // Subtle upward "heat" drift
          EffectController(
            duration: ScrollSequenceConfig.titleAnimDuration,
            curve: GameCurves.titleDrift,
          ),
        ),
      ]),
    );
  }

  void animateToTab(
    Vector2 targetPos,
    double targetScale,
    VoidCallback onComplete,
  ) {
    removeAll(children.query<Effect>());
    _primaryTitle.removeAll(_primaryTitle.children.query<Effect>());
    final localTarget = targetPos - position;
    _primaryTitle.add(
      MoveToEffect(
        localTarget,
        EffectController(
          duration: ScrollSequenceConfig.titleMoveDuration,
          curve: GameCurves.tabTransition,
        ),
      ),
    );

    _primaryTitle.add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: 1.0,
          curve: GameCurves.tabTransition,
          onMax: onComplete,
        ),
      ),
    );
  }

  void hide() {
    _primaryTitle.opacity = 0;
  }
}
