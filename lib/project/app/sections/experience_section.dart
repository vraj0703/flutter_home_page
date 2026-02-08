import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/experience/circles_background_component.dart';

class ExperienceSection implements GameSection {
  final CirclesBackgroundComponent circlesBackground;
  final Queuer queuer;
  Vector2 screenSize;
  double _scrollProgress = 0.0;
  bool _hasWarmedUpNext = false;
  bool _isAnimatingEntry = false;

  static const double _maxHeight = 3000.0;

  ExperienceSection({
    required this.circlesBackground,
    required this.queuer,
    required this.screenSize,
  });

  @override
  double get maxScrollExtent => _maxHeight;

  @override
  List<Vector2> get snapRegions => [
    Vector2(0, 0), // Start
    Vector2(2500, 3000), // End
  ];

  // Callbacks
  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onReverseComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  Future<void> warmUp() async {
    // 1. Reset State
    _scrollProgress = 0.0;
    _hasWarmedUpNext = false;
    circlesBackground.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;

    // 1. Configure Physics - Reset to top of independent range
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    // 2. Position Component
    circlesBackground.position = Vector2.zero();
    circlesBackground.size = screenSize;
    circlesBackground.opacity =
    0.0; // Start hidden (opacity handled by animateEntry)

    // 3. Notify Global State
    queuer.queue(event: const SceneEvent.enterExperience());
  }

  /// Cinematic entry animation triggered after flash transition
  /// Non-scroll-dependent "settling" effect with scale + opacity + bloom
  Future<void> animateEntry() async {
    _isAnimatingEntry = true;

    // Start at zoomed scale, fully transparent, no bloom
    circlesBackground.scale = Vector2.all(1.2);
    circlesBackground.opacity = 0.0;
    circlesBackground.revealProgress = 0.0;

    final controller = EffectController(
      duration: 1.2,
      curve: Curves.easeOutCubic,
    );

    // Animate scale down to 1.0 ("settling" zoom)
    circlesBackground.add(ScaleEffect.to(Vector2.all(1.0), controller));

    // Animate opacity to 1.0 (fade in)
    circlesBackground.add(
      OpacityEffect.to(
        1.0,
        controller,
        onComplete: () => _isAnimatingEntry = false,
      ),
    );

    // Animate revealProgress to intensify shader bloom (0.0 → 1.0)
    // Manual animation over 1.2 seconds
    _animateRevealProgress();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setSnapRegions(snapRegions);
    setScrollOffset(_maxHeight);
    circlesBackground.opacity = 1.0;
  }

  @override
  Future<void> exit() async {
    circlesBackground.opacity = 0.0;
  }

  @override
  ScrollResult handleScroll(double delta) {
    final newScroll = _scrollProgress + delta;
    setScrollOffset(newScroll);

    if (newScroll > _maxHeight) return ScrollOverflow(newScroll - _maxHeight);
    if (newScroll < 0) return ScrollUnderflow(newScroll);

    return ScrollConsumed(newScroll);
  }

  @override
  void setScrollOffset(double offset) {
    _scrollProgress = offset;

    // Trigger Pre-warm for next section (500px before end)
    if (_scrollProgress > _maxHeight - 500 && !_hasWarmedUpNext) {
      onWarmUpNextSection?.call();
      _hasWarmedUpNext = true;
    }

    _updateVisuals();
  }

  void _updateVisuals() {
    // Skip scroll-driven updates during cinematic entry animation
    if (_isAnimatingEntry) return;

    // Fade Rotator (aligned with background)
    if (_scrollProgress >= 0 && _scrollProgress <= 1000) {
      final fade = (_scrollProgress / 1000.0).clamp(0.0, 1.0);
      circlesBackground.opacity = fade;
    } else if (_scrollProgress > 1000) {
      circlesBackground.opacity = 1.0;
    } else {
      circlesBackground.opacity = 0.0;
    }
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    circlesBackground.size = screenSize;
  }

  /// Helper to manually animate revealProgress from 0.0 → 1.0 over 1.2s
  void _animateRevealProgress() async {
    const duration = 1.2;
    const steps = 60; // 60fps
    const stepDuration = duration / steps;

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(
        Duration(milliseconds: (stepDuration * 1000).round()),
      );
      final progress = (i / steps).clamp(0.0, 1.0);
      circlesBackground.revealProgress = progress;
    }
  }

  @override
  void update(double dt) {}
}
