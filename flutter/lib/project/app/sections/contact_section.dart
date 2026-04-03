import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:web/web.dart' as web;

import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/transition/transition_coordinator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_scene_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/back_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/white_overlay_component.dart';

class PhilosophySection extends Component implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final PhilosophyTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final PhilosophyTrailComponent trailComponent;
  final BackButtonComponent backButton;
  final WhiteOverlayComponent whiteOverlay;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;
  final GameAudioSystem _audioSystem;

  // ignore: unused_field — retained for future use (e.g., transition back with flash effect)
  final TransitionCoordinator _transitionCoordinator;

  double get _maxHeight => trailComponent.maxScrollExtent;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;
  bool _freezeCapture = false;

  double _animTime = 0.0;

  // --- Contact Section State ---
  bool _isActive = false;

  /// Entrance animation progress (0 = hidden, 1 = fully visible)
  double _entranceProgress = 0.0;
  static const double _entranceDuration = 2.0; // seconds to fully reveal

  /// Ambient lightning timer
  double _ambientLightningTimer = 0.0;
  static const double _ambientLightningMinInterval = 6.0;
  static const double _ambientLightningMaxInterval = 15.0;
  double _nextLightningAt = 8.0;
  final math.Random _rng = math.Random();

  PhilosophySection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.backButton,
    required this.whiteOverlay,
    required this.screenSize,
    required this.playEntrySound,
    required this.playCompletionSound,
    required GameAudioSystem audioSystem,
    required TransitionCoordinator transitionCoordinator,
  }) : _audioSystem = audioSystem,
       _transitionCoordinator = transitionCoordinator {
    orchestrator = BeachSceneOrchestrator(background: cloudBackground);
    cloudBackground.setOrchestrator(orchestrator);
    _orchestratorInitialized = true;

    // Wire back button to navigate back to React
    backButton.onTap = navigateBackToReact;

    backButton.opacity = 0.0;
  }

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete;

  set freezeCapture(bool value) => _freezeCapture = value;

  @override
  List<Vector2> get snapRegions => [];

  /// Scroll is not used for card reveal in Contact mode.
  /// We keep setScrollOffset for interface compliance but it does nothing meaningful.
  @override
  void setScrollOffset(double offset) {
    // No-op: Contact section is not scroll-driven
  }

  void triggerLightningEffect() {
    cloudBackground.triggerLightningEffect();
  }

  @override
  void prepareGhostRender() {
    _resetVisuals();
    cloudBackground.opacity = 0.02;
    trailComponent.opacity = 0.02;
    titleComponent.opacity = 0.02;
  }

  @override
  Future<void> warmUp() async {
    cloudBackground.warmUp();
    await titleComponent.warmUp();
  }

  @override
  Future<void> finalizeGhostRender() async {
    await orchestrator.reflection.updateReflectionTexture();
    forceCaptureRefraction();

    // Strict Visibility Reset - Hide all components
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    titleComponent.opacity = 0.0;
    whiteOverlay.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _isActive = true;
    _freezeCapture = false;
    _entranceProgress = 0.0;
    _ambientLightningTimer = 0.0;
    _nextLightningAt = _rng.nextDouble() * 4.0 + 4.0; // first strike 4-8s in

    // Disable scroll bounds — no scrolling needed
    scrollSystem.resetScroll(0.0);
    scrollSystem.setBounds(0.0, 0.0);
    scrollSystem.setSnapRegions([]);

    // Start with white overlay bridge, then fade it out
    whiteOverlay.opacity = 1.0;
    // Back button starts hidden, will fade in with entrance animation
    backButton.opacity = 0.0;

    // Play entry sound
    playEntrySound();
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    // Same as enter for Contact section
    await enter(scrollSystem);
  }

  @override
  Future<void> exit() async {
    _isActive = false;

    // Strict Visibility Reset - Hide all components
    titleComponent.opacity = 0.0;
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    backButton.opacity = 0.0;
    whiteOverlay.opacity = 0.0;

    // Clean up reflection resources to prevent memory leaks
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;

    // Stop background capture loop
    _freezeCapture = true;

    // Reset shader uniforms and state flags
    _cleanupPhilosophyComponents();

    // Reset visuals to initial state
    _resetVisuals();
  }

  int _frameCounter = 0;

  @override
  void update(double dt) {
    if (!_isActive) return;

    _animTime += dt;

    // --- Entrance Animation ---
    // Smoothly reveal all components over _entranceDuration seconds
    if (_entranceProgress < 1.0) {
      _entranceProgress = (_entranceProgress + dt / _entranceDuration).clamp(
        0.0,
        1.0,
      );
      _applyEntranceAnimation(_entranceProgress);
    }

    // --- Ambient Lightning ---
    _ambientLightningTimer += dt;
    if (_ambientLightningTimer >= _nextLightningAt) {
      _ambientLightningTimer = 0.0;
      _nextLightningAt =
          _ambientLightningMinInterval +
          _rng.nextDouble() *
              (_ambientLightningMaxInterval - _ambientLightningMinInterval);

      // Trigger a gentle lightning flash
      orchestrator.lightning.triggerFlash(
        0.15,
      ); // Low intensity = distant thunder
      _audioSystem.playSpatialThunder(0.15);
    }

    // --- Refraction Capture (for rain visual) ---
    if (!_freezeCapture && _entranceProgress > 0.3) {
      _frameCounter++;
      if (_frameCounter % PhilosophySectionLayout.lowFpsThrottle == 0) {
        _captureRefractionFrame();
      }
    }

    // --- Title breathe animation when fully visible ---
    if (_entranceProgress >= 1.0) {
      final breathe =
          math.sin(_animTime * PhilosophySectionLayout.breatheFrequency) *
          PhilosophySectionLayout.breatheAmplitude;
      final baseScale = PhilosophySectionLayout.titleSettleScale;
      titleComponent.scale = Vector2.all(baseScale + baseScale * breathe);
    }

    // --- Register reflection targets ---
    if (_orchestratorInitialized && _entranceProgress > 0.5) {
      orchestrator.reflection.registerTarget(titleComponent);
      for (final card in trailComponent.cards) {
        orchestrator.reflection.registerTarget(card);
      }
    }
  }

  /// Drives the entrance animation: fades in background, title, trail, and cards together.
  void _applyEntranceAnimation(double progress) {
    // Phase 1 (0.0 - 0.3): White overlay fades out, background fades in
    final overlayFade = (1.0 - (progress / 0.3)).clamp(0.0, 1.0);
    whiteOverlay.opacity = overlayFade;

    final bgProgress = (progress / 0.4).clamp(0.0, 1.0);
    final bgCurve = Curves.easeOutCubic.transform(bgProgress);
    cloudBackground.opacity = bgCurve;
    cloudBackground.scale = Vector2.all(
      PhilosophySectionLayout.backgroundOverscan,
    );
    cloudBackground.position = Vector2(
      -(screenSize.x * PhilosophySectionLayout.backgroundOverscanMargin),
      -(bgCurve * PhilosophySectionLayout.backgroundYShift),
    );

    // Set water level for shader
    cloudBackground.setWaterLevel(
      screenSize.y * PhilosophySectionLayout.waterLevelRatio,
    );
    cloudBackground.setScrollProgress(bgCurve * 0.5); // Midway sky gradient

    // Phase 2 (0.2 - 0.6): Title fades in and floats up
    if (progress > 0.2) {
      final titleProgress = ((progress - 0.2) / 0.4).clamp(0.0, 1.0);
      final titleCurve = Curves.elasticOut.transform(titleProgress);

      titleComponent.opacity = titleProgress;
      titleComponent.showReflection = true;
      titleComponent.waterLineY =
          screenSize.y * PhilosophySectionLayout.waterLineYRatio;

      final startY = screenSize.y * PhilosophySectionLayout.titleStartYRatio;
      final endY = screenSize.y * PhilosophySectionLayout.titleEndYRatio;
      final currentY = startY + (endY - startY) * titleCurve;
      titleComponent.position = Vector2(screenSize.x / 2, currentY);

      // Scale animation
      double targetScale;
      if (titleProgress < PhilosophySectionLayout.titleOvershootThreshold) {
        targetScale = lerpDouble(
          PhilosophySectionLayout.titleInitialScale,
          PhilosophySectionLayout.titleOvershootScale,
          titleProgress / PhilosophySectionLayout.titleOvershootThreshold,
        )!;
      } else {
        final settleProgress =
            (titleProgress - PhilosophySectionLayout.titleOvershootThreshold) /
            (1.0 - PhilosophySectionLayout.titleOvershootThreshold);
        targetScale = lerpDouble(
          PhilosophySectionLayout.titleOvershootScale,
          PhilosophySectionLayout.titleSettleScale,
          settleProgress,
        )!;
      }
      titleComponent.scale = Vector2.all(targetScale);
    } else {
      titleComponent.opacity = 0.0;
    }

    // Phase 3 (0.3 - 0.8): Trail and cards appear
    if (progress > 0.3) {
      final trailProgress = ((progress - 0.3) / 0.5).clamp(0.0, 1.0);
      final trailCurve = Curves.easeOutCubic.transform(trailProgress);

      trailComponent.opacity = trailCurve;
      trailComponent.scale = Vector2.all(
        PhilosophySectionLayout.trailInitialScale +
            (PhilosophySectionLayout.trailScaleRange * trailCurve),
      );
      trailComponent.position = Vector2(
        0,
        (1.0 - trailCurve) * PhilosophySectionLayout.trailInitialY,
      );

      // Force cards to their final "locked" positions by setting a high scroll offset
      // This makes all 4 cards visible at their target positions
      final cardScroll = 2700.0 * trailCurve; // Max lock point for all cards
      trailComponent.setTargetScroll(cardScroll);
      trailComponent.updateTrailAnimation(cardScroll);
    } else {
      trailComponent.opacity = 0.0;
    }

    // Phase 4 (0.7 - 1.0): Back button fades in
    if (progress > 0.7) {
      final btnProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      backButton.opacity = btnProgress;
      backButton.position = Vector2(80.0, screenSize.y - 50.0);
    } else {
      backButton.opacity = 0.0;
    }
  }

  void forceCaptureRefraction() {
    _captureRefractionFrame();
  }

  void _captureRefractionFrame() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    const double scale = PhilosophySectionLayout.refractionScale;
    canvas.scale(scale);

    cloudBackground.render(canvas);
    trailComponent.render(canvas);
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    if (titleComponent.isLoaded && titleComponent.opacity == 0.0) {
      titleComponent.position = Vector2(
        screenSize.x / 2,
        screenSize.y * PhilosophySectionLayout.titleStartYRatio,
      );
    }
  }

  @override
  ScrollResult handleScroll(double delta) {
    // Contact section does not consume scroll.
    // Any scroll is ignored.
    return ScrollConsumed(0.0);
  }

  void _resetVisuals() {
    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(
      PhilosophySectionLayout.titleInitialScale,
    );
    titleComponent.position = Vector2(
      screenSize.x / 2,
      screenSize.y * PhilosophySectionLayout.titleStartYRatio,
    );
    titleComponent.showReflection = false;

    trailComponent.opacity = 0.0;
    trailComponent.setTargetScroll(0.0);
    trailComponent.updateTrailAnimation(0.0);

    backButton.opacity = 0.0;
  }

  void _cleanupPhilosophyComponents() {
    _freezeCapture = false;
  }

  /// Sends a message to the parent React frame to navigate back.
  /// Fades out the Contact section before sending the handoff.
  void navigateBackToReact() {
    if (!_isActive) return;
    _isActive = false; // Prevent double-taps

    if (kIsWeb) {
      try {
        final msg = <String, String>{'type': 'goto-react'}.jsify();
        web.window.parent?.postMessage(msg, '*'.toJS);
        debugPrint('[Flutter Contact] postMessage sent: goto-react');
      } catch (e) {
        debugPrint('[Flutter Contact] postMessage error: $e');
      }
    }
  }

  @override
  void dispose() {
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;
  }
}
