import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import '../../interfaces/scroll_observer.dart';

class ContactPageController implements ScrollObserver {
  final ContactPageComponent component;
  final double screenHeight;
  static const double initEntranceStart =
      ScrollSequenceConfig.contactEntranceStart;
  static const double entranceDuration =
      ScrollSequenceConfig.contactEntranceDuration;
  static const double holdDuration = ScrollSequenceConfig.contactHoldDuration;
  static const double exitDuration = ScrollSequenceConfig.contactExitDuration;

  final double visibleStart;
  final double exitStart;
  final double exitEnd;

  ContactPageController({required this.component, required this.screenHeight})
    : visibleStart = ScrollSequenceConfig.contactVisibleStart,
      exitStart = ScrollSequenceConfig.contactExitStart,
      exitEnd = ScrollSequenceConfig.contactExitEnd;

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
