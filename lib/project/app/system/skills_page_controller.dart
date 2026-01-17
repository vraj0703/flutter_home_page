import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class SkillsPageController implements ScrollObserver {
  final SkillsKeyboardComponent component;

  // 1. Entrance: 12200 -> 12800 (Shifted to ensure Testimonials gone)
  static const double entranceStart = 12200.0;
  static const double entranceEnd = 12800.0;

  // 2. Visible/Interact: 12800 -> 14800 (2000px)
  static const double interactEnd = 14800.0;

  // 3. Exit: 14800 -> 15400
  static const double exitEnd = 15400.0;

  SkillsPageController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    // Enhanced with ElasticEaseOut for playful bounce entrance
    // and SpringCurve for smooth exit
    const elasticEaseOut = ElasticEaseOut(amplitude: 0.4, period: 0.3);
    const springCurve = SpringCurve(mass: 0.9, stiffness: 170.0, damping: 12.0);
    const exponentialEaseOut = ExponentialEaseOut();

    if (scrollOffset < entranceStart) {
      component.opacity = 0.0;
      component.scale = Vector2.all(0.7);
      component.position = Vector2.zero();
    } else if (scrollOffset < entranceEnd) {
      // Entrance Phase with ElasticEaseOut for bouncy appearance
      final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
      final curvedT = elasticEaseOut.transform(t);
      component.opacity = curvedT.clamp(0.0, 1.0);
      component.scale = Vector2.all(0.7 + (0.3 * curvedT.clamp(0.0, 1.0))); // 0.7 -> 1.0 with bounce
      component.position = Vector2.zero();
    } else if (scrollOffset < interactEnd) {
      // Hold Phase
      component.opacity = 1.0;
      component.scale = Vector2.all(1.0);
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      // Exit Phase with SpringCurve and elegant fade
      final t = (scrollOffset - interactEnd) / (exitEnd - interactEnd);
      final curvedT = springCurve.transform(t);
      component.opacity = 1.0 - exponentialEaseOut.transform(t);
      // Slide Up with spring physics
      component.position = Vector2(0, -100 * curvedT);
    } else {
      component.opacity = 0.0;
      component.position = Vector2(0, -100);
    }
  }
}
