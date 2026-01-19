import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Static inactive dot with tap detection
class StaticDot extends PositionComponent with TapCallbacks {
  static const double size = 8.0;
  static const double tapRadius = 20.0; // Generous tap area
  static const Color color = Color(0x40FFFFFF); // Light gray (25% white)

  final int sectionIndex;
  final void Function(int index)? onTapped;

  final Paint _paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  StaticDot({
    required this.sectionIndex,
    required Vector2 position,
    this.onTapped,
  }) : super(
          position: position,
          size: Vector2.all(size),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset.zero,
      size / 2,
      _paint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Use generous tap area for mobile-friendly interaction
    final tapPos = event.localPosition;
    if (tapPos.distanceTo(Offset.zero) <= tapRadius) {
      onTapped?.call(sectionIndex);
    }
  }
}
