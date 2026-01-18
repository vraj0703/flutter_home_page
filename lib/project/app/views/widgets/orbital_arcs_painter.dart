import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class OrbitalArcsPainter extends CustomPainter {
  final double rotation;
  final Color accentColor;
  final double opacity;

  OrbitalArcsPainter({
    required this.rotation,
    required this.accentColor,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final center = Offset(0, size.height / 2); // Anchor at Left-Center
    final maxRadius = size.height * 1;

    // 1. Outer Arc (Darkest) - 0.8x Speed
    final paint1 = Paint()
      ..color = Colors.white.withValues(
        alpha: GameStyles.orbitalArcAlphaOuter * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameLayout.orbitalArcWidthOuter
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final rect1 = Rect.fromCircle(
      center: center,
      radius: maxRadius * GameLayout.orbitalRadiusOuter,
    );
    final outerAngle = rotation * 0.8;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(outerAngle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect1, 0, 2 * pi, false, paint1);
    canvas.restore();

    // 2. Middle Arc (Medium) - 1.0x
    final paint2 = Paint()
      ..color = Colors.white.withValues(
        alpha: GameStyles.orbitalArcAlphaMid * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameLayout.orbitalArcWidthMid;

    canvas.drawCircle(center, maxRadius * GameLayout.orbitalRadiusMid, paint2);

    // 3. Inner Arc (Lighter/Active Track) - 1.2x
    final innerAngle = rotation * 1.2;

    final paint3 = Paint()
      ..shader =
          SweepGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(
                alpha: GameStyles.orbitalArcAlphaInnerBg * opacity,
              ),
              accentColor.withValues(
                alpha: GameStyles.orbitalArcAlphaInner * opacity,
              ),
              Colors.white.withValues(
                alpha: GameStyles.orbitalArcAlphaInnerBg * opacity,
              ),
              Colors.white.withValues(alpha: 0.0),
            ],
            startAngle: 0.0,
            endAngle: 2 * pi,
            transform: GradientRotation(innerAngle - (pi / 2)),
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: maxRadius * GameLayout.orbitalRadiusInner,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameLayout.orbitalArcWidthInner;

    canvas.drawCircle(
      center,
      maxRadius * GameLayout.orbitalRadiusInner,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant OrbitalArcsPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.opacity != opacity;
  }
}
