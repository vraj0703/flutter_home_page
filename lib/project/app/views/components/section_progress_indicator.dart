import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';

class SectionProgressIndicator extends PositionComponent with HasPaint, TapCallbacks {
  static const int totalSections = 6;
  static const double dotSize = 8.0;
  static const double dotSpacing = 20.0;
  static const double hitAreaRadius = 15.0; // Larger tap area
  static const Color inactiveColor = Color(0x40FFFFFF); // White 25%
  static const Color activeColor = Color(0xFFFFC107); // Gold

  int _currentSection = 0;
  int _targetSection = 0;
  double _transitionProgress = 1.0; // 1.0 = fully transitioned

  final Paint _inactivePaint = Paint()..color = inactiveColor;
  final Paint _activePaint = Paint()..color = activeColor;

  // Callback when a section is tapped
  void Function(int section)? onSectionTap;

  static const _springCurve = SpringCurve(
    mass: 0.8,
    stiffness: 240.0,
    damping: 8.0,
  );

  SectionProgressIndicator({this.onSectionTap}) {
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
        // Transitioning to this dot - bouncy scale increase
        final curvedT = _springCurve.transform(_transitionProgress);
        final size = dotSize * (1.0 + (1.0 * (1.0 - curvedT.abs())));
        final color = Color.lerp(inactiveColor, activeColor, curvedT)!;
        final paint = Paint()..color = color;
        canvas.drawCircle(center, size / 2, paint);
      } else if (i == _currentSection && _transitionProgress < 1.0) {
        // Transitioning away from this dot - bouncy scale decrease
        final curvedT = _springCurve.transform(_transitionProgress);
        final size = dotSize * (1.0 + (1.0 * curvedT));
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

  @override
  void onTapDown(TapDownEvent event) {
    // Convert tap position to local coordinates
    final localPos = event.localPosition;

    // Calculate which dot was tapped
    final totalHeight = (totalSections - 1) * dotSpacing;

    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final dotCenter = Offset(0, y);

      // Check if tap is within hit area of this dot
      final distance = (localPos - dotCenter).distance;
      if (distance <= hitAreaRadius) {
        // Notify callback
        onSectionTap?.call(i);
        break;
      }
    }
  }
}
