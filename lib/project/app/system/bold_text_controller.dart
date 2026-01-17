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
    // Refined for spacious, futuristic feel with smooth transitions
    // Longer hold time, more graceful exit

    // Phase 0: Hidden/Wait (0 -> 500)
    // Phase 1: Enter (500 -> 1100) - Slower, more graceful entrance
    // Phase 2: Hold (1100 -> 1900) - Extended for breathing room
    // Phase 3: Exit (1900 -> 2300) - Longer, smoother fade to philosophy

    const exponentialEaseOut = ExponentialEaseOut();

    double offsetX = -screenWidth; // Default off-screen left
    double offsetY = 0;

    if (scrollOffset < 500) {
      // Waiting Phase
      offsetX = -screenWidth;
    } else if (scrollOffset < 1100) {
      // Enter Phase (500 -> 1100) - Extended for smoother entry
      final t = ((scrollOffset - 500) / 600).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      // Lerp from -screenWidth to 0
      offsetX = -screenWidth + (screenWidth * curvedT);
      offsetY = 0;
    } else if (scrollOffset < 1900) {
      // Hold Phase (1100 -> 1900) - Extended hold for spacious feel
      offsetX = 0;
      offsetY = 0;
    } else {
      // Exit Phase (1900 -> 2300) - Graceful fade and minimal upward drift
      final t = ((scrollOffset - 1900) / 400).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      // Minimal horizontal movement, just fade
      offsetX = 0;
      offsetY = -30 * curvedT; // Subtle upward float
    }

    component.position = centerPosition + Vector2(offsetX, offsetY);

    // 2. Opacity Logic - Refined for smooth transitions
    // Phase 1: Fade In (500 -> 800) - Slower, more graceful
    // Phase 2: Visible (800 -> 2000) - Extended for spacious feel
    // Phase 3: Fade Out (2000 -> 2300) - Longer, overlaps with philosophy entrance

    double opacity = 0.0;

    if (scrollOffset < 500) {
      opacity = 0.0;
    } else if (scrollOffset < 800) {
      // Fade In - Slower entrance
      final t = ((scrollOffset - 500) / 300).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < 2000) {
      // Fully Visible - Extended duration for breathing room
      opacity = 1.0;
    } else {
      // Fade Out - Graceful, overlaps with philosophy entrance
      final t = ((scrollOffset - 2000) / 300).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    }
    component.opacity = opacity;

    // 3. Shine Logic - Minimal, futuristic shimmer
    // Very subtle for space/minimal theme

    // Sub-Phase A: Wipe (1200 -> 1900) - Slow, extended wipe
    double shine = 0.0;
    if (scrollOffset >= 1200 && scrollOffset < 1900) {
      shine = ((scrollOffset - 1200) / 700).clamp(0.0, 1.0);
      shine = exponentialEaseOut.transform(shine);
    } else if (scrollOffset >= 1900) {
      shine = 1.0; // Wipe moved past
    }
    component.fillProgress = shine;

    // Sub-Phase B: Full Shine Shimmer - Very subtle for minimal aesthetic
    double fullShine = 0.0;
    if (scrollOffset >= 1900 && scrollOffset < 2100) {
      // Very low intensity (0.5 instead of 0.7) for minimal, futuristic feel
      final t = ((scrollOffset - 1900) / 200).clamp(0.0, 1.0);
      fullShine = 0.5 * exponentialEaseOut.transform(t);
    } else if (scrollOffset >= 2100) {
      // Maintain minimal shimmer
      fullShine = 0.5;
    }
    component.fullShineStrength = fullShine;
  }
}
