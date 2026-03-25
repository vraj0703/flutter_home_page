import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/views/components/experience/circles_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_content_component.dart';

import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/experience_page_controller.dart';

class ExperienceSection extends Component
    with FlameBlocListenable<SceneBloc, SceneState>
    implements GameSection {
  final CirclesBackgroundComponent circlesBackground;
  final Queuer queuer;
  late final ExperienceContentComponent content;
  final ExperiencePageController _controller = ExperiencePageController();
  Vector2 screenSize;
  bool _isAnimatingEntry = false;

  // GameSection Interface Implementation
  @override
  VoidCallback? onComplete;
  @override
  VoidCallback? onReverseComplete;
  @override
  VoidCallback? onWarmUpNextSection;

  @override
  double get maxScrollExtent => 2000.0; // Allow some scroll play for background effect

  @override
  List<Vector2> get snapRegions => []; // No snapping for free-flow background interaction

  ExperienceSection({
    required this.circlesBackground,
    required this.queuer,
    required this.screenSize,
  }) {
    content = ExperienceContentComponent();
     add(content);

    _controller.onScrollUpdate = (scroll) {
      circlesBackground.setScrollProgress(scroll / maxScrollExtent);
    };
  }

  @override
  void prepareGhostRender() {
    circlesBackground.opacity = 0.02;
    content.opacity = 0.02;
  }

  @override
  Future<void> warmUp() async {
    circlesBackground.warmUp();
  }

  @override
  Future<void> finalizeGhostRender() async {
    circlesBackground.opacity = 0.0;
    content.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    // Reset internal state
    _controller.reset();

    // Configure system
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Trigger visual entry
    await animateEntry();
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    // Entering from below (future section)? Not applicable as this is last section.
    // BUT, if we add a section AFTER this, we'd need this.
    _controller.reset();
    _controller.setTargetScroll(maxScrollExtent); // Start at bottom?

    scrollSystem.resetScroll(maxScrollExtent);
    scrollSystem.setSnapRegions(snapRegions);

    // Make visible immediately
    circlesBackground.opacity = 1.0;
    circlesBackground.scale = Vector2.all(1.0);
    content.opacity = 1.0;
  }

  @override
  void setScrollOffset(double offset) {
    if (offset < 0) {
      onReverseComplete?.call();
      return;
    }
    if (offset > maxScrollExtent) {
      onComplete?.call();
      // Clamp visual
      _controller.setTargetScroll(maxScrollExtent);
      return;
    }
    _controller.setTargetScroll(offset);
  }

  @override
  ScrollResult handleScroll(double delta) {
    final newTarget = _controller.targetScroll + delta;

    if (newTarget < -10.0) {
      // Slight threshold for underflow
      return ScrollUnderflow(newTarget);
    }

    if (newTarget > maxScrollExtent) {
      return ScrollOverflow(newTarget - maxScrollExtent);
    }

    _controller.setTargetScroll(newTarget);
    return ScrollConsumed(newTarget);
  }

  @override
  void onNewState(SceneState state) {
    state.maybeMap(experience: (_) => animateEntry(), orElse: () {});
  }

  @override
  void update(double dt) {
    super.update(dt);
    _controller.update(dt);
  }

  /// Cinematic Hero Entry: Fades, Settles Scale, and Blooms Colors
  Future<void> animateEntry() async {
    if (_isAnimatingEntry) return;
    _isAnimatingEntry = true;

    try {
      // Clear any stale effects from previous calls to prevent stacking
      circlesBackground.children.whereType<Effect>().toList().forEach(
        (e) => e.removeFromParent(),
      );

      // 1. Initial State: Blown-out and zoomed in
      circlesBackground.opacity = 0.0;
      circlesBackground.scale = Vector2.all(1.2); // Start zoomed

      // 2. Multi-Part Animation Sequence
      final duration = const Duration(milliseconds: 1200);
      final curve = Curves.easeOutCubic;

      // Fade in the background
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

      // 3. Finalize
      await Future.delayed(duration);
    } finally {
      _isAnimatingEntry = false;
    }
  }

  Future<void> nextExperience() async {
    // Phase 1 (Bloom): Flash-fade the background to white, then settle
    circlesBackground.add(
      OpacityEffect.to(
        0.2,
        EffectController(duration: 0.4, curve: Curves.easeIn),
        onComplete: () {
          // Phase 2 (Swap): Update the text values at peak
          content.cycleData();
          content.animateTextReveal();

          // Phase 3 (Settle): Fade background back to full opacity
          circlesBackground.add(
            OpacityEffect.to(
              1.0,
              EffectController(duration: 0.8, curve: Curves.easeOut),
            ),
          );
        },
      ),
    );
  }

  @override
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

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    circlesBackground.size = screenSize;
    content.size = screenSize; // Ensure content gets resized
  }

  @override
  void dispose() {
    // Clean up circles background or other resources if needed later
    circlesBackground.removeFromParent();
    content.removeFromParent();
  }
}

