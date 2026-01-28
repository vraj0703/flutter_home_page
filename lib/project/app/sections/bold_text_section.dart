import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';

class BoldTextSection implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final BoldTextRevealComponent boldTextComponent;
  final BackgroundRunComponent backgroundRun;
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent logoOverlay;
  Vector2 centerPosition;

  // Internal state
  double _scrollProgress = 0.0;
  static const double _maxHeight = 3000.0;

  static const double titleParallaxExit = 800.0;
  static const double titleFadeEnd = 500.0;
  static const double boldTextEnd = 2800.0;
  static const double uiFadeEnd = 100.0;

  BoldTextSection({
    required this.boldTextComponent,
    required this.backgroundRun,
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.logoOverlay,
    required this.centerPosition,
  });

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onReverseComplete;

  @override
  List<Vector2> get snapRegions => [
    // Snap to Start (Rubber band effect)
    Vector2(-500, 0),
    Vector2(200, 0), // Also snap if slightly positive
    // Snap to Focus (Center)
    Vector2(1200, 1500),
    Vector2(1800, 1500),
  ];

  @override
  void setScrollOffset(double offset) {
    // Check for Overflow (Next Section)
    if (offset > _maxHeight) {
      _scrollProgress = _maxHeight;
      _updateVisuals(_scrollProgress);
      onComplete?.call();
      return;
    }

    // Check for Underflow (Previous Section)
    if (offset < 0) {
      _scrollProgress = 0;
      _updateVisuals(_scrollProgress);
      onReverseComplete?.call();
      return;
    }

    // Valid Scroll
    _scrollProgress = offset;
    _updateVisuals(_scrollProgress);
  }

  @override
  Future<void> warmUp() async {
    // Only reset if we are effectively at the start
    if (_scrollProgress <= 0) {
      boldTextComponent.opacity = 0.0;
      // Ensure titles are visible and centered if we are back at start
      cinematicTitle.opacity = 1.0;
      cinematicSecondaryTitle.opacity = 1.0;
      logoOverlay.opacity = 1.0;

      cinematicTitle.position = centerPosition;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector;

      backgroundRun.opacity = 1.0;
    }
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    // Configure ScrollSystem for this section
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    boldTextComponent.opacity = 1.0;
    boldTextComponent.position = centerPosition;
    backgroundRun.opacity = 1.0;
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    // Configure ScrollSystem for reverse entry
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setSnapRegions(snapRegions);

    // Set internal state to end
    setScrollOffset(_maxHeight);

    boldTextComponent.opacity = 1.0;
    boldTextComponent.position = centerPosition;
    backgroundRun.opacity = 1.0;
  }

  @override
  Future<void> exit() async {
    boldTextComponent.opacity = 0.0;
    cinematicTitle.opacity = 0.0;
    cinematicSecondaryTitle.opacity = 0.0;
    logoOverlay.opacity = 0.0;
    backgroundRun.opacity = 0.0;
  }

  @override
  void update(double dt) {
    // No specific time-based updates purely for the section logic
  }

  @override
  void onResize(Vector2 newSize) {
    centerPosition = newSize / 2;
    boldTextComponent.position = centerPosition;
  }

  @override
  ScrollResult handleScroll(double delta) {
    final newScroll = _scrollProgress + delta;
    setScrollOffset(newScroll);

    if (newScroll > _maxHeight) {
      return ScrollOverflow(newScroll - _maxHeight);
    }
    if (newScroll < 0) {
      return ScrollUnderflow(newScroll);
    }
    return ScrollConsumed(newScroll);
  }

  void _updateVisuals(double scrollOffset) {
    // Fade Out UI
    if (scrollOffset < uiFadeEnd) {
      final p = (scrollOffset / uiFadeEnd).clamp(0.0, 1.0);
      logoOverlay.opacity = 1.0 - p;
    } else {
      logoOverlay.opacity = 0.0;
    }

    // Intro Transitions (Titles & UI)
    // Parallax
    if (scrollOffset <= titleParallaxExit) {
      final p = (scrollOffset / titleParallaxExit).clamp(0.0, 1.0);
      final offset = Vector2.zero()..lerp(GameLayout.parallaxEndVector, p);

      cinematicTitle.position = centerPosition + offset;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector + offset;

      final opacity = 1.0 - p;
      cinematicTitle.opacity = opacity;
      cinematicSecondaryTitle.opacity = opacity;
    } else {
      final offset = GameLayout.parallaxEndVector;
      cinematicTitle.position = centerPosition + offset;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector + offset;
    }

    if (scrollOffset > titleFadeEnd) {
      cinematicTitle.opacity = 0.0;
      cinematicSecondaryTitle.opacity = 0.0;
    }

    final textProgress = (scrollOffset / boldTextEnd).clamp(0.0, 1.0);
    boldTextComponent.scrollProgress = textProgress;
    boldTextComponent.position = centerPosition;
  }
}
