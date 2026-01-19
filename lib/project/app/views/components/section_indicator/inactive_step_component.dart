import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Static inactive dot indicator
class InactiveStepComponent extends PositionComponent with TapCallbacks {
  static const double dotSize = 8.0;
  static const Color inactiveColor = Color(0x40FFFFFF); // Light gray (white 25%)

  final int index;
  final void Function(int index)? onTap;

  final Paint _paint = Paint()
    ..color = inactiveColor
    ..style = PaintingStyle.fill;

  InactiveStepComponent({
    required this.index,
    required Vector2 position,
    this.onTap,
  }) : super(
          position: position,
          size: Vector2.all(dotSize),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      dotSize / 2,
      _paint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call(index);
  }
}
