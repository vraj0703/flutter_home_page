import 'package:flame/components.dart';
import 'scroll_effect.dart';

class RotateScrollEffect extends ScrollEffect<PositionComponent> {
  final double startAngle;
  final double endAngle;

  RotateScrollEffect({
    required super.startScroll,
    required super.endScroll,
    this.startAngle = 0.0,
    required this.endAngle, // Radians
    super.curve,
  });

  @override
  void update(PositionComponent component, double progress) {
    final currentAngle = startAngle + (endAngle - startAngle) * progress;
    component.angle = currentAngle;
  }
}
