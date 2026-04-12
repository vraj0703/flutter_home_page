import 'dart:async';
import 'package:flame/game.dart';

/// Three-tier game loop control — replaces binary pause/resume.
///
/// - [active]:     Every frame processes (60fps target)
/// - [background]: Accumulates dt, processes every ~83ms (12fps) — keeps
///                 ambient particles alive at near-zero cost
/// - [frozen]:     Engine fully paused — zero frames, zero CPU
enum TickTier { active, background, frozen }

/// Mixin that adds tiered frame-rate control to a FlameGame.
///
/// Usage:
/// ```dart
/// class MyGame extends FlameGame with ThrottledGame { ... }
/// ```
///
/// In your `update(double dt)`:
/// ```dart
/// @override
/// void update(double dt) {
///   super.update(dt);
///   if (!shouldProcessTick(dt)) return;
///   // ... your game logic
/// }
/// ```
mixin ThrottledGame on FlameGame {
  TickTier _tickTier = TickTier.active;
  TickTier _lastActiveTier = TickTier.active;

  /// Accumulated dt during background tier — drains when threshold reached.
  double _backgroundAccumulator = 0.0;

  /// Background tier target interval: ~83ms (12fps).
  static const double _backgroundInterval = 1.0 / 12.0;

  Timer? _backgroundTimer;

  /// The current tick tier.
  TickTier get tickTier => _tickTier;

  /// The last non-frozen tier (used to restore after tab visibility change).
  TickTier get lastActiveTier => _lastActiveTier;

  /// Transition to a new tick tier.
  void setTickTier(TickTier tier) {
    if (tier == _tickTier) return;

    // Remember last active tier for restore-after-tab-hidden
    if (_tickTier != TickTier.frozen) {
      _lastActiveTier = _tickTier;
    }

    _tickTier = tier;

    switch (tier) {
      case TickTier.active:
        _backgroundAccumulator = 0.0;
        if (paused) resumeEngine();
      case TickTier.background:
        _backgroundAccumulator = 0.0;
        // Keep engine running — we gate in shouldProcessTick
        if (paused) resumeEngine();
      case TickTier.frozen:
        pauseEngine();
    }
  }

  /// Call at the top of your `update(dt)`. Returns `true` if game logic should
  /// run this frame. In [background] tier, returns `true` only every ~83ms.
  bool shouldProcessTick(double dt) {
    if (_tickTier == TickTier.active) return true;
    if (_tickTier == TickTier.frozen) return false;

    // Background tier: accumulate and gate
    _backgroundAccumulator += dt;
    if (_backgroundAccumulator >= _backgroundInterval) {
      _backgroundAccumulator -= _backgroundInterval;
      return true;
    }
    return false;
  }
}
