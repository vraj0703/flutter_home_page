import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';

import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';

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
  bool _hasPlayedEntrySound = false; // "Re" sound at balloon top
  bool _canReplayEntrySound =
      false; // Logic for re-triggering sound on scroll back

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
  @override
  VoidCallback? onReverseComplete; // To previous section

  @override
  List<Vector2> get snapRegions => [
    // Snap to End
    Vector2(1400, _maxHeight),
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
    _updateVisuals(_scrollProgress);
  }

  void _updateVisuals(double offset) {
    // Logic for re-playing entry sound if user scrolls back to start
    if (offset > 50.0) {
      _canReplayEntrySound = true;
    } else if (offset < 10.0 && _canReplayEntrySound) {
      playEntrySound();
      _canReplayEntrySound = false;
    }

    // Update Components
    trailComponent.setTargetScroll(offset);
    _updateFloatingTitleAnimation(offset);
  }

  bool _isActive = false;

  @override
  Future<void> warmUp() async {
    if (_scrollProgress <= 0) {
      _resetVisuals();
    }
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _isActive = true;

    // Configure ScrollSystem
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    trailComponent.opacity = 1.0;
    // Hide default background when Philosophy enters

    // Cloud background should be visible from previous section (BoldText)
    // We play the generic entry sound if this is fresh entry?
    // Legacy manager played sound onActivate.
    playEntrySound();
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _isActive = true;

    // Configure ScrollSystem
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setSnapRegions(snapRegions);

    // Set internal state
    setScrollOffset(_maxHeight);

    trailComponent.opacity = 1.0;
    playEntrySound();
  }

  @override
  Future<void> exit() async {
    _isActive = false;
    // When done, we might hide things or let them linger?
    // Legacy: onDeactivate calling reset().
    _resetVisuals();
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

    // Ported from PhilosophyPageController

    // 1. Balloon Title Animation (0 - 800px)
    const titleDuration = 800.0;
    final titleProgress = (scrollOffset / titleDuration).clamp(0.0, 1.0);

    // 2. Trail Cards Animation (Starts at 800px)
    if (scrollOffset > titleDuration) {
      const trailDuration = 2600.0;
      final trailProgress = ((scrollOffset - titleDuration) / trailDuration)
          .clamp(0.0, 1.0);
      trailComponent.updateTrailAnimation(trailProgress);
    } else {
      trailComponent.updateTrailAnimation(0.0);
    }

    if (titleProgress <= 0.0) {
      // _resetVisuals(); // Careful not to hard reset if we just dipped slightly below
      return;
    }

    // Enable reflection
    titleComponent.showReflection = true;
    titleComponent.waterLineY = screenSize.y * 0.55;

    // Easing
    final eased = Curves.easeOutQuad.transform(titleProgress);

    // Visuals
    titleComponent.opacity = (titleProgress * 1.5).clamp(0.0, 1.0);

    final scale = 0.1 + (eased * 0.9);
    titleComponent.scale = Vector2.all(scale);

    final startY = screenSize.y * 0.7;
    final endY = screenSize.y * 0.15;
    final currentY = startY + (endY - startY) * eased;

    // Sway
    final swayAmount = 20.0;
    final sway = sin(titleProgress * pi * 2) * swayAmount * (1 - eased);
    titleComponent.position = Vector2(screenSize.x / 2 + sway, currentY);

    // Reflection Update
    final reflectionOpacity = (titleProgress >= 1.0)
        ? titleComponent.opacity
        : 0.0;

    cloudBackground.setTextReflection(
      texture: titleComponent.textTexture,
      textX: titleComponent.position.x,
      textY: currentY,
      waterY: screenSize.y * 0.47,
      textOpacity: reflectionOpacity,
      textScale: titleComponent.scale.x * 1.5,
      centerX: titleComponent.x,
    );

    // Sound Trigger (The "Re" sound when balloon hits top)
    // Note: This matches the old controller's "onComplete"
    if (titleProgress >= 1.0 && !_hasPlayedEntrySound) {
      playCompletionSound(); // Confusing naming in legacy, triggers at top of balloon
      _hasPlayedEntrySound = true;
    } else if (titleProgress < 1.0) {
      _hasPlayedEntrySound =
          false; // Reset so it can play again if we scroll down and up
    }
  }

  void _resetVisuals() {
    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(0.1);
    titleComponent.position = Vector2(screenSize.x / 2, screenSize.y * 0.7);
    titleComponent.showReflection = false;
    _hasPlayedEntrySound = false;

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
