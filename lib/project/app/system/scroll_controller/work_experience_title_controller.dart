import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

/// Controls the "Work Experience" title with FULL PAGE PARALLAX:
/// Phase 1: Rise from far below with parallax (3600-4000)
/// Phase 2: Hold at center with subtle pulse (4000-4300)
/// Phase 3: Ascend far above with parallax (4300-4650)
/// NO OVERLAPS - Clean transitions before and after
class WorkExperienceTitleController implements ScrollObserver {
  final WorkExperienceTitleComponent component;
  final double screenHeight;
  final Vector2 centerPosition;

  // Smooth curves for fluid motion
  static const springCurve = SpringCurve(
    mass: 1.0,
    stiffness: 140.0,
    damping: 15.0,
  );
  static const exponentialEaseOut = ExponentialEaseOut();

  WorkExperienceTitleController({
    required this.component,
    required this.screenHeight,
    required this.centerPosition,
  });

  @override
  void onScroll(double scrollOffset) {
    // Config constants
    const entranceStart = ScrollSequenceConfig.workExpTitleEntranceStart;
    const entranceDuration = ScrollSequenceConfig.workExpTitleEntranceDuration;
    final entranceEnd = ScrollSequenceConfig.workExpTitleEntranceEnd;

    const holdStart = ScrollSequenceConfig.workExpTitleHoldStart;
    const holdDuration = ScrollSequenceConfig.workExpTitleHoldDuration;
    final holdEnd = ScrollSequenceConfig.workExpTitleHoldEnd;

    const exitStart = ScrollSequenceConfig.workExpTitleExitStart;
    const exitDuration = ScrollSequenceConfig.workExpTitleExitDuration;
    final exitEnd = ScrollSequenceConfig.workExpTitleExitEnd;

    double yOffset = 0.0;
    double opacity = 0.0;
    double scale = 1.0;
    double rotation = 0.0; // Subtle rotation wobble

    if (scrollOffset < entranceStart) {
      // Before entrance: hidden FAR below (full page parallax distance)
      yOffset = screenHeight * 1.5; // Start 1.5x screen height below
      opacity = 0.0;
      scale = 0.9; // Start smaller
    } else if (scrollOffset < entranceEnd) {
      // Phase 1: ENTRANCE - Full page parallax from far below
      final t = ((scrollOffset - entranceStart) / entranceDuration).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);

      // Position: Far below → center (full page parallax)
      yOffset = (screenHeight * 1.5) * (1.0 - curvedT);

      // Opacity: fade in smoothly
      opacity = exponentialEaseOut.transform(t);

      // Scale: 0.9 → 1.0 for depth and parallax effect
      scale = 0.9 + (0.1 * exponentialEaseOut.transform(t));

      // Subtle rotation wobble during entrance (±0.5° = ±0.0087 radians)
      rotation = 0.0087 * math.sin(t * math.pi * 3) * (1.0 - t);
    } else if (scrollOffset < holdEnd) {
      // Phase 2: HOLD - Stay at center with subtle pulse
      yOffset = 0.0;
      opacity = 1.0;

      // Pulse animation during hold
      final holdProgress = ((scrollOffset - holdStart) / holdDuration).clamp(
        0.0,
        1.0,
      );
      component.applyPulse(holdProgress);
      scale = component.scale.x; // Use the pulse scale
    } else if (scrollOffset < exitEnd) {
      // Phase 3: EXIT - Full page parallax to far above
      final t = ((scrollOffset - exitStart) / exitDuration).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);

      // Position: center → far above (full page parallax)
      yOffset = -(screenHeight * 1.5) * curvedT;

      // Opacity: fade out smoothly
      opacity = 1.0 - exponentialEaseOut.transform(t);

      // Scale: 1.0 → 1.1 (moving toward viewer then away)
      scale = 1.0 + (0.1 * curvedT);
    } else {
      // After exit: hidden FAR above
      yOffset = -(screenHeight * 1.5);
      opacity = 0.0;
      scale = 1.1;
    }

    // Apply transformations
    component.position = centerPosition + Vector2(0, yOffset);
    component.opacity = opacity;
    component.scale = Vector2.all(scale);
    component.angle = rotation;
  }
}
