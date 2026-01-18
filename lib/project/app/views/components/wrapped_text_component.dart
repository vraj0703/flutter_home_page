import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WrappedTextComponent extends PositionComponent with HasPaint {
  final TextPainter painter;
  final double maxWidth;

  WrappedTextComponent(this.painter, this.maxWidth);

  @override
  Future<void> onLoad() async {
    painter.layout(maxWidth: maxWidth);
    size = Vector2(painter.width, painter.height);
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) return;
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, maxWidth, painter.height),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
