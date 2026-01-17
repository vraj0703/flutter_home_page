import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/widgets/components/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class SkillsPageController implements ScrollObserver {
  final SkillsKeyboardComponent component;

  static const double entranceStart = 8600.0;
  static const double entranceEnd = 9000.0;
  static const double interactEnd = 10400.0;
  static const double exitEnd = 10800.0;

  SkillsPageController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = SpringCurve(
      mass: 1.0,
      stiffness: 140.0,
      damping: 18.0,
    );

    if (scrollOffset < entranceStart) {
      component.opacity = 0.0;
      component.scale = Vector2.all(0.9);
      component.position = Vector2.zero();
    } else if (scrollOffset < entranceEnd) {
      final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
      final curvedT = exponentialEaseOut.transform(t);
      component.opacity = curvedT;
      component.scale = Vector2.all(0.9 + (0.1 * curvedT));
      component.position = Vector2.zero();
    } else if (scrollOffset < interactEnd) {
      // Hold Phase
      component.opacity = 1.0;
      component.scale = Vector2.all(1.0);
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      final t = (scrollOffset - interactEnd) / (exitEnd - interactEnd);
      final curvedT = gentleSpring.transform(t);
      component.opacity = 1.0 - exponentialEaseOut.transform(t);
      component.position = Vector2(0, -120 * curvedT);
    } else {
      component.opacity = 0.0;
      component.position = Vector2(0, -120);
    }
  }
}
