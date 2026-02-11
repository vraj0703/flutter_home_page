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

class PhilosophySection implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final PhilosophyTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final PhilosophyTrailComponent trailComponent;
  final NextButtonComponent nextButton;
  final RainTransitionComponent rainTransition;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;
  double _scrollProgress = 0.0;
  static const double _maxHeight = 3500.0;
  int _currentPhase = 0;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;
  bool _freezeCapture = false;
  bool _isShattering = false;

  PhilosophySection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.nextButton,
    required this.rainTransition,
    required this.screenSize,
    required this.playEntrySound,
    required this.playCompletionSound,
  }) {
    // Bind smoothing callback - legacy controller did this in constructor
    trailComponent.onScrollUpdate = _updateFloatingTitleAnimation;

    // Initialize orchestrator immediately
    orchestrator = BeachSceneOrchestrator(
      background: cloudBackground,
      rainTransition: rainTransition,
    );
    cloudBackground.setOrchestrator(orchestrator);
    _orchestratorInitialized = true;

    // Wire button callbacks
    nextButton.onProgressChange = (progress) {
      if (progress > 0) {
        rainTransition.opacity = 1.0;
      }
      // Delegate everything to orchestrator
      orchestrator.holdProgress = progress;

      // Keep mouse tracking for wiping effect
      rainTransition.updateMousePosition(nextButton.position);

      if (math.Random().nextDouble() < progress * 0.3) {
        trailComponent.game.audio.playSpatialWaterdrop(0.5);
      }
    };

    // If your component doesn't have onReleased,
    nextButton.onReleased = () {
      rainTransition.reset(); // This triggers the lerp back to 0.0
    };

    nextButton.onHoldComplete = () {
      // Hold complete → Delegate to TransitionCoordinator
      if (!_isShattering) {
        _isShattering = true;

        // Delegate entire transition sequence to coordinator
        // We access MyGame to get the Experience Section (now state-driven)
        // casting game reference to MyGame to access specific getters
        final myGame = trailComponent.game;
        final to = myGame.experienceSection;

        // to is verified non-null by getter (late final), but check anyway if logic changes
        myGame.transitionCoordinator.startPhilosophyToExperience(
          from: this,
          to: to,
        );
      } else {}
    };

    rainTransition.onShatterComplete = () {
      // Pre-warm next section if not already done
      if (!_hasWarmedUpNext) {
        onWarmUpNextSection?.call();
        _hasWarmedUpNext = true;
      }

      // Delay 100ms before advancing to next section
      Future.delayed(const Duration(milliseconds: 100), () {
        _triggerComplete();
      });
    };
  }

  void _triggerComplete() {
    onComplete?.call();
  }

  @override
  VoidCallback? onComplete; // To next section

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete; // To previous section

  bool _hasWarmedUpNext = false;

  set freezeCapture(bool value) => _freezeCapture = value;

  @override
  List<Vector2> get snapRegions => [
    // Snap for each card's "Locked" state (align with rangeEnd)
    Vector2(1450, 1550), // Card 0 lock at 1500
    Vector2(1950, 2050), // Card 1 lock at 2000
    Vector2(2450, 2550), // Card 2 lock at 2500
    Vector2(2950, 3050), // Card 3 lock at 3000
    // Final section completion snap
    Vector2(3400, _maxHeight),
  ];

  @override
  void setScrollOffset(double offset) {
    if (offset > _maxHeight) {
      _scrollProgress = _maxHeight;
      _updateVisuals(_scrollProgress);
      // Explicitly DO NOT call onComplete here.
      // We want to force the user to use the "Hold" button to advance.
      // onComplete?.call();
      return;
    }

    if (offset < 0) {
      _scrollProgress = 0;
      _updateVisuals(_scrollProgress);
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

    _updateVisuals(_scrollProgress);
  }

  void _updateVisuals(double offset) {
    trailComponent.setTargetScroll(offset);

    // Position and fade in button after title is visible (scrollOffset > 1000)
    if (offset > 1000) {
      // Position button below title
      nextButton.position = Vector2(
        screenSize.x / 2,
        screenSize.y * 0.4 +
            120, // 120px below title center (title is at 40% screen height)
      );

      // Fade in button over 500px (1000-1500)
      final buttonFadeProgress = ((offset - 1000) / 500.0).clamp(0.0, 1.0);
      nextButton.opacity = buttonFadeProgress;
    } else {
      nextButton.opacity = 0.0;
    }

    // Position rain transition component to cover full screen
    rainTransition.position = Vector2.zero();
    rainTransition.size = screenSize;

    // Changes: Remove scroll-driven rain logic.
    // Rain is now exclusively driven by nextButton.onProgressChange callback (in constructor).
    // This ensures only "holding" the button triggers the rain effect.
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

    // Architectural Visibility: Set components to minimally visible
    // This forces the standard Game Render Loop to process these components
    // and upload their textures/shaders to the GPU on the REAL rendering context.
    // NOTE: Opacity must be > 0.01 because PhilosophyCard skips render if alpha <= 0.01
    cloudBackground.opacity = 0.02;
    trailComponent.opacity = 0.02;
    titleComponent.opacity = 0.02;
    cloudBackground.warmUp();
    await titleComponent.warmUp();

    // Allow the game loop to cycle for a duration (e.g. 10-15 frames @ 60fps)
    // This works because MyGame.onLoad will NO LONGER await this method synchronously.
    await Future.delayed(const Duration(milliseconds: 300));

    // Force Reflection Manager to initialize its texture from the "live" scene
    await orchestrator.reflection.updateReflectionTexture();

    // Capture the valid frame for the transition shader
    forceCaptureRefraction();

    // Hide components again
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    titleComponent.opacity = 0.0;
    nextButton.opacity = 0.0;
    rainTransition.setTarget(0.0);
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _currentPhase = 0;
    _freezeCapture = false;

    // Configure ScrollSystem
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Architectural Visibility: Reveal components
    trailComponent.opacity = 1.0;
    cloudBackground.opacity = 1.0;
    titleComponent.opacity = 1.0; // Make title visible
    nextButton.opacity = 0.0; // Will fade in at scroll > 1000
    rainTransition.setTarget(0.0);

    // Pre-capture refraction to prevent lag on first hover
    // This primes the RainTransitionComponent with a valid texture (sync)
    // REMOVED: forceCaptureRefraction(); // Causes lag on entry. Rely on warmUp() instead.

    // Trigger initial sound (Phase 1)
    _updateVisuals(0.0);
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _currentPhase = 7;
    _freezeCapture = false;

    // Configure ScrollSystem
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setSnapRegions(snapRegions);

    // Set internal state
    setScrollOffset(_maxHeight);

    // Architectural Visibility: Reveal components
    trailComponent.opacity = 1.0;
    cloudBackground.opacity = 1.0;
  }

  @override
  Future<void> exit() async {
    _isActive = false;

    // Strict Visibility Reset - Hide all components
    titleComponent.opacity = 0.0;
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    nextButton.opacity = 0.0;

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

  // Called every frame by game loop (via `update` if we hooked it,
  // but since PhilosophySection isn't a Component, we need to be called by MyGame or similar?
  // Actually, wait. PhilosophySection is a pure class, it doesn't have an `update` called by the Game loop
  // efficiently unless `MyGame` calls `currentSection.update(dt)`.
  // Let's check `MyGame.dart` or `GameSection` interface...
  // `GameSection` has `void update(double dt)`.
  // So we can use that!

  @override
  void update(double dt) {
    // 1. Trail component has its own update(dt) called by game loop
    // But we need to drive the refraction capture here.

    // 2. Real-time Refraction Capture
    // Only capture if we are interacting with the rain
    if ((nextButton.isHovering ||
            rainTransition.currentIntensity > 0.0 ||
            _isShattering) &&
        !_freezeCapture) {
      _frameCounter++;

      // Optimization Logic:
      // If we are SHATTERING or HOLDING, we need full 60fps for smoothness.
      // If we are just idling with some intensity, we can throttle.
      bool needsHighFPS = _isShattering || nextButton.isHovering;

      if (needsHighFPS || _frameCounter % 2 == 0) {
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

    const double scale = 0.5;
    canvas.scale(scale);

    // Render the beach and the text/cards into the off-screen buffer
    cloudBackground.render(canvas);
    trailComponent.render(canvas);

    final picture = recorder.endRecording();

    // logical size * scale
    final int w = (screenSize.x * scale).toInt();
    final int h = (screenSize.y * scale).toInt();

    // toImageSync avoids the raster thread roundtrip (available in Flutter 3.x+)
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

  void _updateFloatingTitleAnimation(double scrollOffset) {
    if (!_isActive) return;

    // Sync Audio with smoothed scroll
    _updateAudio(scrollOffset);

    // 1. Background Fade-in (0 - 500)
    // Only show beach background during Philosophy scroll range
    // Fade in from 0-500px to prevent visibility in logo state
    if (scrollOffset >= 0 && scrollOffset <= 500) {
      final fadeInProgress = (scrollOffset / 500.0).clamp(0.0, 1.0);
      cloudBackground.opacity = fadeInProgress;
    } else if (scrollOffset > 500) {
      cloudBackground.opacity = 1.0;
    } else {
      cloudBackground.opacity = 0.0;
    }

    // 2. Title Animation (500 - 1000)
    // Remapped per user request
    const double titleStart = 500.0;
    const double titleEnd = 1000.0;

    // Pass raw offset to trail (it handles its own 1000-3000 ranges now)
    trailComponent.updateTrailAnimation(scrollOffset);

    // Title Progress
    final titleProgress =
        ((scrollOffset - titleStart) / (titleEnd - titleStart)).clamp(0.0, 1.0);

    if (titleProgress <= 0.0) {
      // Reset position/opacity if below range
      if (scrollOffset < titleStart) {
        titleComponent.opacity = 0.0;
        titleComponent.showReflection = false;
      }
      return;
    }

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
    // Target Y: Align with cards at perspective point (horizon)
    final endY = screenSize.y * 0.4;
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

    // Reset Trail (prevent leaks)
    trailComponent.setTargetScroll(0.0);
    trailComponent.updateTrailAnimation(0.0);
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

    // Stop all specific audio loops if any are running
    // game.audio.stopPhilosophyLoops(); // If such a method existed
  }
}
