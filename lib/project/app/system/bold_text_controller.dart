import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class BoldTextController implements ScrollObserver {
  final BoldTextRevealComponent component;
  final double screenWidth;
  final Vector2 centerPosition;

  BoldTextController({
    required this.component,
    required this.screenWidth,
    required this.centerPosition,
  });

  @override
  void onScroll(double scrollOffset) {
    // Faster scroll timing, exits to the right for continuity

    // Phase 0: Hidden/Wait (0 -> 400)
    // Phase 1: Enter (400 -> 900) - Smooth entrance
    // Phase 2: Hold (900 -> 1400) - Sufficient viewing time
    // Phase 3: Exit (1400 -> 1700) - Exit to right

    const exponentialEaseOut = ExponentialEaseOut();

    double offsetX = -screenWidth; // Default off-screen left
    double offsetY = 0;

    if (scrollOffset < 400) {
      // Waiting Phase
      offsetX = -screenWidth;
    } else if (scrollOffset < 900) {
      // Enter Phase (400 -> 900) - Smooth entry from left
      final t = ((scrollOffset - 400) / 500).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      offsetX = -screenWidth + (screenWidth * curvedT);
      offsetY = 0;
    } else if (scrollOffset < 1400) {
      // Hold Phase (900 -> 1400) - Center position
      offsetX = 0;
      offsetY = 0;
    } else {
      // Exit Phase (1400 -> 1700) - Exit to right
      final t = ((scrollOffset - 1400) / 300).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      offsetX = screenWidth * curvedT; // Move to right
      offsetY = 0;
    }

    component.position = centerPosition + Vector2(offsetX, offsetY);

    // 2. Opacity Logic - Refined for smooth transitions
    // Phase 1: Fade In (500 -> 750) - Compressed timing
    // Phase 2: Visible (750 -> 1500) - Sufficient viewing time
    // Phase 3: Fade Out (1500 -> 1700) - Overlaps with philosophy entrance

    double opacity = 0.0;

    if (scrollOffset < 500) {
      opacity = 0.0;
    } else if (scrollOffset < 750) {
      // Fade In - Smooth entrance
      final t = ((scrollOffset - 500) / 250).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < 1500) {
      // Fully Visible - Sufficient duration for breathing room
      opacity = 1.0;
    } else {
      // Fade Out - Graceful, overlaps with philosophy entrance
      final t = ((scrollOffset - 1500) / 200).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    }
    component.opacity = opacity;

    // 3. Shine Logic - Minimal, futuristic shimmer
    // Very subtle for space/minimal theme

    // Sub-Phase A: Wipe (1050 -> 1400) - Compressed timing
    double shine = 0.0;
    if (scrollOffset >= 1050 && scrollOffset < 1400) {
      shine = ((scrollOffset - 1050) / 350).clamp(0.0, 1.0);
      shine = exponentialEaseOut.transform(shine);
    } else if (scrollOffset >= 1400) {
      shine = 1.0; // Wipe moved past
    }
    component.fillProgress = shine;

    // Sub-Phase B: Full Shine Shimmer - Very subtle for minimal aesthetic
    double fullShine = 0.0;
    if (scrollOffset >= 1400 && scrollOffset < 1550) {
      // Very low intensity (0.5) for minimal, futuristic feel
      final t = ((scrollOffset - 1400) / 150).clamp(0.0, 1.0);
      fullShine = 0.5 * exponentialEaseOut.transform(t);
    } else if (scrollOffset >= 1550) {
      // Maintain minimal shimmer
      fullShine = 0.5;
    }
    component.fullShineStrength = fullShine;
  }
}
