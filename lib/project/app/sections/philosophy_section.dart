import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';

class PhilosophySection implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final PhilosophyTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final PhilosophyTrailComponent trailComponent;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;

  // Internal State
  double _scrollProgress = 0.0;
  static const double _maxHeight = 3500.0;

  // Audio Phase Tracking
  int _currentPhase = 0;

  PhilosophySection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.screenSize,
    required this.playEntrySound,
    required this.playCompletionSound,
  }) {
    // Bind smoothing callback - legacy controller did this in constructor
    trailComponent.onScrollUpdate = _updateFloatingTitleAnimation;
  }

  @override
  VoidCallback? onComplete; // To next section

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete; // To previous section

  bool _hasWarmedUpNext = false;

  @override
  List<Vector2> get snapRegions => [
    // Snap to End
    Vector2(3000, _maxHeight),
  ];

  @override
  void setScrollOffset(double offset) {
    if (offset > _maxHeight) {
      _scrollProgress = _maxHeight;
      _updateVisuals(_scrollProgress);
      onComplete?.call();
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

    _updateVisuals(_scrollProgress);
  }

  void _updateVisuals(double offset) {
    trailComponent.setTargetScroll(offset);
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
          trailComponent.game.playTrailCardSound(0); // Mi
          break;
        case 4:
          trailComponent.game.playTrailCardSound(1); // Fa
          break;
        case 5:
          trailComponent.game.playTrailCardSound(2); // Si
          break;
        case 6:
          trailComponent.game.playTrailCardSound(3); // Sol
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
    // Pre-complile shader
    cloudBackground.warmUp();
    titleComponent.warmUp();

    // Architectural Visibility: Ensure hidden after warmup
    cloudBackground.opacity = 0.0;
    titleComponent.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _currentPhase = 0; // Reset phase tracker

    // Configure ScrollSystem
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Architectural Visibility: Reveal components
    trailComponent.opacity = 1.0;
    cloudBackground.opacity = 1.0;

    // Trigger initial sound (Phase 1)
    _updateVisuals(0.0);
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _hasWarmedUpNext = false;
    _isActive = true;
    _currentPhase = 7;

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
    // Architectural Visibility: Hide everything
    _resetVisuals();
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
  }

  @override
  void update(double dt) {
    // Trail component has its own update(dt) called by game loop
    // No specific section-controller updates needed here
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    // We might need to re-calculate positions if currently visible,
    // but _updateFloatingTitleAnimation recalculates based on screenSize anyway whenever it runs.
    // If we are idle/reset, we should update reset position.
    if (titleComponent.opacity == 0.0) {
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

    // 1. Background Entrance (0 - 500)
    // Handled by generic opacity, but maybe enforce full visibility here?
    cloudBackground.opacity = 1.0;

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
    titleComponent.waterLineY = screenSize.y * 0.55;

    // Easing
    final eased = Curves.easeOutQuad.transform(titleProgress);

    // Visuals
    // Fade in 0->1
    titleComponent.opacity = titleProgress;

    // Scale up
    final scale = 0.1 + (eased * 0.9);
    titleComponent.scale = Vector2.all(scale);

    // Move Up
    final startY = screenSize.y * 0.7;
    final endY = screenSize.y * 0.15;
    final currentY = startY + (endY - startY) * eased;

    // Sway (subtle)
    final swayAmount = 20.0;
    final sway = sin(titleProgress * pi * 2) * swayAmount * (1 - eased);
    titleComponent.position = Vector2(screenSize.x / 2 + sway, currentY);

    // Reflection Update
    final reflectionOpacity = titleComponent.opacity;

    cloudBackground.setTextReflection(
      texture: titleComponent.textTexture,
      textX: titleComponent.position.x,
      textY: currentY,
      waterY: screenSize.y * 0.47,
      textOpacity: reflectionOpacity,
      textScale: titleComponent.scale.x * 1.5,
      centerX: titleComponent.x,
    );
  }

  void _resetVisuals() {
    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(0.1);
    titleComponent.position = Vector2(screenSize.x / 2, screenSize.y * 0.7);
    titleComponent.showReflection = false;
    _currentPhase = 0;

    // Reset Trail (prevent leaks)
    trailComponent.updateTrailAnimation(0.0);

    cloudBackground.setTextReflection(
      texture: null,
      textX: 0,
      textY: 0,
      waterY: 0,
      textOpacity: 0,
      textScale: 0,
      centerX: 0,
    );
  }
}
