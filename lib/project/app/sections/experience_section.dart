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

  /// Cinematic Hero Entry: Fades, Settles Scale, and Blooms Colors
  Future<void> animateEntry() async {
    _isAnimatingEntry = true;

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
    // We use a custom ValueEffect to drive the shader uniform
    // Note: EffectController duration 1.5s for a slightly longer bloom tail
    circlesBackground.add(
      OpacityEffect.fadeOut(EffectController(duration: 0.0)),
    );
    // Wait, the user specifically asked for ValueEffect. Flame doesn't have a generic ValueEffect handy in standard unless implemented or using a FloatEffect/SizeEffect etc.
    // Actually Flame DOES NOT have a `ValueEffect` class out of the box in v1.x usually?
    // Let me check if `ValueEffect` exists in this codebase or if I need to implement it.
    // The user provided the code: `ValueEffect<double>(...)`. This implies they expect it to exist or me to use a standard Flame effect that acts like it.
    // Standard Flame has `Effect` subclasses.
    // If `ValueEffect` is missing, I should create a simple inline one or usage `CustomEffect`.
    // However, looking at the user request: "This final plan serves as your Architectural Master Key... here is the specific implementation... `ValueEffect<double>`"
    // I should check if `ValueEffect` is imported or available.
    // If not, I'll implement a `RevealEffect` class or similar.
    // Let's assume for a moment I need to implement it or use a callback effect.
    // Actually, `OpacityEffect` and `ScaleEffect` are standard.
    // `circlesBackground.revealProgress` is a custom property.
    // There isn't a built-in "PropertyEffect".
    // I will check `package:flame/effects.dart` capabilities in my mind.
    // I might need to implement `ValueEffect` or use an `UpdateEffect`.
    // Let's look at the file content again. It imports `package:flame/effects.dart`.

    // DECISION: I will implement a local `_RevealEffect` or usage a timer/tween if `ValueEffect` isn't found.
    // BUT the user PROVIDED the code. They might be assuming I have it.
    // I will write the code as requested, but if `ValueEffect` is not a standard Flame class (it's not), I will create a `CustomEffect` or proper class for it.
    // Actually, to be safe and "Apple-polish", I'll implement `RevealProgressEffect` extending `Effect`.

    circlesBackground.add(
      _RevealProgressEffect(
        from: 1.0,
        to: 0.0,
        controller: EffectController(duration: 1.5, curve: curve),
      ),
    );

    // 3. Finalize
    await Future.delayed(duration);
    _isAnimatingEntry = false;
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

  @override
  void update(double dt) {}
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
