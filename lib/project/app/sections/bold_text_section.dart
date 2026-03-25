import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

class BoldTextSection implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final BoldTextRevealComponent boldTextComponent;
  final BackgroundRunComponent backgroundRun;
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent logoOverlay;
  Vector2 centerPosition;

  // Cached mutable vectors to prevent GC allocations on high refresh rates
  final Vector2 _tempTitleOffset = Vector2.zero();

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
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete;

  bool _hasWarmedUpNext = false;
  bool _isActive = false;

  @override
  List<Vector2> get snapRegions => [
    // 1. Snap to Title (Start)
    // Range: -500 to 500 -> Snaps to 0
    Vector2(-500, 0),
    Vector2(500, 0),

    // 2. Snap to Bold Text Focus (Center)
    // Range: 1000 to 2000 -> Snaps to 1500 (ScrollSequenceConfig.boldTextFocus)
    // This creates a strong "magnetic" zone around the fully visible text.
    Vector2(1000, ScrollSequenceConfig.boldTextFocus),
    Vector2(2000, ScrollSequenceConfig.boldTextFocus),
  ];

  @override
  void prepareGhostRender() {
    boldTextComponent.opacity = 0.001;
    cinematicTitle.opacity = 0.001;
    cinematicSecondaryTitle.opacity = 0.001;
    cinematicTitle.position = centerPosition;
    cinematicSecondaryTitle.position =
        centerPosition + GameLayout.secTitleOffsetVector;
  }

  @override
  Future<void> warmUp() async {
    // Pre-load logic if needed
  }

  @override
  Future<void> finalizeGhostRender() async {
    boldTextComponent.opacity = 0.0;
    cinematicTitle.opacity = 0.0;
    cinematicSecondaryTitle.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _isActive = true;
    _hasWarmedUpNext = false;
    // Configure ScrollSystem for this section
    scrollSystem.resetScroll(0.0);
    scrollSystem.setSnapRegions(snapRegions);

    // Architectural Visibility: Reveal all components
    boldTextComponent.opacity = 1.0;
    cinematicTitle.reset();
    cinematicSecondaryTitle.opacity = 1.0;
    backgroundRun.opacity = 1.0;

    logoOverlay.opacity = 1.0;

    boldTextComponent.position = centerPosition;
  }

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

    // Warm up next section if nearing completion
    if (_scrollProgress > _maxHeight - 500 && !_hasWarmedUpNext) {
      onWarmUpNextSection?.call();
      _hasWarmedUpNext = true;
    }

    _updateVisuals(_scrollProgress);
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _isActive = true;
    _hasWarmedUpNext = false;
    // Configure ScrollSystem for reverse entry
    scrollSystem.resetScroll(_maxHeight);
    scrollSystem.setSnapRegions(snapRegions);
    setScrollOffset(_maxHeight);
    boldTextComponent.opacity = 1.0;
    cinematicTitle.reset();
    cinematicSecondaryTitle.opacity = 1.0;
    logoOverlay.opacity = 1.0;
    backgroundRun.opacity = 1.0;
    boldTextComponent.position = centerPosition;
  }

  @override
  Future<void> exit() async {
    _isActive = false;
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
    _updateVisuals(_scrollProgress);
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
      if (_isActive) logoOverlay.opacity = 1.0 - p;
    } else {
      if (_isActive) logoOverlay.opacity = 0.0;
    }

    // Intro Transitions (Titles & UI)
    // Parallax
    if (scrollOffset <= titleParallaxExit) {
      final p = (scrollOffset / titleParallaxExit).clamp(0.0, 1.0);
      
      _tempTitleOffset.setFrom(GameLayout.parallaxEndVector);
      _tempTitleOffset.scale(p);

      cinematicTitle.position
        ..setFrom(centerPosition)
        ..add(_tempTitleOffset);
      cinematicSecondaryTitle.position
        ..setFrom(centerPosition)
        ..add(GameLayout.secTitleOffsetVector)
        ..add(_tempTitleOffset);

      if (_isActive) {
        final opacity = 1.0 - p;
        cinematicTitle.opacity = opacity;
        cinematicSecondaryTitle.opacity = opacity;
      }
    } else {
      cinematicTitle.position
        ..setFrom(centerPosition)
        ..add(GameLayout.parallaxEndVector);
      cinematicSecondaryTitle.position
        ..setFrom(centerPosition)
        ..add(GameLayout.secTitleOffsetVector)
        ..add(GameLayout.parallaxEndVector);
    }

    if (scrollOffset > titleFadeEnd && _isActive) {
      cinematicTitle.opacity = 0.0;
      cinematicSecondaryTitle.opacity = 0.0;
    }

    final textProgress = (scrollOffset / boldTextEnd).clamp(0.0, 2.0);
    boldTextComponent.scrollProgress = textProgress;
    boldTextComponent.position = centerPosition;
  }

  @override
  void dispose() {
    // No heavy resources to dispose currently
  }
}
