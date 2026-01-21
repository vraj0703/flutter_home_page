import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

class ContactPageController implements ScrollObserver {
  final ContactPageComponent component;
  final double screenHeight;
  static const double initEntranceStart =
      ScrollSequenceConfig.contactEntranceStart;
  static const double entranceDuration =
      ScrollSequenceConfig.contactEntranceDuration;

  final double visibleStart;

  ContactPageController({required this.component, required this.screenHeight})
    : visibleStart = ScrollSequenceConfig.contactVisibleStart;

  @override
  void onScroll(double scrollOffset) {
    const entranceSpring = GameCurves.contactEntranceSpring;
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
    } else {
      // Contact stays visible as final section
      component.position = Vector2.zero();
      component.opacity = 1.0;
    }
  }
}
