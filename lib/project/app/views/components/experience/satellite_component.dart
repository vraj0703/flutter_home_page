import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SatelliteComponent extends PositionComponent with HasPaint {
  String year;
  Color color;
  double _opacity = 0.0;

  SatelliteComponent({required this.year, required this.color});

  @override
  set opacity(double val) {
    _opacity = val;
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    // Draw Dot
    final paint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 6, paint);

    canvas.save();
    canvas.rotate(-angle);

    final textSpan = TextSpan(
      text: year,
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: _opacity),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final dist = 40.0;
    final dx = dist * sin(angle);
    final dy = dist * -cos(angle);

    textPainter.paint(
      canvas,
      Offset(dx - textPainter.width / 2, dy - textPainter.height / 2),
    );

    canvas.restore();
  }
}
