import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_description_item.dart';

class ExperienceDetailsComponent extends PositionComponent with HasPaint {
  final List<ExperienceNode> data;
  final List<ExperienceDescriptionItem> _items = [];

  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.0;
  static const double activeScale = 1.15;
  static const double inactiveScale = 0.65;
  static const double spacing = pi / 4;

  double _parentOpacity = 1.0;

  ExperienceDetailsComponent({required this.data, super.position});

  @override
  set opacity(double val) {
    if (super.opacity == val) return;
    super.opacity = val;
    _parentOpacity = val;
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < data.length; i++) {
      final item = ExperienceDescriptionItem(description: data[i].description);
      _items.add(item);
      add(item);
    }
  }

  void updateRotation(double systemRotation) {
    final center = Vector2(0, size.y / 2);

    final orbitRadius = size.y * GameLayout.expOrbitRadiusMultiplier;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final baseAngle = i * spacing;

      final currentAngle = baseAngle + systemRotation;

      final x = center.x + orbitRadius * cos(currentAngle);
      final y = center.y + orbitRadius * sin(currentAngle);

      item.position = Vector2(x, y);
      item.angle = currentAngle;
      double diff = currentAngle;

      while (diff > pi) {
        diff -= 2 * pi;
      }
      while (diff < -pi) {
        diff += 2 * pi;
      }

      final dist = diff.abs();

      const threshold = 0.4;

      if (dist < threshold) {
        final t = 1.0 - (dist / threshold);

        item.opacity = t * _parentOpacity;
        item.scale = Vector2.all(
          inactiveScale + (activeScale - inactiveScale) * t,
        );
      } else {
        item.opacity = 0.0;
      }
    }
  }
}
