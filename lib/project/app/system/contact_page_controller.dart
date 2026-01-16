import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/contact_page_component.dart';

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
    // Entrance Phase
    if (scrollOffset < initEntranceStart) {
      component.position = Vector2(0, screenHeight); // Hidden below
      component.opacity = 0.0; // Ensure hidden
    } else if (scrollOffset < visibleStart) {
      // Slide Up
      final t = (scrollOffset - initEntranceStart) / entranceDuration;
      // Linear slide: screenHeight -> 0
      final y = screenHeight * (1.0 - t);
      component.position = Vector2(0, y);
      component.opacity = 1.0; // Fully visible as it slides
    } else if (scrollOffset < exitStart) {
      // Hold
      component.position = Vector2.zero();
      component.opacity = 1.0;
    } else if (scrollOffset < exitEnd) {
      // Exit Slide Up
      final t = (scrollOffset - exitStart) / exitDuration;
      // 0 -> -screenHeight
      final y = -screenHeight * t;
      component.position = Vector2(0, y);
      component.opacity = 1.0;
    } else {
      // Gone above
      component.position = Vector2(0, -screenHeight);
      component.opacity = 0.0;
    }
  }
}
