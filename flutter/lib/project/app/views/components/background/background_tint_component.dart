import 'dart:ui';
import 'package:flame/components.dart';

class BackgroundTintComponent extends PositionComponent {
  Color currentTint = const Color(0x00000000); // Transparent initially

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (currentTint.a > 0) {
      final paint = Paint()..color = currentTint;
      canvas.drawRect(size.toRect(), paint);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
