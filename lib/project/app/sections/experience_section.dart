import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/views/components/experience/circles_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_content_component.dart';

import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/experience_page_controller.dart';

class ExperienceSection extends Component
    with FlameBlocListenable<SceneBloc, SceneState> {
  final CirclesBackgroundComponent circlesBackground;
  final Queuer queuer;
  late final ExperienceContentComponent content;
  final ExperiencePageController _controller = ExperiencePageController();
  Vector2 screenSize;

  ExperienceSection({
    required this.circlesBackground,
    required this.queuer,
    required this.screenSize,
  }) {
    content = ExperienceContentComponent();
    add(content);

    _controller.onScrollUpdate = (scroll) {
      circlesBackground.setScrollProgress(scroll / 1000.0);
    };
  }

  @override
  void onNewState(SceneState state) {
    state.maybeMap(experience: (_) => animateEntry(), orElse: () {});
  }

  void handleScroll(double delta) {
    _controller.setTargetScroll(_controller.targetScroll + delta);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _controller.update(dt);
  }

  /// Cinematic Hero Entry: Fades, Settles Scale, and Blooms Colors
  Future<void> animateEntry() async {
    // 1. Initial State: Blown-out and zoomed in
    circlesBackground.opacity = 0.0;
    circlesBackground.scale = Vector2.all(1.2); // Start zoomed
    circlesBackground.revealProgress = 1.0; // Start at max bloom (1.0)

    // Ensure content is loaded and ready
    content.opacity = 0.0;

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
        onComplete: () {
          // Bloom settled.
        },
      ),
    );

    // Animate Content In
    content.animateEntry();

    // 3. Finalize
    await Future.delayed(duration);
  }

  Future<void> nextExperience() async {
    // Phase 1 (Bloom): Animate circlesBackground.revealProgress to 1.0 (0.4s)
    circlesBackground.add(
      _RevealProgressEffect(
        from: 0.0,
        to: 1.0,
        controller: EffectController(duration: 0.4, curve: Curves.easeIn),
        onComplete: () {
          // Phase 2 (Swap): At 1.0, update the text values
          content.cycleData();
          content.animateTextReveal();

          // Phase 3 (Settle): Animate circlesBackground.revealProgress back to 0.0 (0.8s)
          circlesBackground.add(
            _RevealProgressEffect(
              from: 1.0,
              to: 0.0,
              controller: EffectController(
                duration: 0.8,
                curve: Curves.easeOut,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> exit() async {
    // Fade out for return transition
    circlesBackground.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.5, curve: Curves.easeOut),
      ),
    );
    content.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.4, curve: Curves.easeOut),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void onResize(Vector2 newSize) {
    screenSize = newSize;
    circlesBackground.size = screenSize;
    content.size = screenSize; // Ensure content gets resized
  }

  void dispose() {
    // Clean up circles background or other resources if needed later
    circlesBackground.removeFromParent();
    content.removeFromParent();
  }
}

class _RevealProgressEffect extends Effect {
  final double from;
  final double to;

  _RevealProgressEffect({
    required this.from,
    required this.to,
    required EffectController controller,
    super.onComplete,
  }) : super(controller);

  @override
  void apply(double progress) {
    if (parent is CirclesBackgroundComponent) {
      (parent as CirclesBackgroundComponent).revealProgress =
          from + (to - from) * progress;
    }
  }
}
