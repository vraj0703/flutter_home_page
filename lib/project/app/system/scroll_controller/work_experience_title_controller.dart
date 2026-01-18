import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

/// Controls the "Work Experience" title scroll animation:
/// Phase 1: Rise from bottom with spring physics (3300-3650)
/// Phase 2: Hold at center with subtle pulse (3650-3900)
/// Phase 3: Ascend to top with fade out (3900-4100)
class WorkExperienceTitleController implements ScrollObserver {
  final WorkExperienceTitleComponent component;
  final double screenHeight;
  final Vector2 centerPosition;

  // Curves for natural motion
  static const springCurve = SpringCurve(
    mass: 0.9,
    stiffness: 160.0,
    damping: 14.0,
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

    // Calculate text height estimate for positioning
    const textHeightEstimate = 100.0;

    double yOffset = 0.0;
    double opacity = 0.0;
    double scale = 1.0;

    if (scrollOffset < entranceStart) {
      // Before entrance: hidden below
      yOffset = screenHeight + 200;
      opacity = 0.0;
      scale = 0.95;
    } else if (scrollOffset < entranceEnd) {
      // Phase 1: ENTRANCE - Rise from bottom with spring physics
      final t = ((scrollOffset - entranceStart) / entranceDuration).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);

      // Position: bottom → center
      yOffset = (screenHeight + 200) * (1.0 - curvedT);

      // Opacity: fade in smoothly
      opacity = exponentialEaseOut.transform(t);

      // Scale: 0.95 → 1.0 for depth
      scale = 0.95 + (0.05 * exponentialEaseOut.transform(t));
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
      // Phase 3: EXIT - Ascend to top with acceleration
      final t = ((scrollOffset - exitStart) / exitDuration).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);

      // Position: center → top
      yOffset = -(textHeightEstimate + 300) * curvedT;

      // Opacity: fade out in last portion
      if (t < 0.5) {
        opacity = 1.0;
      } else {
        final fadeT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
        opacity = 1.0 - exponentialEaseOut.transform(fadeT);
      }

      // Scale: subtle increase 1.0 → 1.05 (moving toward viewer)
      scale = 1.0 + (0.05 * curvedT);
    } else {
      // After exit: hidden above
      yOffset = -(textHeightEstimate + 300);
      opacity = 0.0;
      scale = 1.05;
    }

    // Apply transformations
    component.position = centerPosition + Vector2(0, yOffset);
    component.opacity = opacity;
    component.scale = Vector2.all(scale);
  }
}
