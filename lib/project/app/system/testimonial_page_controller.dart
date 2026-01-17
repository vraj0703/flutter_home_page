import 'package:flame/components.dart'; // Add this for Vector2
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class TestimonialPageController implements ScrollObserver {
  final TestimonialPageComponent component;
  final double entranceStart;
  final double exitStart;
  final double exitEnd;

  // Configuration
  // Experience ends ~7600 (Exit 7100 -> 7600)
  static const double initEntranceStart = 7600.0;
  static const double initInteractionStart =
      8000.0; // Start scrolling after fade in
  static const double visibleDuration =
      4000.0; // Increased to cover full carousel width
  static const double exitDuration = 600.0;

  final double interactionStart;
  final double interactionEnd;

  TestimonialPageController({
    required this.component,
    this.entranceStart = initEntranceStart,
  }) : interactionStart = initInteractionStart,
       interactionEnd = initEntranceStart + visibleDuration,
       exitStart = initEntranceStart + visibleDuration,
       exitEnd = initEntranceStart + visibleDuration + exitDuration;

  @override
  void onScroll(double scrollOffset) {
    _handleVisibility(scrollOffset);
    _handleInteraction(scrollOffset);
    _handleExit(scrollOffset);
  }

  void _handleInteraction(double scrollOffset) {
    // Determine linear progress of scroll within interaction range
    // Map this to a horizontal offset for the carousel

    double scrollDelta = 0.0;

    if (scrollOffset < interactionStart) {
      scrollDelta = 0.0;
    } else if (scrollOffset > interactionEnd) {
      scrollDelta = interactionEnd - interactionStart;
    } else {
      scrollDelta = scrollOffset - interactionStart;
    }

    component.updateScroll(scrollDelta);
  }

  void _handleVisibility(double scrollOffset) {
    // Enhanced with ExponentialEaseOut for smooth fade
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
    } else if (scrollOffset < exitEnd) {
      // Exit Fade Out with ExponentialEaseOut
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleExit(double scrollOffset) {
    if (!component.isLoaded) return;

    // Enhanced Exit with SpringCurve for natural physics
    const springCurve = SpringCurve(mass: 1.0, stiffness: 160.0, damping: 13.0);

    // Parallax Slide Up with Spring Physics
    if (scrollOffset < exitStart) {
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);
      component.position = Vector2(0, -1000 * curvedT);
    } else {
      component.position = Vector2(0, -1000);
    }
  }
}
