import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/experience_page_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class ExperiencePageController implements ScrollObserver {
  final ExperiencePageComponent component;
  final double entranceStart;
  final double interactionStart;
  final double interactionEnd;
  final double exitStart;
  final double exitEnd;

  // Scroll Configuration
  static const double initEntranceStart = 4200.0;
  static const double initInteractionStart = 4600.0;
  static const double itemScrollHeight = 500.0;
  static const int itemCount = 5;

  ExperiencePageController({
    required this.component,
    this.entranceStart = initEntranceStart,
    this.interactionStart = initInteractionStart,
  }) : interactionEnd = interactionStart + (itemCount * itemScrollHeight),
       exitStart = interactionStart + (itemCount * itemScrollHeight),
       exitEnd =
           interactionStart + (itemCount * itemScrollHeight) + itemScrollHeight;

  @override
  void onScroll(double scrollOffset) {
    _handleVisibility(scrollOffset);
    _handleInteraction(scrollOffset);
    _handleExit(scrollOffset);
  }

  void _handleVisibility(double scrollOffset) {
    // Enhanced with ExponentialEaseOut for smooth, professional fade
    const exponentialEaseOut = ExponentialEaseOut();
    double opacity = 0.0;

    // 1. Entrance (Fade In) with ExponentialEaseOut
    if (scrollOffset < entranceStart) {
      opacity = 0.0;
    } else if (scrollOffset < entranceStart + 400) {
      final t = ((scrollOffset - entranceStart) / 400).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < exitStart) {
      opacity = 1.0;
    } else if (scrollOffset < exitStart + 500) {
      // Exit Fade Out with ExponentialEaseOut
      final t = ((scrollOffset - exitStart) / 500).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleInteraction(double scrollOffset) {
    if (scrollOffset < interactionStart) {
      // Reset to initial state
      component.updateInteraction(0.0);
      return;
    }

    if (scrollOffset > interactionEnd) {
      // Lock to final state
      component.updateInteraction(interactionEnd - interactionStart);
      return;
    }

    final localScroll = scrollOffset - interactionStart;
    component.updateInteraction(localScroll);
  }

  void _handleExit(double scrollOffset) {
    if (!component.isLoaded) return;

    // Enhanced Exit with SpringCurve and Scale Compression
    const springCurve = SpringCurve(mass: 1.0, stiffness: 170.0, damping: 12.0);

    // Parallax Slide Up + Warp + Scale Compression
    if (scrollOffset < exitStart) {
      component.position = component.initialPosition;
      component.setWarp(0.0);
      // Reset scale (assuming component has scale property)
      if (component.scale != Vector2.all(1.0)) {
        component.scale = Vector2.all(1.0);
      }
    } else if (scrollOffset < exitEnd) {
      // 0.0 to 1.0 progress
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);

      // Move up by 1000px with spring curve
      component.position = component.initialPosition + Vector2(0, -1000 * curvedT);

      // Trigger Warp
      component.setWarp(t);

      // Scale compression during exit (1.0 → 0.98 → 0.95)
      double scale = 1.0;
      if (t < 0.5) {
        scale = 1.0 - (0.02 * (t / 0.5)); // 1.0 → 0.98
      } else {
        scale = 0.98 - (0.03 * ((t - 0.5) / 0.5)); // 0.98 → 0.95
      }
      component.scale = Vector2.all(scale);
    } else {
      // Final state
      component.position = component.initialPosition + Vector2(0, -1000);
      component.setWarp(1.0);
      component.scale = Vector2.all(0.95);
    }
  }
}
