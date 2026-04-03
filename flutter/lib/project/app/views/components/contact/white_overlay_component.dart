import 'dart:ui';
import 'package:flame/components.dart';

class WhiteOverlayComponent extends PositionComponent {
  double opacity = 0.0;
  WhiteOverlayComponent() : super(priority: 50);

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
