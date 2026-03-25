import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';

import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/transition/transition_coordinator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_scene_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/next_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/rain_transition_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/white_overlay_component.dart';

class PhilosophySection extends Component implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final PhilosophyTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final PhilosophyTrailComponent trailComponent;
  final NextButtonComponent nextButton;
  final RainTransitionComponent rainTransition;
  final WhiteOverlayComponent whiteOverlay;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;
  final GameAudioSystem _audioSystem;
  final TransitionCoordinator _transitionCoordinator;
  double _scrollProgress = 0.0;

  double get _maxHeight => trailComponent.maxScrollExtent;
  int _currentPhase = 0;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;
  bool _freezeCapture = false;
  bool _isShattering = false;

  bool _buttonVisible = false;
  double _buttonOpacity = 0.0;
  double _animTime = 0.0;

  /// Countdown timer for deferred section completion, driven by the game loop.
  /// Set to > 0 when shatter completes; ticks down in [update] and fires
  /// [_triggerComplete] when it reaches zero. Reset in [exit] to prevent
  /// stale callbacks on disposed sections.
  double _pendingCompleteCountdown = -1.0;

  PhilosophySection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.nextButton,
    required this.rainTransition,
    required this.whiteOverlay,
    required this.screenSize,
    required this.playEntrySound,
    required this.playCompletionSound,
    required GameAudioSystem audioSystem,
    required TransitionCoordinator transitionCoordinator,
  })  : _audioSystem = audioSystem,
        _transitionCoordinator = transitionCoordinator {
    orchestrator = BeachSceneOrchestrator(
      background: cloudBackground,
      rainTransition: rainTransition,
    );
    cloudBackground.setOrchestrator(orchestrator);
    _orchestratorInitialized = true;

    nextButton.onProgressChange = (progress) {
      if (progress > 0) {
        rainTransition.opacity = 1.0;
      }
      orchestrator.holdProgress = progress;
      rainTransition.updateMousePosition(nextButton.position);

      if (math.Random().nextDouble() < progress * 0.3) {
        _audioSystem.playSpatialWaterdrop(0.5);
      }
    };

    nextButton.onReleased = () {
      rainTransition.reset();
    };

    // Initialize visibility
    nextButton.opacity = 0.0;

    nextButton.onHoldComplete = () {
      if (!_isShattering) {
        _isShattering = true;
        _transitionCoordinator.startPhilosophyToExperience(from: this);
      }
    };

    rainTransition.onShatterComplete = () {
      if (!_hasWarmedUpNext) {
        onWarmUpNextSection?.call();
        _hasWarmedUpNext = true;
      }

      // Schedule completion via game-loop timer instead of fire-and-forget Future.delayed.
      // Cleared in exit() to prevent stale callbacks on disposed sections.
      _pendingCompleteCountdown = 0.1; // 100ms
    };
  }

  void _triggerComplete() {
    onComplete?.call();
  }

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete;

  bool _hasWarmedUpNext = false;
  bool _hasScrolledPastEntry = false;

  set freezeCapture(bool value) => _freezeCapture = value;

  @override
  List<Vector2> get snapRegions => [
    // Snap for each card's "Locked" state (align with rangeEnd)
    Vector2(1450, 1550), // Card 0 lock at 1500
    Vector2(1950, 2050), // Card 1 lock at 2000
    Vector2(2450, 2550), // Card 2 lock at 2500
    Vector2(2650, 2750), // Card 3 lock at 2700
    Vector2(_maxHeight - 100, _maxHeight + 100), // Snap to end
  ];

  @override
  void setScrollOffset(double offset) {
    if (!_isActive) return;

    // Button visibility: show when last card settles, hide on ANY reverse scroll
    if (offset < _scrollProgress && _buttonVisible) {
      // Reverse scroll detected — hide button immediately
      _buttonVisible = false;
    } else if (offset >= PhilosophySectionLayout.buttonShowThreshold && !_buttonVisible && !_isShattering) {
      // All cards settled — show button
      _buttonVisible = true;
    }

    // Log significant scroll milestones (every 500px)

    if (offset > _maxHeight) {
      _scrollProgress = _maxHeight;
      _applyScrollEffects(_scrollProgress);
      return;
    }

    if (offset < 0) {
      _scrollProgress = 0;
      _applyScrollEffects(_scrollProgress);
      onReverseComplete?.call();
      return;
    }

    _scrollProgress = offset;

    if (_scrollProgress > _maxHeight - PhilosophySectionLayout.warmUpLookahead && !_hasWarmedUpNext) {
      onWarmUpNextSection?.call();
      _hasWarmedUpNext = true;
    }

    cloudBackground.setScrollProgress(_scrollProgress / _maxHeight);

    _applyScrollEffects(_scrollProgress);
  }

  void triggerLightningEffect() {
    cloudBackground.triggerLightningEffect();
  }

  void _applyScrollEffects(double offset) {


    if (!_hasScrolledPastEntry && offset > PhilosophySectionLayout.entryScrollThreshold) {
      _hasScrolledPastEntry = true;
    }

    if (_hasScrolledPastEntry) {
      whiteOverlay.opacity = 0.0;
    } else {
      final overlayProgress =
          (offset / PhilosophySectionLayout.whiteOverlayFadeDistance).clamp(0.0, 1.0);
      whiteOverlay.opacity = 1.0 - overlayProgress;
    }

    double entryProgress =
        (offset / PhilosophySectionLayout.backgroundFadeDistance).clamp(0.0, 1.0);
    final entryCurve = Curves.easeOutCubic.transform(entryProgress);
    cloudBackground.opacity = entryCurve;
    cloudBackground.scale = Vector2.all(PhilosophySectionLayout.backgroundOverscan);
    cloudBackground.position = Vector2(
      -(screenSize.x * PhilosophySectionLayout.backgroundOverscanMargin),
      -(entryCurve * PhilosophySectionLayout.backgroundYShift),
    );

    if (offset > PhilosophySectionLayout.trailAppearOffset) {
      double trailProgress =
          ((offset - PhilosophySectionLayout.trailAppearOffset) / PhilosophySectionLayout.trailFadeDistance)
              .clamp(0.0, 1.0);
      final trailCurve = Curves.easeOutCubic.transform(trailProgress);

      trailComponent.opacity = trailCurve;
      trailComponent.scale = Vector2.all(
        PhilosophySectionLayout.trailInitialScale + (PhilosophySectionLayout.trailScaleRange * trailCurve),
      );
      trailComponent.position =
          Vector2(0, (1.0 - trailCurve) * PhilosophySectionLayout.trailInitialY);
    } else {
      trailComponent.opacity = 0.0;
      trailComponent.scale = Vector2.all(PhilosophySectionLayout.trailInitialScale);
      trailComponent.position = Vector2(0, PhilosophySectionLayout.trailInitialY);
    }

    if (offset > PhilosophySectionLayout.titleStartOffset) {
      final titleProgress = ((offset - PhilosophySectionLayout.titleStartOffset) /
              (PhilosophySectionLayout.titleEndOffset - PhilosophySectionLayout.titleStartOffset))
          .clamp(0.0, 1.0);

      if (titleProgress > 0) {
        _updateFloatingTitleAnimation(titleProgress);
      } else {
        titleComponent.opacity = 0.0;
      }
    } else {
      titleComponent.opacity = 0.0;
    }

    trailComponent.setTargetScroll(offset);
    trailComponent.updateTrailAnimation(offset);

    _updateAudio(offset);
    nextButton.position =
        Vector2(screenSize.x / 2, screenSize.y * PhilosophySectionLayout.buttonYRatio);
  }

  void _updateAudio(double offset) {
    if (!_isActive) return;

    // Each audio phase spans one audioPhaseWidth (500px).
    // Phase 0 is silent; phases 1-6 map to musical notes Do-Sol.
    const pw = PhilosophySectionLayout.audioPhaseWidth;
    int newPhase = 0;
    if (offset < pw) {
      newPhase = 1; // 0-500: Do
    } else if (offset < pw * 2) {
      newPhase = 2; // 500-1000: Re
    } else if (offset < pw * 3) {
      newPhase = 3; // 1000-1500: Mi
    } else if (offset < pw * 4) {
      newPhase = 4; // 1500-2000: Fa
    } else if (offset < pw * 5) {
      newPhase = 5; // 2000-2500: Si
    } else if (offset < pw * 6) {
      newPhase = 6; // 2500-3000: Sol
    } else {
      newPhase = 7;
    }

    if (newPhase > _currentPhase) {
      for (int i = _currentPhase + 1; i <= newPhase; i++) {
        if (i == 2) continue;
        _audioQueue.add(i);
      }
      _currentPhase = newPhase;
    } else if (newPhase < _currentPhase) {
      for (int i = _currentPhase - 1; i >= newPhase; i--) {
        if (i == 2) continue;
        _audioQueue.add(i);
      }
      _currentPhase = newPhase;
    }
  }

  final List<int> _audioQueue = [];
  double _timeSinceLastNote = 0.0;
  static const double _noteInterval = 0.2; // 200ms spacing

  void _processAudioQueue(double dt) {
    if (_audioQueue.isEmpty) return;

    _timeSinceLastNote += dt;
    if (_timeSinceLastNote >= _noteInterval) {
      final phase = _audioQueue.removeAt(0);
      _playPhaseSound(phase);
      _timeSinceLastNote = 0.0;
    }
  }

  void _playPhaseSound(int phase) {
    switch (phase) {
      case 1:
        playEntrySound(); // Do
        break;
      case 2:
        break;
      case 3:
        _audioSystem.playTrailCardSound(0); // Card 1: Re
        break;
      case 4:
        _audioSystem.playTrailCardSound(1); // Card 2: Mi
        break;
      case 5:
        _audioSystem.playTrailCardSound(2); // Card 3: Fa
        break;
      case 6:
        _audioSystem.playTrailCardSound(3); // Card 4: Si
        break;
    }
  }

  bool _isActive = false;

  @override
  void prepareGhostRender() {
    if (_scrollProgress <= 0) {
      _resetVisuals();
    }
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
    nextButton.opacity = 0.0;
    rainTransition.setTarget(0.0);
    whiteOverlay.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _hasScrolledPastEntry = false; // Reset for new entry
    _currentPhase = 0;
    _freezeCapture = false;
    _buttonVisible = false;
    _buttonOpacity = 0.0;
    // Allow small overshoot (-10 to max+10) to trigger exit navigation logic
    scrollSystem.resetScroll(0.0);
    scrollSystem.setBounds(-10.0, _maxHeight + 10.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Ensure all components start hidden
    nextButton.opacity = 0.0;
    rainTransition.opacity = 0.0;
    rainTransition.setTarget(0.0);
    whiteOverlay.opacity = 1.0; // Bridge from Bold Text flash

    // Apply scroll effects at 0.0 to set all initial opacities
    _applyScrollEffects(0.0);
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _hasScrolledPastEntry = true; // Don't show white overlay on reverse entry
    _currentPhase = 7;
    _freezeCapture = false;
    _buttonVisible = true;
    _buttonOpacity = 1.0;

    // Configure ScrollSystem
    // Configure ScrollSystem with overshoot margin
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setBounds(-10.0, _maxHeight + 10.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Use _applyScrollEffects to calculate correct visibility
    // instead of manually setting opacities (which caused leaking)
    _applyScrollEffects(_maxHeight);
  }

  @override
  Future<void> exit() async {
    _isActive = false;
    _pendingCompleteCountdown = -1.0; // Cancel any pending completion timer

    // Strict Visibility Reset - Hide all components
    titleComponent.opacity = 0.0;
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    nextButton.opacity = 0.0;
    whiteOverlay.opacity = 0.0;
    rainTransition.opacity = 0.0;
    _buttonVisible = false;
    _buttonOpacity = 0.0;

    // Dispose resources to prevent GPU leaks
    rainTransition.opacity = 0.0;
    rainTransition.disposeResources();

    // Clean up reflection resources to prevent memory leaks
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0; // Stop thunder simulation

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

    // Deferred completion timer (replaces fire-and-forget Future.delayed)
    if (_pendingCompleteCountdown > 0) {
      _pendingCompleteCountdown -= dt;
      if (_pendingCompleteCountdown <= 0) {
        _pendingCompleteCountdown = -1.0;
        _triggerComplete();
      }
    }

    // Process audio queue (Moved from scroll loop to time loop)
    _processAudioQueue(dt);

    // Smooth button fade (decoupled from scroll)

    final targetButtonOpacity = _buttonVisible ? 1.0 : 0.0;
    if ((_buttonOpacity - targetButtonOpacity).abs() > 0.01) {
      final speed = _buttonVisible
          ? PhilosophySectionLayout.buttonFadeInSpeed
          : PhilosophySectionLayout.buttonFadeOutSpeed;
      _buttonOpacity = lerpDouble(
        _buttonOpacity,
        targetButtonOpacity,
        dt * speed,
      )!;
    } else {
      _buttonOpacity = targetButtonOpacity;
    }
    nextButton.opacity = _buttonOpacity;
    nextButton.scale = Vector2.all(
      PhilosophySectionLayout.buttonMinScale + ((1.0 - PhilosophySectionLayout.buttonMinScale) * _buttonOpacity),
    );

    if ((nextButton.isHovering ||
            rainTransition.currentIntensity > 0.0 ||
            _isShattering) &&
        !_freezeCapture) {
      _frameCounter++;

      bool needsHighFPS = _isShattering || nextButton.isHovering;

      // Throttle capture to balance GPU cost vs visual quality
      int throttle = needsHighFPS
          ? PhilosophySectionLayout.highFpsThrottle
          : PhilosophySectionLayout.lowFpsThrottle;

      if (_frameCounter % throttle == 0) {
        _captureRefractionFrame();
      }
    }
  }

  void forceCaptureRefraction() {
    _captureRefractionFrame();
  }

  /// Captures a low-res snapshot of the beach scene for the rain refraction shader.
  ///
  /// Uses [PictureRecorder.toImageSync] to avoid the 1-frame raster-thread lag
  /// that `toImage` would introduce, which causes visible tearing in the rain
  /// distortion. The low resolution ([PhilosophySectionLayout.refractionScale])
  /// keeps the UI-thread blocking cost minimal (~2-4ms on modern hardware).
  void _captureRefractionFrame() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    const double scale = PhilosophySectionLayout.refractionScale;
    canvas.scale(scale);

    // Render the beach and the text/cards into the off-screen buffer
    cloudBackground.render(canvas);
    trailComponent.render(canvas);

    final picture = recorder.endRecording();

    // logical size * scale
    final int w = (screenSize.x * scale).toInt();
    final int h = (screenSize.y * scale).toInt();

    // toImageSync avoids the raster thread roundtrip (available in Flutter 3.x+)
    // RISK: blocking UI thread. Kept low res (0.2) to mitigate.
    try {
      final img = picture.toImageSync(w, h);
      rainTransition.updateBackgroundTexture(img);
    } catch (e) {
      // Silently handle disposal errors
    } finally {
      picture.dispose(); // Prevent GPU memory leak
    }
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
    final newScroll = _scrollProgress + delta;
    setScrollOffset(newScroll);

    // Check Overflow
    if (newScroll > _maxHeight) {
      return ScrollOverflow(newScroll - _maxHeight);
    }

    // Check Underflow
    if (newScroll < 0) {
      return ScrollUnderflow(newScroll);
    }

    return ScrollConsumed(newScroll);
  }

  // Consolidated into _applyScrollEffects, this now just handles the specific Title Visuals
  void _updateFloatingTitleAnimation(double titleProgress) {
    if (!_isActive) return;


    // Enable reflection
    titleComponent.showReflection = true;
    titleComponent.waterLineY = screenSize.y * PhilosophySectionLayout.waterLineYRatio;

    // Easing - elastic for premium feel
    final eased = Curves.elasticOut.transform(titleProgress);

    // Fade in 0->1
    titleComponent.opacity = titleProgress;

    // Scale up with overshoot: initial → overshoot → settle
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

    // Idle breathe animation when fully visible
    if (titleProgress >= 1.0) {
      final breathe =
          math.sin(_animTime * PhilosophySectionLayout.breatheFrequency) * PhilosophySectionLayout.breatheAmplitude;
      targetScale += targetScale * breathe;
    }

    titleComponent.scale = Vector2.all(targetScale);

    // Move Up
    final startY = screenSize.y * PhilosophySectionLayout.titleStartYRatio;
    final endY = screenSize.y * PhilosophySectionLayout.titleEndYRatio;
    final currentY = startY + (endY - startY) * eased;

    // Sway (subtle)
    final sway = math.sin(titleProgress * math.pi * 2) *
        PhilosophySectionLayout.swayAmount *
        (1 - eased);
    titleComponent.position = Vector2(screenSize.x / 2 + sway, currentY);

    // Reflection Registration
    if (_orchestratorInitialized) {
      orchestrator.reflection.registerTarget(titleComponent);
      for (final card in trailComponent.cards) {
        orchestrator.reflection.registerTarget(card);
      }
    }

    // Set water level for shader (procedural ocean boundary)
    cloudBackground.setWaterLevel(screenSize.y * PhilosophySectionLayout.waterLevelRatio);
  }

  void _resetVisuals() {

    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(PhilosophySectionLayout.titleInitialScale);
    titleComponent.position = Vector2(
      screenSize.x / 2,
      screenSize.y * PhilosophySectionLayout.titleStartYRatio,
    );
    titleComponent.showReflection = false;
    _currentPhase = 0;
    _buttonVisible = false;
    _buttonOpacity = 0.0;

    // Reset Trail (prevent leaks)
    trailComponent.opacity = 0.0;
    trailComponent.setTargetScroll(0.0);
    trailComponent.updateTrailAnimation(0.0);

    // Reset button
    nextButton.opacity = 0.0;
    nextButton.scale = Vector2.all(PhilosophySectionLayout.buttonMinScale);
  }

  /// Cleanup Philosophy components and reset shader uniforms
  void _cleanupPhilosophyComponents() {
    // Reset shader uniforms to initial state
    rainTransition.setTarget(0.0);
    rainTransition.setShatterProgress(0.0);

    // Reset state flags
    _freezeCapture = false;
    _isShattering = false;
    _hasWarmedUpNext = false;
  }

  @override
  void dispose() {
    // Strict Cleanup of Heavy Resources
    rainTransition.disposeResources();
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;
  }
}
