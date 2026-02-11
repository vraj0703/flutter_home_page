import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/sections/experience_section.dart';
import 'package:flutter_home_page/project/app/sections/philosophy_section.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/flash_transition_component.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

/// Coordinates the seamless transition from Philosophy to Experience section
/// with precise timing of audio, visual effects, and section lifecycle management.
class TransitionCoordinator {
  final MyGame game;
  final math.Random _random = math.Random();
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
    required ExperienceSection to,
  }) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // 1. SNAPSHOT & CLIMAX PREP
    from.freezeCapture = true;
    from.nextButton.opacity = 0.0;
    game.blockInput(); // Redundant if we rely on state, but good for safety

    // Notify Bloc of new state
    game.queuer.queue(event: const SceneEvent.loadExperience());

    // 2. AUDIO DUCK (0-400ms)
    game.audio.duckAmbientLoops(durationMs: 400);

    // Small delay for audio duck to start
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. VISUAL CLIMAX (Shatter + Lightning)
    from.rainTransition.triggerShatter();
    from.orchestrator.lightning.triggerFlash(1.0);
    game.audio.playTransitionClimax();
    // Master Epic: Haptics at exact moment of shatter
    HapticFeedback.heavyImpact();
    _triggerCameraShake(intensity: 12.0, duration: 0.5);

    // 4. MOUNT FLASH OVERLAY
    // Force a fresh capture for the refraction texture (sync)
    from.forceCaptureRefraction();

    final flash = FlashTransitionComponent(
      texture: from.rainTransition.backgroundTexture,
      onPeakReached: () async {
        // === AT THE PEAK OF THE WHITE FLASH ===

        // Stop Philosophy Runner & Hide components
        await game.primarySequenceRunner.stop();

        // Update Global State to Experience
        game.queuer.queue(event: const SceneEvent.enterExperience());

        // Note: Experience is now state-driven, so we don't need to start a runner.
        // The SceneBloc state change will make MyGame route inputs/updates correctly if needed.
        // But primarily, Experience is an overlay state.

        // Trigger the Hero Entry Animation (Non-scroll dependent)
        // Handled by ExperienceSection.onNewState
        // await to.animateEntry();
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
  Future<void> returnToPhilosophy({
    required ExperienceSection from,
    required PhilosophySection to,
  }) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    game.blockInput();

    // 1. Animate Experience Exit
    await from.exit();

    // 2. Switch State back to Active (Philosophy)
    game.queuer.queue(event: const SceneEvent.onScroll());

    // 3. Resume Philosophy Runner in reverse mode
    // This properly re-enters the last section (Philosophy) at max scroll,
    // calling warmUp() and enterReverse() which restores all components.
    // Unlike start(), resumeReverse() doesn't have the _isActive early-return
    // and correctly positions the scroll at the section's maxScrollExtent.
    await game.primarySequenceRunner.resumeReverse();

    // 4. Unblock
    game.unblockInput();
    _isTransitioning = false;
  }

  /// Triggers camera shake effect on climax
  void _triggerCameraShake({
    required double intensity,
    required double duration,
  }) {
    final totalDuration = (duration * 1000).toInt(); // Convert to milliseconds
    const frames = 10;
    const initialIntensity = 8.0;

    int currentFrame = 0;

    void shakeFrame() {
      if (currentFrame >= frames) return;

      final progress = currentFrame / frames;
      final intensity = initialIntensity * (1.0 - progress);

      game.camera.viewfinder.position.setFrom(
        game.camera.viewfinder.position +
            Vector2(
              (_random.nextDouble() - 0.5) * intensity,
              (_random.nextDouble() - 0.5) * intensity,
            ),
      );

      currentFrame++;

      if (currentFrame < frames) {
        Future.delayed(
          Duration(milliseconds: totalDuration ~/ frames),
          shakeFrame,
        );
      } else {
        // Reset camera to center
        game.camera.viewfinder.position.setZero();
      }
    }

    shakeFrame();
  }
}
