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
import 'package:flutter_home_page/project/app/views/components/contact/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/beach_scene_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/back_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/contact/white_overlay_component.dart';
import 'package:flutter_home_page/project/app/system/registration/game_component_factory.dart';

class ContactSection extends Component implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final ContactTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final ContactTrailComponent trailComponent;
  final BackButtonComponent backButton;
  final WhiteOverlayComponent whiteOverlay;
  final LogoComponent logoComponent;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;
  final GameAudioSystem _audioSystem;

  // ignore: unused_field — retained for future use (e.g., transition back with flash effect)
  final TransitionCoordinator _transitionCoordinator;

  final ContactTextButton homeButton;
  final ContactIconButton audioToggle;

  double get _maxHeight => trailComponent.maxScrollExtent;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;

  double _animTime = 0.0;

  // --- Contact Section State ---
  bool _isActive = false;

  /// Whether the first reflection capture has been done post-entrance
  bool _reflectionCaptured = false;

  /// Entrance animation progress (0 = hidden, 1 = fully visible)
  double _entranceProgress = 0.0;
  static const double _entranceDuration = 2.0; // seconds to fully reveal

  /// Ambient lightning timer
  double _ambientLightningTimer = 0.0;
  static const double _ambientLightningMinInterval = 6.0;
  static const double _ambientLightningMaxInterval = 15.0;
  double _nextLightningAt = 8.0;
  final math.Random _rng = math.Random();

  ContactSection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.backButton,
    required this.whiteOverlay,
    required this.logoComponent,
    required this.homeButton,
    required this.audioToggle,
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

    // Wire Gallery button to navigate to React gallery
    backButton.onTap = navigateBackToReact;
    backButton.opacity = 0.0;
  }

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete;

  // freezeCapture removed — was only used by dead _captureRefractionFrame code

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
    // Skip reflection during ghost render — it blocks GPU for 200-500ms
    // Reflection will be captured ONCE after entrance animation completes

    // Strict Visibility Reset - Hide all components
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    titleComponent.opacity = 0.0;
    whiteOverlay.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _isActive = true;
    _entranceProgress = 0.0;
    _ambientLightningTimer = 0.0;
    _reflectionCaptured = false;
    _nextLightningAt = _rng.nextDouble() * 4.0 + 4.0; // first strike 4-8s in

    // Pause reflection updates during entrance — prevents GPU blocking
    orchestrator.reflection.paused = true;

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
    logoComponent.scale = Vector2.zero();
    logoComponent.priority = 10; // Reset to default zLogo
    homeButton.opacity = 0.0;
    audioToggle.opacity = 0.0;

    // Stop all contact audio on exit
    _audioSystem.stopBoldTextAudio();

    // Clean up reflection resources to prevent memory leaks
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;

    // Stop background capture loop

    // Reset shader uniforms and state flags
    _cleanupContactComponents();

    // Reset visuals to initial state
    _resetVisuals();
  }

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

    // --- Enable reflection ONCE after entrance completes ---
    if (_entranceProgress >= 1.0 && !_reflectionCaptured) {
      _reflectionCaptured = true;
      // Un-pause reflection and capture once now that content is stable
      orchestrator.reflection.paused = false;
      orchestrator.reflection.updateReflectionTexture();
    }

    // --- Title breathe animation when fully visible ---
    if (_entranceProgress >= 1.0) {
      final breathe =
          math.sin(_animTime * ContactSectionLayout.breatheFrequency) *
          ContactSectionLayout.breatheAmplitude;
      final baseScale = ContactSectionLayout.titleSettleScale;
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
      ContactSectionLayout.backgroundOverscan,
    );
    cloudBackground.position = Vector2(
      -(screenSize.x * ContactSectionLayout.backgroundOverscanMargin),
      -(bgCurve * ContactSectionLayout.backgroundYShift),
    );

    // Set water level for shader
    cloudBackground.setWaterLevel(
      screenSize.y * ContactSectionLayout.waterLevelRatio,
    );
    cloudBackground.setScrollProgress(bgCurve * 0.5); // Midway sky gradient

    // Phase 2 (0.2 - 0.6): Title fades in and floats up
    if (progress > 0.2) {
      final titleProgress = ((progress - 0.2) / 0.4).clamp(0.0, 1.0);
      final titleCurve = Curves.elasticOut.transform(titleProgress);

      titleComponent.opacity = titleProgress;
      titleComponent.showReflection = true;
      titleComponent.waterLineY =
          screenSize.y * ContactSectionLayout.waterLineYRatio;

      final startY = screenSize.y * ContactSectionLayout.titleStartYRatio;
      final endY = screenSize.y * ContactSectionLayout.titleEndYRatio;
      final currentY = startY + (endY - startY) * titleCurve;
      titleComponent.position = Vector2(screenSize.x / 2, currentY);

      // Scale animation
      double targetScale;
      if (titleProgress < ContactSectionLayout.titleOvershootThreshold) {
        targetScale = lerpDouble(
          ContactSectionLayout.titleInitialScale,
          ContactSectionLayout.titleOvershootScale,
          titleProgress / ContactSectionLayout.titleOvershootThreshold,
        )!;
      } else {
        final settleProgress =
            (titleProgress - ContactSectionLayout.titleOvershootThreshold) /
            (1.0 - ContactSectionLayout.titleOvershootThreshold);
        targetScale = lerpDouble(
          ContactSectionLayout.titleOvershootScale,
          ContactSectionLayout.titleSettleScale,
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
        ContactSectionLayout.trailInitialScale +
            (ContactSectionLayout.trailScaleRange * trailCurve),
      );
      trailComponent.position = Vector2(
        0,
        (1.0 - trailCurve) * ContactSectionLayout.trailInitialY,
      );

      // Force cards to their final "locked" positions by setting a high scroll offset
      // This makes all 4 cards visible at their target positions
      final cardScroll = 2700.0 * trailCurve; // Max lock point for all cards
      trailComponent.setTargetScroll(cardScroll);
      trailComponent.updateTrailAnimation(cardScroll);
    } else {
      trailComponent.opacity = 0.0;
    }

    // Phase 4 (0.7 - 1.0): Buttons + logo fade in
    if (progress > 0.7) {
      final btnProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

      // Gallery button — bottom left
      backButton.opacity = btnProgress;
      backButton.position = Vector2(80.0, screenSize.y - 50.0);

      // Logo — top left, small, z-above contact content
      logoComponent.priority = 50;
      logoComponent.position = Vector2(50.0, 50.0);
      logoComponent.scale = Vector2.all(0.15 * btnProgress);

      // Home + Audio buttons — bottom right
      homeButton.opacity = btnProgress;
      homeButton.position = Vector2(screenSize.x - 160.0, screenSize.y - 50.0);
      audioToggle.opacity = btnProgress;
      audioToggle.position = Vector2(screenSize.x - 50.0, screenSize.y - 50.0);
    } else {
      backButton.opacity = 0.0;
      logoComponent.scale = Vector2.zero();
      homeButton.opacity = 0.0;
      audioToggle.opacity = 0.0;
    }
  }

  // Removed: _captureRefractionFrame() was rendering to a PictureRecorder
  // that was never finalized (endRecording() never called) — pure wasted GPU work.

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    if (titleComponent.isLoaded && titleComponent.opacity == 0.0) {
      titleComponent.position = Vector2(
        screenSize.x / 2,
        screenSize.y * ContactSectionLayout.titleStartYRatio,
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
      ContactSectionLayout.titleInitialScale,
    );
    titleComponent.position = Vector2(
      screenSize.x / 2,
      screenSize.y * ContactSectionLayout.titleStartYRatio,
    );
    titleComponent.showReflection = false;

    trailComponent.opacity = 0.0;
    trailComponent.setTargetScroll(0.0);
    trailComponent.updateTrailAnimation(0.0);

    backButton.opacity = 0.0;
    logoComponent.scale = Vector2.zero();
    homeButton.opacity = 0.0;
    audioToggle.opacity = 0.0;
  }

  void _cleanupContactComponents() {
  }

  /// Sends a message to the parent React frame to navigate back.
  /// Fades out the Contact section before sending the handoff.
  void navigateBackToReact() {
    if (!_isActive) return;
    _isActive = false; // Prevent double-taps

    if (kIsWeb) {
      try {
        final msg = <String, String>{'type': 'flutter-handoff'}.jsify();
        web.window.parent?.postMessage(msg, web.window.origin.toJS);
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
