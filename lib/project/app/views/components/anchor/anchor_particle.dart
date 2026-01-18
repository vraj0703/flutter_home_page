import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/anchor_config.dart';

/// Individual particle for the orbital anchor's trailing effect.
/// Particles fade out over their lifetime creating a motion trail.
class AnchorParticle extends PositionComponent {
  final Color color;
  double lifetime;
  final double maxLifetime;
  final double size;
  double opacity;

  AnchorParticle({
    required Vector2 position,
    required this.color,
    required this.maxLifetime,
    required this.size,
  })  : lifetime = 0.0,
        opacity = AnchorConfig.particleOpacityStart,
        super(position: position, size: Vector2.all(size), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    // Age the particle
    lifetime += dt;

    // Fade out over lifetime
    final lifeProgress = (lifetime / maxLifetime).clamp(0.0, 1.0);
    opacity = AnchorConfig.particleOpacityStart *
        (1.0 - lifeProgress) *
        AnchorConfig.particleFadeSpeed;

    // Mark for removal when fully faded
    if (lifetime >= maxLifetime || opacity <= 0.01) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size * 0.3,
      );

    // Draw particle as glowing circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );
  }
}
