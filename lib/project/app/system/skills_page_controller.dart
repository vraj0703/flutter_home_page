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
    // Refined for minimal, futuristic feel - smooth glide, no bounce
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = SpringCurve(mass: 1.0, stiffness: 140.0, damping: 18.0);

    if (scrollOffset < entranceStart) {
      component.opacity = 0.0;
      component.scale = Vector2.all(0.9);
      component.position = Vector2.zero();
    } else if (scrollOffset < entranceEnd) {
      // Entrance Phase - Smooth, elegant scale-up
      final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
      final curvedT = exponentialEaseOut.transform(t);
      component.opacity = curvedT;
      component.scale = Vector2.all(0.9 + (0.1 * curvedT)); // 0.9 -> 1.0 smooth
      component.position = Vector2.zero();
    } else if (scrollOffset < interactEnd) {
      // Hold Phase
      component.opacity = 1.0;
      component.scale = Vector2.all(1.0);
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      // Exit Phase - Smooth fade and upward glide
      final t = (scrollOffset - interactEnd) / (exitEnd - interactEnd);
      final curvedT = gentleSpring.transform(t);
      component.opacity = 1.0 - exponentialEaseOut.transform(t);
      // Smooth upward glide
      component.position = Vector2(0, -120 * curvedT);
    } else {
      component.opacity = 0.0;
      component.position = Vector2(0, -120);
    }
  }
}
