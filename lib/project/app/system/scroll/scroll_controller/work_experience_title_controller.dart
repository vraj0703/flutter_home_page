import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

class WorkExperienceTitleController implements ScrollObserver {
  final WorkExperienceTitleComponent component;
  final double screenHeight;
  final Vector2 centerPosition;

  // Local constants derived from 1600 total height
  static const double entranceDuration = 600.0;
  static const double entranceEnd = 600.0;
  static const double holdStart = 600.0;
  static const double holdDuration = 500.0;
  static const double holdEnd = 1100.0;
  static const double exitStart = 1100.0;
  static const double exitDuration = 500.0;
  static const double exitEnd = 1600.0;

  static const springCurve = SpringCurve(
    mass: 1.0,
    stiffness: 140.0,
    damping: 15.0,
  );
  static const exponentialEaseOut = ExponentialEaseOut();

  WorkExperienceTitleController({
    required this.component,
    required this.screenHeight,
    required this.centerPosition,
  });

  @override
  void onScroll(double offset) {
    double yOffset = 0.0;
    double opacity = 0.0;
    double scale = 1.0;
    double rotation = 0.0;

    if (offset < 0) {
      yOffset = screenHeight * 1.5;
      opacity = 0.0;
      scale = 0.9;
    } else if (offset < entranceEnd) {
      final t = (offset / entranceDuration).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);
      yOffset = (screenHeight * 1.5) * (1.0 - curvedT);
      opacity = exponentialEaseOut.transform(t);
      scale = 0.9 + (0.1 * exponentialEaseOut.transform(t));
      rotation = 0.0087 * math.sin(t * math.pi * 3) * (1.0 - t);
    } else if (offset < holdEnd) {
      yOffset = 0.0;
      opacity = 1.0;
      final holdProgress = ((offset - holdStart) / holdDuration).clamp(
        0.0,
        1.0,
      );
      component.applyPulse(holdProgress);
      scale = component.scale.x;
    } else if (offset < exitEnd) {
      final t = ((offset - exitStart) / exitDuration).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);
      yOffset = -(screenHeight * 1.5) * curvedT;
      opacity = 1.0 - exponentialEaseOut.transform(t);
      scale = 1.0 + (0.1 * curvedT);
    } else {
      yOffset = -(screenHeight * 1.5);
      opacity = 0.0;
      scale = 1.1;
    }

    component.position = centerPosition + Vector2(0, yOffset);
    component.opacity = opacity;
    component.scale = Vector2.all(scale);
    component.angle = rotation;
  }
}
