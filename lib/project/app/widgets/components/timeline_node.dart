import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TimelineNode extends PositionComponent with HasPaint {
  final bool isStart;
  final bool isEnd;

  TimelineNode({super.position, this.isStart = false, this.isEnd = false})
    : super(size: Vector2.all(20), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final center = size / 2;
    final radius = size.x / 4;

    // Outer Glow
    canvas.drawCircle(
      center.toOffset(),
      radius + 4,
      Paint()
        ..color = const Color(0xFFC78E53).withValues(alpha: 0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Inner Core
    canvas.drawCircle(
      center.toOffset(),
      radius,
      Paint()..color = const Color(0xFFE3E4E5).withValues(alpha: 1.0 * opacity),
    );
  }
}
