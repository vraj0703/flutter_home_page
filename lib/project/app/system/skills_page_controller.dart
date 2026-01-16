import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/skills_keyboard_component.dart';

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
    if (scrollOffset < entranceStart) {
      component.opacity = 0.0;
      component.scale = Vector2.all(0.8);
    } else if (scrollOffset < entranceEnd) {
      // Entrance Phase
      final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
      component.opacity = t;
      component.scale = Vector2.all(0.8 + (0.2 * t)); // 0.8 -> 1.0
      component.position = Vector2.zero(); // Centered (handled by parent?)
      // Actually specific positioning might be needed if component isn't sized to screen.
      // Assuming component.onLoad centers chassis relative to its size (screen size).
    } else if (scrollOffset < interactEnd) {
      // Hold Phase
      component.opacity = 1.0;
      component.scale = Vector2.all(1.0);

      // Interaction: Animate keys?
      // We can pass scroll delta to component later.
    } else if (scrollOffset < exitEnd) {
      // Exit Phase
      final t = (scrollOffset - interactEnd) / (exitEnd - interactEnd);
      component.opacity = 1.0 - t;
      // Slide Up
      component.position = Vector2(0, -100 * t);
    } else {
      component.opacity = 0.0;
    }
  }
}
