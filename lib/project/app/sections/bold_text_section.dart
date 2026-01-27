import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';

class BoldTextSection implements GameSection {
  final BoldTextRevealComponent boldTextComponent;
  final BeachBackgroundComponent beachBackground;
  final BackgroundRunComponent backgroundRun;
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent interactiveUI;
  Vector2 centerPosition;

  // Internal state
  double _scrollProgress = 0.0;
  // This matches the BoldTextManager's previous _maxHeight
  static const double _maxHeight = 3200.0;

  BoldTextSection({
    required this.boldTextComponent,
    required this.beachBackground,
    required this.backgroundRun,
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.interactiveUI,
    required this.centerPosition,
  });

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onReverseComplete;

  @override
  Future<void> warmUp() async {
    // Only reset if we are effectively at the start
    if (_scrollProgress <= 0) {
      boldTextComponent.opacity = 0.0;
      beachBackground.opacity = 0.0;
      // Ensure titles are visible and centered if we are back at start
      cinematicTitle.opacity = 1.0;
      cinematicSecondaryTitle.opacity = 1.0;
      interactiveUI.opacity = 1.0;

      cinematicTitle.position = centerPosition;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector;

      backgroundRun.opacity = 1.0;
    }
  }

  @override
  Future<void> enter() async {
    boldTextComponent.opacity = 1.0;
    boldTextComponent.position = centerPosition;

    // Ensure background is visible when entering (e.g. from Philosophy)
    backgroundRun.opacity = 1.0;
    // We intentionally start with beach background hidden (0.0)
    // It fades in during the scroll logic
  }

  @override
  Future<void> exit() async {
    // When exiting forward, we typically want to leave things visible
    // for the next section to overlap, OR fade them out.
    // In the legacy manager: "onDeactivate -> opacity = 0.0".
    // But since Philosophy needs the beach background, we likely keep it.
    // We will HIDE the bold text though.
    boldTextComponent.opacity = 0.0;

    // Ensure intro elements are hidden on forward exit
    cinematicTitle.opacity = 0.0;
    cinematicSecondaryTitle.opacity = 0.0;
    interactiveUI.opacity = 0.0;
  }

  @override
  void update(double dt) {
    // No specific time-based updates purely for the section logic
  }

  @override
  void onResize(Vector2 newSize) {
    centerPosition = newSize / 2;
    boldTextComponent.position = centerPosition;
    // Titles will be updated in _updateVisuals call on next scroll or immediately if we wanted to
    // But usually MyGame handles global resize for idle components.
    // If active, handleScroll below will catch up.
  }

  @override
  ScrollResult handleScroll(double delta) {
    final newScroll = _scrollProgress + delta;

    // Check for Overflow (Next Section)
    if (newScroll > _maxHeight) {
      final overflow = newScroll - _maxHeight;
      // We are done.
      onComplete?.call();
      return ScrollOverflow(overflow);
    }

    // Check for Underflow (Previous Section)
    if (newScroll < 0) {
      onReverseComplete?.call();
      return ScrollUnderflow(newScroll);
    }

    // Valid Scroll
    _scrollProgress = newScroll;
    _updateVisuals(_scrollProgress);

    return ScrollConsumed(newScroll);
  }

  void _updateVisuals(double scrollOffset) {
    // 0. Intro Transitions (Titles & UI)
    // Parallax
    if (scrollOffset < ScrollSequenceConfig.titleParallaxEnd) {
      final p = (scrollOffset / ScrollSequenceConfig.titleParallaxEnd).clamp(
        0.0,
        1.0,
      );
      final offset = Vector2.zero()..lerp(GameLayout.parallaxEndVector, p);

      cinematicTitle.position = centerPosition + offset;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector + offset;
    } else {
      // Pin to end state if scrolled past
      final offset = GameLayout.parallaxEndVector;
      cinematicTitle.position = centerPosition + offset;
      cinematicSecondaryTitle.position =
          centerPosition + GameLayout.secTitleOffsetVector + offset;
    }

    // Fade Out Titles
    if (scrollOffset < ScrollSequenceConfig.titleFadeEnd) {
      final p = (scrollOffset / ScrollSequenceConfig.titleFadeEnd).clamp(
        0.0,
        1.0,
      );
      final opacity = 1.0 - p;
      cinematicTitle.opacity = opacity;
      cinematicSecondaryTitle.opacity = opacity;
    } else {
      cinematicTitle.opacity = 0.0;
      cinematicSecondaryTitle.opacity = 0.0;
    }

    // Fade Out UI
    if (scrollOffset < ScrollSequenceConfig.uiFadeEnd) {
      final p = (scrollOffset / ScrollSequenceConfig.uiFadeEnd).clamp(0.0, 1.0);
      interactiveUI.opacity = 1.0 - p;
    } else {
      interactiveUI.opacity = 0.0;
    }

    // 1. Update BoldText progress
    // Legacy Logic: (scrollOffset / 3200).clamp(0,1)
    // wait, legacy controller used `ScrollSequenceConfig.boldTextEnd` which is likely less than 3200
    // Checking controller: (scrollOffset / ScrollSequenceConfig.boldTextEnd)
    // We should stick to config for the text, but section lasts until 3200.
    final textProgress = (scrollOffset / ScrollSequenceConfig.boldTextEnd)
        .clamp(0.0, 1.0);
    boldTextComponent.scrollProgress = textProgress;
    boldTextComponent.position = centerPosition; // Ensure centered

    // 2. Update Beach Background Fade
    // Legacy Logic: Fade in 2700 -> 3200
    const fadeStart = 2700.0;
    const fadeEnd = 3200.0;

    if (scrollOffset < fadeStart) {
      beachBackground.opacity = 0.0;
    } else if (scrollOffset < fadeEnd) {
      final fadeP = (scrollOffset - fadeStart) / (fadeEnd - fadeStart);
      beachBackground.opacity = fadeP.clamp(0.0, 1.0);
    } else {
      beachBackground.opacity = 1.0;
    }
  }
}
