import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

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
    canvas.drawCircle(Offset.zero, GameLayout.expSatelliteDotSize, paint);

    canvas.save();
    canvas.rotate(-angle);

    final textSpan = TextSpan(
      text: year,
      style: TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.satelliteFontSize,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: _opacity),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final dist = GameLayout.expSatelliteLabelDist;
    final dx = dist * sin(angle);
    final dy = dist * -cos(angle);

    textPainter.paint(
      canvas,
      Offset(dx - textPainter.width / 2, dy - textPainter.height / 2),
    );

    canvas.restore();
  }
}
