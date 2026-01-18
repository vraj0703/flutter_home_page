import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';

class SectionProgressIndicator extends PositionComponent {
  static const int totalSections = 6;
  static const double dotSize = 8.0;
  static const double dotSpacing = 20.0;
  static const Color inactiveColor = Color(0x40FFFFFF); // White 25%
  static const Color activeColor = Color(0xFFFFC107); // Gold

  int _currentSection = 0;
  int _targetSection = 0;
  double _transitionProgress = 1.0; // 1.0 = fully transitioned

  final Paint _inactivePaint = Paint()..color = inactiveColor;
  final Paint _activePaint = Paint()..color = activeColor;

  static const _springCurve = SpringCurve(
    mass: 0.8,
    stiffness: 180.0,
    damping: 12.0,
  );

  SectionProgressIndicator() {
    anchor = Anchor.topRight;
  }

  void setSection(int section) {
    if (section != _targetSection && section >= 0 && section < totalSections) {
      _currentSection = _targetSection;
      _targetSection = section;
      _transitionProgress = 0.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_transitionProgress < 1.0) {
      _transitionProgress += dt * 3.0; // 3.0 for speed
      if (_transitionProgress >= 1.0) {
        _transitionProgress = 1.0;
        _currentSection = _targetSection;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final totalHeight = (totalSections - 1) * dotSpacing;

    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final center = Offset(0, y);

      if (i == _targetSection && _transitionProgress < 1.0) {
        // Transitioning to this dot
        final curvedT = _springCurve.transform(_transitionProgress);
        final size = dotSize * (1.0 + (0.5 * (1.0 - curvedT.abs())));
        final color = Color.lerp(inactiveColor, activeColor, curvedT)!;
        final paint = Paint()..color = color;
        canvas.drawCircle(center, size / 2, paint);
      } else if (i == _currentSection && _transitionProgress < 1.0) {
        // Transitioning away from this dot
        final curvedT = _springCurve.transform(_transitionProgress);
        final size = dotSize * (1.0 + (0.5 * curvedT));
        final color = Color.lerp(activeColor, inactiveColor, curvedT)!;
        final paint = Paint()..color = color;
        canvas.drawCircle(center, size / 2, paint);
      } else if (i == _targetSection) {
        // Currently active dot
        canvas.drawCircle(center, dotSize / 2, _activePaint);
      } else {
        // Inactive dot
        canvas.drawCircle(center, dotSize / 2, _inactivePaint);
      }
    }
  }
}
