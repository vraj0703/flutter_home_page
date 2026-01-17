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
    // 1. Position Logic with Enhanced Curves
    // Timeline Shifted by +500 to avoid Title overlap.

    // Phase 0: Hidden/Wait (0 -> 500)
    // Phase 1: Enter (500 -> 1000) - From Left (-W) to Center (0) with ExponentialEaseOut
    // Phase 2: Hold (1000 -> 1500) - Center
    // Phase 3: Exit (1500 -> 2000) - Center to Right with upward drift and SpringCurve

    const exponentialEaseOut = ExponentialEaseOut();
    const springCurve = SpringCurve(mass: 1.0, stiffness: 180.0, damping: 12.0);

    double offsetX = -screenWidth; // Default off-screen left
    double offsetY = 0;

    if (scrollOffset < 500) {
      // Waiting Phase
      offsetX = -screenWidth;
    } else if (scrollOffset < 1000) {
      // Enter Phase (500 -> 1000) with ExponentialEaseOut for smooth elegance
      final t = ((scrollOffset - 500) / 500).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      // Lerp from -screenWidth to 0
      offsetX = -screenWidth + (screenWidth * curvedT);
      offsetY = 0;
    } else if (scrollOffset < 1500) {
      // Hold Phase (1000 -> 1500)
      offsetX = 0;
      offsetY = 0;
    } else {
      // Exit Phase (1500 -> 1900) with SpringCurve and upward drift
      final t = ((scrollOffset - 1500) / 400).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);
      // Lerp from 0 to +screenWidth with subtle upward float
      offsetX = screenWidth * curvedT;
      offsetY = -50 * curvedT; // Upward drift during exit
    }

    component.position = centerPosition + Vector2(offsetX, offsetY);

    // 2. Opacity Logic with Extended Hold and ExponentialEaseOut Fade
    // Phase 1: Fade In (500 -> 700)
    // Phase 2: Visible (700 -> 1800) - Extended by 100 units
    // Phase 3: Fade Out (1800 -> 1900) - ExponentialEaseOut for elegance

    double opacity = 0.0;

    if (scrollOffset < 500) {
      opacity = 0.0;
    } else if (scrollOffset < 700) {
      // Fade In
      opacity = ((scrollOffset - 500) / 200).clamp(0.0, 1.0);
    } else if (scrollOffset < 1800) {
      // Fully Visible - Extended duration
      opacity = 1.0;
    } else {
      // Fade Out with ExponentialEaseOut for graceful exit
      final t = ((scrollOffset - 1800) / 100).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    }
    component.opacity = opacity;

    // 3. Shine Logic with Refined Timing and Subtle Elegance
    // Extended wipe duration for more gradual, sophisticated shimmer

    // Sub-Phase A: Wipe (1000 -> 1600) - Extended from 400 to 600 scroll units, slower & elegant
    double shine = 0.0;
    if (scrollOffset >= 1000 && scrollOffset < 1600) {
      shine = ((scrollOffset - 1000) / 600).clamp(0.0, 1.0);
      shine = exponentialEaseOut.transform(shine);
    } else if (scrollOffset >= 1600) {
      shine = 1.0; // Wipe moved past
    }
    component.fillProgress = shine;

    // Sub-Phase B: Full Shine Shimmer (1600 -> 1800) - Reduced intensity for subtle elegance
    double fullShine = 0.0;
    if (scrollOffset >= 1600 && scrollOffset < 1800) {
      // Ramp up full shine with reduced peak (0.7 instead of 1.0)
      final t = ((scrollOffset - 1600) / 200).clamp(0.0, 1.0);
      fullShine = 0.7 * exponentialEaseOut.transform(t);
    } else if (scrollOffset >= 1800) {
      // Exit Phase (1800+) - Maintain subtle shimmer during exit
      fullShine = 0.7;
    }
    component.fullShineStrength = fullShine;
  }
}
