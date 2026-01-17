import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/contact_page_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class ContactPageController implements ScrollObserver {
  final ContactPageComponent component;
  final double screenHeight;

  // 1. Entrance: Slide in from bottom (covering Testimonials)
  static const double initEntranceStart = 15400.0;
  static const double entranceDuration = 800.0;

  // 2. Hold: Static view
  static const double holdDuration = 1500.0;

  // 3. Exit: Slide up or Fade out
  static const double exitDuration = 800.0;

  final double visibleStart;
  final double exitStart;
  final double exitEnd;

  ContactPageController({required this.component, required this.screenHeight})
    : visibleStart = initEntranceStart + entranceDuration,
      exitStart = initEntranceStart + entranceDuration + holdDuration,
      exitEnd =
          initEntranceStart + entranceDuration + holdDuration + exitDuration;

  @override
  void onScroll(double scrollOffset) {
    // Enhanced with Spring Physics for natural, inviting feel
    const entranceSpring = SpringCurve(mass: 1.2, stiffness: 150.0, damping: 14.0);
    const exitSpring = SpringCurve(mass: 1.0, stiffness: 160.0, damping: 12.0);
    const exponentialEaseOut = ExponentialEaseOut();

    // Entrance Phase with Spring and Fade
    if (scrollOffset < initEntranceStart) {
      component.position = Vector2(0, screenHeight); // Hidden below
      component.opacity = 0.0; // Ensure hidden
    } else if (scrollOffset < visibleStart) {
      // Slide Up with SpringCurve and Fade In
      final t = (scrollOffset - initEntranceStart) / entranceDuration;
      final curvedT = entranceSpring.transform(t);
      // Spring-based slide: screenHeight -> 0
      final y = screenHeight * (1.0 - curvedT);
      component.position = Vector2(0, y);
      // Elegant fade in
      component.opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < exitStart) {
      // Hold
      component.position = Vector2.zero();
      component.opacity = 1.0;
    } else if (scrollOffset < exitEnd) {
      // Exit Slide Up with Spring and Fade
      final t = (scrollOffset - exitStart) / exitDuration;
      final curvedT = exitSpring.transform(t);
      // Spring-based slide: 0 -> -screenHeight
      final y = -screenHeight * curvedT;
      component.position = Vector2(0, y);
      // Elegant fade out
      component.opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      // Gone above
      component.position = Vector2(0, -screenHeight);
      component.opacity = 0.0;
    }
  }
}
