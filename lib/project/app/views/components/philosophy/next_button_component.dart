import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors;

class NextButtonComponent extends PositionComponent
    with HasGameReference, HoverCallbacks, HasPaint {
  bool _isHovering = false;
  double _holdProgress = 0.0;
  static const double holdDuration = 1.0;

  static const double radius = 40.0;
  static const Color accentColor = Color(0xFF00FFFF); // Neon Cyan

  bool get isHovering => _isHovering;

  VoidCallback? onHoldComplete;
  VoidCallback? onReleased;
  Function(double)? onProgressChange;

  NextButtonComponent({super.position, super.anchor = Anchor.center}) {
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (opacity <= 0.0) {
      _holdProgress = 0.0;
      _isHovering = false;
      return;
    }
    final previousProgress = _holdProgress;

    if (isHovered) {
      _holdProgress = (_holdProgress + dt / holdDuration).clamp(0.0, 1.0);

      // Trigger completion callback when reaching 100%
      if (previousProgress < 1.0 && _holdProgress >= 1.0) {
        onHoldComplete?.call();
      }
    } else {
      _holdProgress = (_holdProgress - dt).clamp(0.0, 1.0); // Fast decay
    }
    onProgressChange?.call(_holdProgress);
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(size.toOffset() / 2, radius, paint);

    if (_holdProgress > 0.0) {
      final progressPaint = Paint()
        ..color = accentColor
            .withOpacity(0.8 * opacity) // Use Accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      final rect = Rect.fromCircle(
        center: size.toOffset() / 2,
        radius: radius - 2,
      );
      final sweepAngle = 2 * 3.14159 * _holdProgress.clamp(0.0, 1.0);

      canvas.drawArc(rect, -3.14159 / 2, sweepAngle, false, progressPaint);
    }

    final borderColor = _isHovering ? accentColor : Colors.white;

    final borderPaint = Paint()
      ..color = borderColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(size.toOffset() / 2, radius, borderPaint);
  }

  @override
  void onHoverEnter() {
    _isHovering = true;
    // Add a slight scale-up effect for tactile feedback
    add(ScaleEffect.to(Vector2.all(1.1), EffectController(duration: 0.2)));
  }

  @override
  void onHoverExit() {
    _isHovering = false;
    onReleased?.call();
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.2)));
  }

  /* void _handleRelease() {
    if (_isHolding) {
      _isHolding = false;
      _holdProgress = 0.0;
      onReleased?.call(); // Trigger the reset in the RainTransitionComponent
      onProgressChange?.call(0.0); // Immediately tell the shader to target 0
    }
  }
*/
  @override
  bool containsLocalPoint(Vector2 point) {
    final center = size / 2;
    return (point - center).length <= radius;
  }
}
