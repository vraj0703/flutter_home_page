import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';

import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_scene_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/next_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/rain_transition_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/white_overlay_component.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';

class PhilosophySection implements GameSection {
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
  double _scrollProgress = 0.0;
  double get _maxHeight => trailComponent.maxScrollExtent;
  int _currentPhase = 0;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;
  bool _freezeCapture = false;
  bool _isShattering = false;

  // Button state (decoupled from scroll)
  bool _buttonVisible = false;
  double _buttonOpacity = 0.0;

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
  }) {
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
        trailComponent.game.audio.playSpatialWaterdrop(0.5);
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
        final myGame = trailComponent.game;
        myGame.transitionCoordinator.startPhilosophyToExperience(from: this);
      } else {}
    };

    rainTransition.onShatterComplete = () {
      if (!_hasWarmedUpNext) {
        onWarmUpNextSection?.call();
        _hasWarmedUpNext = true;
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        _triggerComplete();
      });
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
      if (_buttonVisible) {
        LoggerUtil.log(
          'PhilosophySection',
          'Reverse Scroll Detected (Offset: ${offset.toStringAsFixed(1)}) -> Hiding Button',
        );
      }
      _buttonVisible = false;
    } else if (offset >= 2700 && !_buttonVisible && !_isShattering) {
      // All cards settled — show button
      LoggerUtil.log(
        'PhilosophySection',
        'Scroll Target Reached (Offset: ${offset.toStringAsFixed(1)}) -> Showing Button',
      );
      _buttonVisible = true;
    }

    // Log significant scroll milestones (every 500px)
    if ((offset ~/ 500) != (_scrollProgress ~/ 500)) {
      LoggerUtil.log(
        'PhilosophySection',
        'Scroll Milestone: ${offset.toStringAsFixed(1)}',
      );
    }

    if (offset > _maxHeight) {
      if (offset > _maxHeight + 500 && _frameCounter % 60 == 0) {
        LoggerUtil.log(
          'PhilosophySection',
          'OVERSHOOT: Offset ${offset.toStringAsFixed(1)} > Max ${_maxHeight.toStringAsFixed(1)}',
        );
      }
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

    // Warm up next section if nearing completion
    if (_scrollProgress > _maxHeight - 500 && !_hasWarmedUpNext) {
      onWarmUpNextSection?.call();
      _hasWarmedUpNext = true;
    }

    // Update shader scroll progress for sky gradient (0.0-1.0)
    cloudBackground.setScrollProgress(_scrollProgress / _maxHeight);

    _applyScrollEffects(_scrollProgress);
  }

  void triggerLightningEffect() {
    cloudBackground.triggerLightningEffect();
  }

  void _applyScrollEffects(double offset) {
    _updateAudio(offset);

    // 0. White Overlay
    // Logic: Only show during initial entry. Once user scrolls deep (> 200), disable it.
    // This prevents "White Screen" when scrolling back up.
    if (!_hasScrolledPastEntry && offset > 200) {
      _hasScrolledPastEntry = true;
    }

    if (_hasScrolledPastEntry) {
      whiteOverlay.opacity = 0.0;
    } else {
      final overlayProgress = (offset / 150.0).clamp(0.0, 1.0);
      whiteOverlay.opacity = 1.0 - overlayProgress;
    }

    // 1. Scene Entry (0 - 500) - "Curtain Reveal"
    // Instead of linear scale, use Parallax + Ease
    double entryProgress = (offset / 500.0).clamp(0.0, 1.0);
    final entryCurve = Curves.easeOutCubic.transform(entryProgress);

    // Background: Parallax (slower) + Fade
    // Moves from 0 to -100 (Upwards) to prevent top gap
    // Requires scale > 1.0 (handled here or in component)
    cloudBackground.opacity = entryCurve;
    cloudBackground.scale = Vector2.all(1.2); // 20% Overscan
    // Center X (offset by 10%), Move Y (0 -> -100)
    cloudBackground.position = Vector2(
      -(screenSize.x * 0.1),
      -(entryCurve * 100),
    );

    // Content Container (Trail): aligned with card rangeStart (1000px)
    if (offset > 1000) {
      double trailProgress = ((offset - 1000) / 200.0).clamp(0.0, 1.0);
      final trailCurve = Curves.easeOutCubic.transform(trailProgress);

      trailComponent.opacity = trailCurve;
      trailComponent.scale = Vector2.all(0.95 + (0.05 * trailCurve));
      trailComponent.position = Vector2(0, (1.0 - trailCurve) * 200);
    } else {
      trailComponent.opacity = 0.0;
      trailComponent.scale = Vector2.all(0.95);
      trailComponent.position = Vector2(0, 200);
    }

    // 2. Title Animation (500 - 1000)
    if (offset > 500) {
      // Remapped per user request
      const double titleStart = 500.0;
      const double titleEnd = 1000.0;

      // Title Progress
      final titleProgress = ((offset - titleStart) / (titleEnd - titleStart))
          .clamp(0.0, 1.0);

      if (titleProgress > 0) {
        _updateFloatingTitleAnimation(titleProgress);
      } else {
        titleComponent.opacity = 0.0;
      }
    } else {
      titleComponent.opacity = 0.0;
    }

    // 3. Trail (Cards) Animation
    trailComponent.setTargetScroll(offset);
    trailComponent.updateTrailAnimation(offset);

    // 4. Button Position (visibility handled in setScrollOffset)
    nextButton.position = Vector2(screenSize.x / 2, screenSize.y * 0.8);
  }

  void _updateAudio(double offset) {
    if (!_isActive) return;

    int newPhase = 0;
    if (offset < 500) {
      newPhase = 1; // 0-500: Do
    } else if (offset < 1000) {
      newPhase = 2; // 500-1000: Re
    } else if (offset < 1500) {
      newPhase = 3; // 1000-1500: Mi
    } else if (offset < 2000) {
      newPhase = 4; // 1500-2000: Fa
    } else if (offset < 2500) {
      newPhase = 5; // 2000-2500: Si
    } else if (offset < 3000) {
      newPhase = 6; // 2500-3000: Sol
    } else {
      newPhase = 7;
    }

    if (newPhase != _currentPhase) {
      _currentPhase = newPhase;
      // Play sound for the NEW phase we just ALIGHTED upon
      switch (newPhase) {
        case 1:
          playEntrySound(); // Do
          break;
        case 2:
          playCompletionSound(); // Re
          break;
        case 3:
          trailComponent.game.audio.playTrailCardSound(0); // Mi
          break;
        case 4:
          trailComponent.game.audio.playTrailCardSound(1); // Fa
          break;
        case 5:
          trailComponent.game.audio.playTrailCardSound(2); // Si
          break;
        case 6:
          trailComponent.game.audio.playTrailCardSound(3); // Sol
          break;
      }
    }
  }

  bool _isActive = false;

  @override
  Future<void> warmUp() async {
    if (_scrollProgress <= 0) {
      _resetVisuals();
    }

    cloudBackground.opacity = 0.02;
    trailComponent.opacity = 0.02;
    titleComponent.opacity = 0.02;
    cloudBackground.warmUp();
    await titleComponent.warmUp();
    await Future.delayed(const Duration(milliseconds: 300));
    await orchestrator.reflection.updateReflectionTexture();
    forceCaptureRefraction();

    // Hide components again
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    titleComponent.opacity = 0.0;
    nextButton.opacity = 0.0;
    rainTransition.setTarget(0.0);
    whiteOverlay.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    LoggerUtil.log('PhilosophySection', 'ENTER -> Activating Section');
    _hasWarmedUpNext = false;
    _isActive = true;
    _hasScrolledPastEntry = false; // Reset for new entry
    _currentPhase = 0;
    _freezeCapture = false;
    _buttonVisible = false;
    _buttonOpacity = 0.0;
    LoggerUtil.log(
      'PhilosophySection',
      'ENTER -> Max Height: ${_maxHeight.toStringAsFixed(1)}',
    );
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
    LoggerUtil.log('PhilosophySection', 'EXIT -> Deactivating Section');
    _isActive = false;

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

    // Smooth button fade (decoupled from scroll)
    final targetButtonOpacity = _buttonVisible ? 1.0 : 0.0;
    if ((_buttonOpacity - targetButtonOpacity).abs() > 0.01) {
      // Fast fade-out (8.0), slower fade-in (3.0) for cinematic feel
      final speed = _buttonVisible ? 3.0 : 8.0;
      _buttonOpacity = lerpDouble(
        _buttonOpacity,
        targetButtonOpacity,
        dt * speed,
      )!;
    } else {
      _buttonOpacity = targetButtonOpacity;
    }
    nextButton.opacity = _buttonOpacity;
    nextButton.scale = Vector2.all(0.5 + (0.5 * _buttonOpacity));

    if ((nextButton.isHovering ||
            rainTransition.currentIntensity > 0.0 ||
            _isShattering) &&
        !_freezeCapture) {
      _frameCounter++;

      bool needsHighFPS = _isShattering || nextButton.isHovering;

      // Throttle capture:
      // High FPS needed? Capture every 2nd frame (30fps effective)
      // Low FPS needed? Capture every 3rd frame (20fps effective)
      int throttle = needsHighFPS ? 2 : 3;

      if (_frameCounter % throttle == 0) {
        _captureRefractionFrame();
      }
    }
  }

  void forceCaptureRefraction() {
    _captureRefractionFrame();
  }

  void _captureRefractionFrame() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Performance: Reduced from 0.5 to 0.2 for mobile optimization.
    // Rain distortion doesn't need high-res crispness, just color data.
    const double scale = 0.2;
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
      titleComponent.position = Vector2(screenSize.x / 2, screenSize.y * 0.7);
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
    titleComponent.waterLineY =
        screenSize.y * 0.55; // Tighter reflection spacing

    // Easing - elastic for premium feel
    final eased = Curves.elasticOut.transform(titleProgress);

    // Visuals
    // Fade in 0->1
    titleComponent.opacity = titleProgress;

    // Scale up with overshoot: 0.1 → 0.8 (overshoot) → 0.6 (settle)
    double targetScale;
    if (titleProgress < 0.7) {
      // Overshoot phase
      targetScale = lerpDouble(0.1, 0.8, titleProgress / 0.7)!;
    } else {
      // Settle phase
      final settleProgress = (titleProgress - 0.7) / 0.3;
      targetScale = lerpDouble(0.8, 0.6, settleProgress)!;
    }

    // Idle breathe animation (±2% when fully visible)
    if (titleProgress >= 1.0) {
      final breathe =
          math.sin(DateTime.now().millisecondsSinceEpoch / 1000.0 * 0.5) * 0.02;
      targetScale += targetScale * breathe;
    }

    titleComponent.scale = Vector2.all(targetScale);

    // Move Up
    final startY = screenSize.y * 0.7;
    // Target Y: Just above center cards (Cards top at ~0.2)
    final endY = screenSize.y * 0.15;
    final currentY = startY + (endY - startY) * eased;

    // Sway (subtle)
    final swayAmount = 20.0;
    final sway =
        math.sin(titleProgress * math.pi * 2) * swayAmount * (1 - eased);
    titleComponent.position = Vector2(screenSize.x / 2 + sway, currentY);

    // Reflection Registration
    if (_orchestratorInitialized) {
      // Register text component
      orchestrator.reflection.registerTarget(titleComponent);

      // Register all cards from trail
      for (final card in trailComponent.cards) {
        orchestrator.reflection.registerTarget(card);
      }
    }

    // Set water level for shader (procedural ocean boundary)
    cloudBackground.setWaterLevel(screenSize.y * 0.72);
  }

  void _resetVisuals() {
    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(0.1);
    titleComponent.position = Vector2(screenSize.x / 2, screenSize.y * 0.7);
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
    nextButton.scale = Vector2.all(0.5);
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
