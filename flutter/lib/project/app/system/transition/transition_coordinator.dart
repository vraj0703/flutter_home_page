import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

import 'package:flutter_home_page/project/app/interfaces/transition_context.dart';
import 'package:flutter_home_page/project/app/sections/philosophy_section.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/flash_transition_component.dart';

/// Coordinates the seamless transition from Philosophy to Experience section
/// with precise timing of audio, visual effects, and section lifecycle management.
class TransitionCoordinator {
  final TransitionContext game;
  bool _isTransitioning = false;

  TransitionCoordinator(this.game);

  /// Executes the complete Philosophy → Experience transition sequence
  ///
  /// Timeline:
  /// - 0ms: Freeze capture, block input, start audio duck
  /// - 400ms: Audio climax, lightning flash, shatter trigger (0.7s duration), camera shake
  /// - Peak Flash (~800ms): Stop Philosophy runner, start Experience runner, trigger animateEntry()
  /// - 1600ms: Flash complete → unblock input
  Future<void> startPhilosophyToExperience({
    required PhilosophySection from,
  }) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Lookup Experience Index (assuming it follows Philosophy)
    final sections = game.primarySequenceRunner.sections;
    final philosophyIndex = sections.indexOf(from);
    final experienceIndex = philosophyIndex + 1;

    // Validate
    if (experienceIndex >= sections.length) {
      _isTransitioning = false;
      return;
    }

    // 1. SNAPSHOT & CLIMAX PREP
    from.freezeCapture = true;
    from.nextButton.opacity = 0.0;
    game.blockInput(); // Redundant if we rely on state, but good for safety

    // Notify Bloc of new state
    game.queuer.queue(event: const SceneEvent.loadExperience());

    // 2. AUDIO DUCK (0-400ms)
    game.audio.duckAmbientLoops(durationMs: 400);

    // Sustain Phase: Wait for the user to "feel" the full rain intensity.
    // This is an awaited delay in a linear async sequence — safe from lifecycle issues.
    final config = ScrollSequenceConfig.philosophyTransition;
    await Future.delayed(Duration(milliseconds: config.sustainDurationMs));

    // 3. VISUAL CLIMAX (Shatter + Lightning)
    from.rainTransition.triggerShatter();
    from.orchestrator.lightning.triggerFlash(1.0);
    game.audio.playTransitionClimax();
    // Master Epic: Haptics at exact moment of shatter
    HapticFeedback.heavyImpact();
    _triggerCameraShake(intensity: 8.0, duration: 0.5);

    // Wait for "Visible Crack" phase before flashing white.
    // Awaited — blocks this method until the delay completes.
    await Future.delayed(Duration(milliseconds: config.shatterToFlashDelayMs));

    // 4. MOUNT FLASH OVERLAY
    // Force a fresh capture for the refraction texture (sync)
    from.forceCaptureRefraction();

    final flash = FlashTransitionComponent(
      texture: from.rainTransition.backgroundTexture,
      onPeakReached: () async {
        // === AT THE PEAK OF THE WHITE FLASH ===

        await game.primarySequenceRunner.jumpToSection(experienceIndex);

        // Update Global State to Experience (keep this for UI overlays/Bloc)
        game.queuer.queue(event: const SceneEvent.enterExperience());
      },
      onComplete: () {
        // Flash fully decayed, unblock input
        game.unblockInput();
        _isTransitioning = false;
      },
    );

    game.camera.viewport.add(flash);
  }

  /// Executes the return transition from Experience to Philosophy (Scroll Up)
  Future<void> returnToPhilosophy() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    game.blockInput();

    // 1. Switch State back to Active (Philosophy)
    game.queuer.queue(event: const SceneEvent.onScroll());

    // 2. Resume Philosophy Runner in reverse mode
    // SequenceRunner handles the exit of current (Experience) and entry of previous (Philosophy)
    await game.primarySequenceRunner.previous();

    // 3. Unblock
    game.unblockInput();
    _isTransitioning = false;
  }

  /// Triggers camera shake by adding a [_CameraShakeComponent] to the viewport.
  /// Tied to the component tree — auto-cleans up if the viewport is removed.
  void _triggerCameraShake({
    required double intensity,
    required double duration,
  }) {
    game.camera.viewport.add(
      _CameraShakeComponent(
        intensity: intensity,
        duration: duration,
        viewfinder: game.camera.viewfinder,
      ),
    );
  }
}

/// Self-removing component that applies decaying random offsets to the camera
/// viewfinder. Lives in the viewport's component tree, so it is automatically
/// disposed if the viewport (or game) is removed — no orphaned timers.
class _CameraShakeComponent extends Component {
  final double intensity;
  final double duration;
  final Viewfinder viewfinder;
  final math.Random _random = math.Random();

  double _elapsed = 0.0;

  _CameraShakeComponent({
    required this.intensity,
    required this.duration,
    required this.viewfinder,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      // Shake complete — reset camera and self-remove
      viewfinder.position.setZero();
      removeFromParent();
      return;
    }

    // Decay intensity linearly over duration
    final progress = _elapsed / duration;
    final currentIntensity = intensity * (1.0 - progress);

    viewfinder.position.setFrom(
      Vector2(
        (_random.nextDouble() - 0.5) * currentIntensity,
        (_random.nextDouble() - 0.5) * currentIntensity,
      ),
    );
  }
}
