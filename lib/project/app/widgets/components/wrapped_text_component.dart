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
    // Parent opacity is applied via global opacity (render tree?)
    // Flame applies opacity to paint if we mix HasPaint?
    // Actually PositionComponent checks opacity, but we need to apply it to the painter.

    // We need to apply the opacity to the text style color
    // But rebuilding painter is expensive?
    // We can use saveLayer with alpha?
    // Or just re-paint.

    if (opacity <= 0.01) return;

    // Quick hack for opacity:
    // If we use saveLayer, we can apply alpha composite.
    // Or we assume standard paint opacity works if we don't override render?
    // TextPainter.paint takes offset. It draws strictly with the Span's color.
    // We must modify color or use layer.

    // Let's use layer for simplicity of generic opacity support

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, maxWidth, painter.height),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
