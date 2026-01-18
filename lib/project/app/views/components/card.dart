import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ProjectCard extends PositionComponent {
  final int index;

  ProjectCard({
    required this.index,
    required super.size,
    required super.position,
  });

  @override
  void render(Canvas canvas) {
    // Glassmorphism look
    final rRect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
