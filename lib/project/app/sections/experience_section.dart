import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/views/components/experience/circles_background_component.dart';

class ExperienceSection {
  final CirclesBackgroundComponent circlesBackground;
  final Queuer queuer;
  Vector2 screenSize;
  ExperienceSection({
    required this.circlesBackground,
    required this.queuer,
    required this.screenSize,
  });

  /// Cinematic Hero Entry: Fades, Settles Scale, and Blooms Colors
  Future<void> animateEntry() async {
    // 1. Initial State: Blown-out and zoomed in
    circlesBackground.opacity = 0.0;
    circlesBackground.scale = Vector2.all(1.2); // Start zoomed
    circlesBackground.revealProgress = 1.0; // Start at max bloom (1.0)

    // 2. Multi-Part Animation Sequence
    final duration = const Duration(milliseconds: 1200);
    final curve = Curves.easeOutCubic;

    // Fade in the background (Fast fade in)
    circlesBackground.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.8, curve: Curves.easeIn),
      ),
    );

    // Settle the scale back to 1.0 (Zoom-out settle)
    circlesBackground.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 1.2, curve: curve),
      ),
    );

    // Fade the shader "Bloom" (revealProgress) from 1.0 back to 0.0 (Settled Colors)
    circlesBackground.add(
      _RevealProgressEffect(
        from: 1.0,
        to: 0.0,
        controller: EffectController(duration: 1.5, curve: curve),
      ),
    );

    // 3. Finalize
    await Future.delayed(duration);
  }

  Future<void> exit() async {
    // Fade out for return transition
    circlesBackground.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.5, curve: Curves.easeOut),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void onResize(Vector2 newSize) {
    screenSize = newSize;
    circlesBackground.size = screenSize;
  }
}

class _RevealProgressEffect extends Effect {
  final double from;
  final double to;

  _RevealProgressEffect({
    required this.from,
    required this.to,
    required EffectController controller,
  }) : super(controller);

  @override
  void apply(double progress) {
    if (parent is CirclesBackgroundComponent) {
      (parent as CirclesBackgroundComponent).revealProgress =
          from + (to - from) * progress;
    }
  }
}
