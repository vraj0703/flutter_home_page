import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/widgets/components/contact_page_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';
import '../interfaces/scroll_observer.dart';

class ContactPageController implements ScrollObserver {
  final ContactPageComponent component;
  final double screenHeight;
  static const double initEntranceStart = 10800.0;
  static const double entranceDuration = 600.0;
  static const double holdDuration = 1000.0;
  static const double exitDuration = 600.0;

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
    const entranceSpring = SpringCurve(
      mass: 1.2,
      stiffness: 150.0,
      damping: 14.0,
    );
    const exitSpring = SpringCurve(mass: 1.0, stiffness: 160.0, damping: 12.0);
    const exponentialEaseOut = ExponentialEaseOut();

    if (scrollOffset < initEntranceStart) {
      component.position = Vector2(0, screenHeight);
      component.opacity = 0.0;
    } else if (scrollOffset < visibleStart) {
      final t = (scrollOffset - initEntranceStart) / entranceDuration;
      final curvedT = entranceSpring.transform(t);

      final y = screenHeight * (1.0 - curvedT);
      component.position = Vector2(0, y);

      component.opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < exitStart) {
      component.position = Vector2.zero();
      component.opacity = 1.0;
    } else if (scrollOffset < exitEnd) {
      final t = (scrollOffset - exitStart) / exitDuration;
      final curvedT = exitSpring.transform(t);

      final y = -screenHeight * curvedT;
      component.position = Vector2(0, y);

      component.opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      // Gone above
      component.position = Vector2(0, -screenHeight);
      component.opacity = 0.0;
    }
  }
}
