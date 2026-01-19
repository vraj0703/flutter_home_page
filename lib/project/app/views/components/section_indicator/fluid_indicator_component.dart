import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Colors;
import 'indicator_state.dart';

/// Fluid morphing indicator that moves between static dots
class FluidIndicatorComponent extends PositionComponent {
  static const double baseSize = 12.0;
  static const double capsuleRatio = 3.0; // Width = 3x height when moving
  static const double massPreservation = 0.08; // Height decreases 8% when stretching
  static const Color activeColor = Color(0xFFFFC107); // Gold

  IndicatorState _state = IndicatorState.idle;
  double _morphProgress = 0.0; // 0.0 = circle, 1.0 = capsule
  double _settleProgress = 0.0; // For overshoot/settle animation
  Vector2 _targetPosition = Vector2.zero();
  Vector2 _startPosition = Vector2.zero();
  double _moveProgress = 0.0;
  double _moveDuration = 1.0;
  double _moveElapsed = 0.0;

  final Paint _paint = Paint()
    ..color = activeColor
    ..style = PaintingStyle.fill;

  final Paint _glowPaint = Paint()
    ..color = activeColor.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  FluidIndicatorComponent({required Vector2 initialPosition}) {
    position = initialPosition;
    _targetPosition = initialPosition.clone();
    _startPosition = initialPosition.clone();
    anchor = Anchor.center;
  }

  IndicatorState get state => _state;

  /// Trigger movement to a new target position
  void moveTo(Vector2 target, double duration) {
    if (_state == IndicatorState.moving) {
      // Already moving, update target mid-flight
      _startPosition = position.clone();
    } else {
      _startPosition = position.clone();
    }

    _targetPosition = target.clone();
    _state = IndicatorState.moving;
    _moveProgress = 0.0;
    _moveElapsed = 0.0;
    _moveDuration = duration;
    _morphProgress = 0.0;
    _settleProgress = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (_state) {
      case IndicatorState.idle:
        // Gently breathe back to perfect circle if needed
        _morphProgress = math.max(0.0, _morphProgress - dt * 4.0);
        _settleProgress = math.max(0.0, _settleProgress - dt * 3.0);
        break;

      case IndicatorState.moving:
        _moveElapsed += dt;
        final rawProgress = (_moveElapsed / _moveDuration).clamp(0.0, 1.0);

        // Bezier curve with peak velocity at 50%
        _moveProgress = _bezierEase(rawProgress);

        // Morph progress: stretch quickly, hold, then snap back
        if (rawProgress < 0.3) {
          // Stretch phase (0 -> 1 in first 30%)
          _morphProgress = (rawProgress / 0.3).clamp(0.0, 1.0);
        } else if (rawProgress < 0.7) {
          // Hold capsule shape during main movement
          _morphProgress = 1.0;
        } else {
          // Snap back phase (1 -> 0 in last 30%)
          _morphProgress = (1.0 - (rawProgress - 0.7) / 0.3).clamp(0.0, 1.0);
        }

        // Update position
        position = Vector2.lerp(_startPosition, _targetPosition, _moveProgress);

        // Check if done
        if (rawProgress >= 1.0) {
          position = _targetPosition.clone();
          _state = IndicatorState.idle;
          _morphProgress = 1.0;
          _settleProgress = 1.0; // Trigger settle animation
        }
        break;

      case IndicatorState.sweeping:
        // TODO: Implement sweep animation if needed
        break;
    }

    // Settle animation (overshoot and vibrate)
    if (_settleProgress > 0.0) {
      _settleProgress = math.max(0.0, _settleProgress - dt * 5.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate dimensions based on morph progress
    final morphT = _morphProgress;

    // Width: 1x (circle) to 3x (capsule)
    final width = baseSize * (1.0 + (capsuleRatio - 1.0) * morphT);

    // Height: 1x to 0.92x (mass preservation)
    final height = baseSize * (1.0 - massPreservation * morphT);

    // Settle overshoot (easeOutBack effect)
    double settleScale = 1.0;
    if (_settleProgress > 0.0) {
      // Overshoot by 10% then settle
      final overshoot = Curves.easeOutBack.transform(1.0 - _settleProgress);
      settleScale = 1.0 + overshoot * 0.1;
    }

    final finalWidth = width * settleScale;
    final finalHeight = height * settleScale;

    // Border radius: full circle when idle, reduced when capsule
    final radiusX = finalWidth / 2;
    final radiusY = finalHeight / 2;

    // Draw glow
    final glowRect = Rect.fromCenter(
      center: Offset(0, 0),
      width: finalWidth + 6,
      height: finalHeight + 6,
    );
    final glowRRect = RRect.fromRectAndRadius(
      glowRect,
      Radius.elliptical(radiusX + 3, radiusY + 3),
    );
    canvas.drawRRect(glowRRect, _glowPaint);

    // Draw core
    final coreRect = Rect.fromCenter(
      center: Offset(0, 0),
      width: finalWidth,
      height: finalHeight,
    );
    final coreRRect = RRect.fromRectAndRadius(
      coreRect,
      Radius.elliptical(radiusX, radiusY),
    );
    canvas.drawRRect(coreRRect, _paint);

    // Draw highlight
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.6);
    final highlightRect = Rect.fromCenter(
      center: Offset(-finalWidth * 0.15, -finalHeight * 0.15),
      width: finalWidth * 0.25,
      height: finalHeight * 0.25,
    );
    final highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.elliptical(radiusX * 0.25, radiusY * 0.25),
    );
    canvas.drawRRect(highlightRRect, highlightPaint);
  }

  /// Bezier curve with peak velocity at 50% (center-to-edge velocity)
  double _bezierEase(double t) {
    // Cubic bezier: (0,0), (0.25, 0.1), (0.75, 0.9), (1,1)
    // This creates acceleration in first half, deceleration in second half
    const p0 = 0.0;
    const p1 = 0.25;
    const p2 = 0.75;
    const p3 = 1.0;

    final oneMinusT = 1.0 - t;
    return p0 * math.pow(oneMinusT, 3) +
        3 * p1 * math.pow(oneMinusT, 2) * t +
        3 * p2 * oneMinusT * math.pow(t, 2) +
        p3 * math.pow(t, 3);
  }
}
