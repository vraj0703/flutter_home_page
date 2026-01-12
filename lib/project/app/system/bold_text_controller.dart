import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/bold_text_reveal_component.dart';

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
    // 1. Position Logic
    // Timeline Shifted by +500 to avoid Title overlap.

    // Phase 0: Hidden/Wait (0 -> 500)
    // Phase 1: Enter (500 -> 1000) - From Left (-W) to Center (0)
    // Phase 2: Hold (1000 -> 1500) - Center
    // Phase 3: Exit (1500 -> 2000) - Center to Up (-1000)

    double offsetX = -screenWidth; // Default off-screen left
    double offsetY = 0;

    if (scrollOffset < 500) {
      // Waiting Phase
      offsetX = -screenWidth;
    } else if (scrollOffset < 1000) {
      // Enter Phase (500 -> 1000)
      final t = ((scrollOffset - 500) / 500).clamp(0.0, 1.0);
      final curvedT = Curves.easeOutCubic.transform(t);
      // Lerp from -screenWidth to 0
      offsetX = -screenWidth + (screenWidth * curvedT);
      offsetY = 0;
    } else if (scrollOffset < 1500) {
      // Hold Phase (1000 -> 1500)
      offsetX = 0;
      offsetY = 0;
    } else {
      // Exit Phase (1500 -> 2000)
      // center to Right
      final t = ((scrollOffset - 1500) / 500).clamp(0.0, 1.0);
      final curvedT = Curves.easeIn.transform(t);
      // Lerp from 0 to +screenWidth
      offsetX = screenWidth * curvedT;
      offsetY = 0;
    }

    component.position = centerPosition + Vector2(offsetX, offsetY);

    // 2. Opacity Logic
    // Phase 1: Fade In (500 -> 700)
    // Phase 2: Visible (700 -> 1700)
    // Phase 3: Fade Out (1700 -> 2000)

    double opacity = 0.0;

    if (scrollOffset < 500) {
      opacity = 0.0;
    } else if (scrollOffset < 700) {
      // Fade In
      opacity = ((scrollOffset - 500) / 200).clamp(0.0, 1.0);
    } else if (scrollOffset < 1700) {
      // Fully Visible
      opacity = 1.0;
    } else {
      // Fade Out
      final t = ((scrollOffset - 1700) / 300).clamp(0.0, 1.0);
      opacity = 1.0 - t;
    }
    component.opacity = opacity;

    // 3. Shine Logic
    // Trigger (1000 -> 1500) - Hold Phase

    // Sub-Phase A: Wipe (1000 -> 1400) - Faster wipe
    double shine = 0.0;
    if (scrollOffset >= 1000 && scrollOffset < 1400) {
      shine = ((scrollOffset - 1000) / 400).clamp(0.0, 1.0);
      shine = Curves.easeInOut.transform(shine);
    } else if (scrollOffset >= 1400) {
      shine = 1.0; // Wipe moved past
    }
    component.fillProgress = shine;

    // Sub-Phase B: Full Shine Flash (1400 -> 1500) -> Hold High -> Exit
    double fullShine = 0.0;
    if (scrollOffset >= 1400 && scrollOffset < 1500) {
      // Ramp up full shine
      fullShine = ((scrollOffset - 1400) / 100).clamp(0.0, 1.0);
      fullShine = Curves.easeOut.transform(fullShine);
    } else {
      // Exit Phase (1500+)
      // Keep Full Shine ON as it exits (User Request)
      fullShine = 1.0;
    }
    component.fullShineStrength = fullShine;
  }
}
