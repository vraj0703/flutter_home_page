import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

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

    // Sustain Phase: Wait for the user to "feel" the full rain intensity
    final config = ScrollSequenceConfig.philosophyTransition;
    await Future.delayed(Duration(milliseconds: config.sustainDurationMs));

    // 3. VISUAL CLIMAX (Shatter + Lightning)
    from.rainTransition.triggerShatter();
    from.orchestrator.lightning.triggerFlash(1.0);
    game.audio.playTransitionClimax();
    // Master Epic: Haptics at exact moment of shatter
    HapticFeedback.heavyImpact();
    _triggerCameraShake(intensity: 12.0, duration: 0.5);

    // Wait for "Visible Crack" phase before flashing white
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
