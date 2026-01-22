import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

class ContactPageController implements ScrollObserver {
  final ContactPageComponent component;
  final double screenHeight;

  // Local Constants
  // visibleStart was +600 from entrance
  static const double visibleStart = 600.0;
  static const double entranceDuration =
      ScrollSequenceConfig.contactEntranceDuration;

  ContactPageController({required this.component, required this.screenHeight});

  @override
  void onScroll(double offset) {
    const entranceSpring = GameCurves.contactEntranceSpring;
    const exponentialEaseOut = ExponentialEaseOut();

    if (offset < 0) {
      component.position = Vector2(0, screenHeight);
      component.opacity = 0.0;
    } else if (offset < visibleStart) {
      final t = (offset / entranceDuration).clamp(0.0, 1.0);
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
