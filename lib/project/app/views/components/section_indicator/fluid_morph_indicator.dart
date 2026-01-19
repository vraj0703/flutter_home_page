import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Colors, Curves;

/// State of the morphing indicator
enum MorphState {
  /// At rest as a circle
  idle,
  /// Morphing and moving to new position
  transitioning,
}

/// Fluid morphing indicator that stretches vertically when moving
class FluidMorphIndicator extends PositionComponent {
  static const double baseSize = 12.0;
  static const double stretchRatio = 3.0; // Height = 3x width when fully stretched
  static const double massConservation = 0.08; // Width decreases 8% when stretching
  static const Color activeColor = Color(0xFFFFC107); // Gold
  static const Color glowColor = Color(0x4DFFC107); // Gold with 30% opacity

  MorphState _state = MorphState.idle;

  // Movement animation
  Vector2 _startPosition = Vector2.zero();
  Vector2 _targetPosition = Vector2.zero();
  double _transitionDuration = 1.0;
  double _transitionElapsed = 0.0;

  // Morphing animation (0.0 = circle, 1.0 = full vertical capsule)
  double _morphProgress = 0.0;

  // Settle animation (overshoot effect)
  double _settleIntensity = 0.0;

  final Paint _corePaint = Paint()
    ..color = activeColor
    ..style = PaintingStyle.fill;

  final Paint _glowPaint = Paint()
    ..color = glowColor
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

  FluidMorphIndicator({required Vector2 initialPosition}) {
    position = initialPosition.clone();
    _startPosition = initialPosition.clone();
    _targetPosition = initialPosition.clone();
    anchor = Anchor.center;
  }

  MorphState get state => _state;

  /// Initiate movement to new target position
  void moveTo(Vector2 target, double duration) {
    _startPosition = position.clone();
    _targetPosition = target.clone();
    _transitionDuration = duration;
    _transitionElapsed = 0.0;
    _state = MorphState.transitioning;
    _morphProgress = 0.0;
    _settleIntensity = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_state == MorphState.idle) {
      // Decay any residual morph/settle effects
      _morphProgress = math.max(0.0, _morphProgress - dt * 4.0);
      _settleIntensity = math.max(0.0, _settleIntensity - dt * 6.0);
      return;
    }

    // Transitioning state
    _transitionElapsed += dt;
    final rawProgress = (_transitionElapsed / _transitionDuration).clamp(0.0, 1.0);

    // Apply bezier curve for center-to-edge velocity (peak at 50%)
    final moveProgress = _cubicBezier(rawProgress, 0.25, 0.1, 0.75, 0.9);

    // Morph timing:
    // 0-30%: Stretch into vertical capsule (anticipation)
    // 30-70%: Hold capsule shape during main movement (action)
    // 70-100%: Snap back to circle (follow-through)
    if (rawProgress < 0.3) {
      // Stretch phase
      _morphProgress = Curves.easeOutCubic.transform(rawProgress / 0.3);
    } else if (rawProgress < 0.7) {
      // Hold at full stretch
      _morphProgress = 1.0;
    } else {
      // Snap back phase with slight overshoot
      final snapProgress = (rawProgress - 0.7) / 0.3;
      _morphProgress = 1.0 - Curves.easeOutBack.transform(snapProgress);
    }

    // Update position using bezier-eased progress
    position = Vector2.lerp(_startPosition, _targetPosition, moveProgress);

    // Check if transition complete
    if (rawProgress >= 1.0) {
      position = _targetPosition.clone();
      _state = MorphState.idle;
      _settleIntensity = 1.0; // Trigger settle animation
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate morph dimensions
    // Vertical stretch: height increases, width decreases (mass preservation)
    final morphT = _morphProgress;

    final width = baseSize * (1.0 - massConservation * morphT);
    final height = baseSize * (1.0 + (stretchRatio - 1.0) * morphT);

    // Apply settle overshoot (easeOutBack creates bounce effect)
    double settleScale = 1.0;
    if (_settleIntensity > 0.0) {
      // Overshoot and settle pattern
      final decayT = 1.0 - _settleIntensity;
      final overshoot = math.sin(decayT * math.pi * 3) * (1.0 - decayT);
      settleScale = 1.0 + overshoot * 0.15;
    }

    final finalWidth = width * settleScale;
    final finalHeight = height * settleScale;

    // Calculate border radii for pill shape
    final radiusX = finalWidth / 2;
    final radiusY = math.min(finalHeight / 2, radiusX); // Cap to maintain pill shape

    final center = Offset.zero;

    // Draw glow layer
    final glowRect = Rect.fromCenter(
      center: center,
      width: finalWidth + 8,
      height: finalHeight + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, Radius.circular(radiusX + 4)),
      _glowPaint,
    );

    // Draw core body
    final coreRect = Rect.fromCenter(
      center: center,
      width: finalWidth,
      height: finalHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(radiusX)),
      _corePaint,
    );

    // Draw specular highlight (water droplet effect)
    final highlightSize = finalWidth * 0.3;
    final highlightOffset = Offset(-finalWidth * 0.2, -finalHeight * 0.25);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7);

    canvas.drawCircle(
      center + highlightOffset,
      highlightSize / 2,
      highlightPaint,
    );
  }

  /// Cubic bezier interpolation
  double _cubicBezier(double t, double p1, double p2, double p3, double p4) {
    final u = 1.0 - t;
    return 3 * u * u * t * p1 +
        3 * u * t * t * p3 +
        t * t * t;
  }
}
