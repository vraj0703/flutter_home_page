import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// Custom easing curves library for professional motion design
/// Provides spring physics, elastic bounces, anticipation, and exponential curves

/// SpringCurve - Natural spring physics with overshoot
/// Simulates damped harmonic oscillator for organic motion
class SpringCurve extends Curve {
  final double mass;
  final double stiffness;
  final double damping;

  const SpringCurve({
    this.mass = 1.0,
    this.stiffness = 180.0,
    this.damping = 12.0,
  });

  @override
  double transformInternal(double t) {
    if (t == 0.0 || t == 1.0) return t;

    // Calculate angular frequency
    final double dampingRatio = damping / (2.0 * math.sqrt(stiffness * mass));
    final double omega = math.sqrt(stiffness / mass);
    final double dampedOmega = omega * math.sqrt(1.0 - dampingRatio * dampingRatio);

    // Damped harmonic oscillator formula
    final double envelope = math.exp(-dampingRatio * omega * t);
    final double phase = dampedOmega * t;
    final double value = 1.0 - envelope * (math.cos(phase) + (dampingRatio * omega / dampedOmega) * math.sin(phase));

    // Ensure we end at exactly 1.0
    return value.clamp(0.0, 1.0);
  }
}

/// ElasticEaseOut - Bouncy elastic with multiple oscillations
/// Creates 2-3 bounces that decay exponentially
class ElasticEaseOut extends Curve {
  final double amplitude;
  final double period;

  const ElasticEaseOut({
    this.amplitude = 0.4,
    this.period = 0.3,
  });

  @override
  double transformInternal(double t) {
    if (t == 0.0 || t == 1.0) return t;

    final double s = period / 4.0;
    final double value = math.pow(2.0, -10.0 * t) *
                        math.sin((t - s) * (math.pi * 2.0) / period) *
                        amplitude + 1.0;

    return value.clamp(0.0, 1.2); // Allow slight overshoot
  }
}

/// AnticipationCurve - Pull back before moving forward
/// Creates dramatic effect by going slightly negative before progressing
class AnticipationCurve extends Curve {
  final double anticipationStrength;

  const AnticipationCurve({
    this.anticipationStrength = 0.12,
  });

  @override
  double transformInternal(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;

    // Three-phase curve
    if (t < 0.2) {
      // Phase 1: Pull back (0 → -anticipationStrength)
      final double phaseT = t / 0.2;
      return -anticipationStrength * _easeInOutCubic(phaseT);
    } else if (t < 0.8) {
      // Phase 2: Accelerate forward with overshoot (-anticipationStrength → 1.2)
      final double phaseT = (t - 0.2) / 0.6;
      return -anticipationStrength + (1.2 + anticipationStrength) * _easeInOutCubic(phaseT);
    } else {
      // Phase 3: Settle to 1.0 (1.2 → 1.0)
      final double phaseT = (t - 0.8) / 0.2;
      return 1.2 - 0.2 * _easeInOutCubic(phaseT);
    }
  }

  double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4.0 * t * t * t;
    } else {
      final double f = (2.0 * t) - 2.0;
      return 0.5 * f * f * f + 1.0;
    }
  }
}

/// ExponentialEaseOut - Very smooth, elegant deceleration
/// Creates refined, professional motion feel
class ExponentialEaseOut extends Curve {
  const ExponentialEaseOut();

  @override
  double transformInternal(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return 1.0 - math.pow(2.0, -10.0 * t);
  }
}

/// BezierCurve - Custom cubic bezier for fine control
/// Provides pre-configured options and custom control points
class BezierCurve extends Curve {
  final double p1x;
  final double p1y;
  final double p2x;
  final double p2y;

  const BezierCurve({
    required this.p1x,
    required this.p1y,
    required this.p2x,
    required this.p2y,
  });

  /// Material Design standard smooth curve
  factory BezierCurve.smooth() {
    return const BezierCurve(p1x: 0.4, p1y: 0.0, p2x: 0.2, p2y: 1.0);
  }

  /// Quick, responsive curve
  factory BezierCurve.snappy() {
    return const BezierCurve(p1x: 0.2, p1y: 0.9, p2x: 0.3, p2y: 1.0);
  }

  /// Sophisticated, elegant curve
  factory BezierCurve.elegant() {
    return const BezierCurve(p1x: 0.25, p1y: 0.1, p2x: 0.25, p2y: 1.0);
  }

  @override
  double transformInternal(double t) {
    if (t == 0.0 || t == 1.0) return t;

    // Use Newton-Raphson method to solve cubic bezier
    // Start with linear approximation
    double x = t;
    for (int i = 0; i < 8; i++) {
      final double z = _cubicBezier(x, p1x, p2x) - t;
      if (z.abs() < 0.001) break;
      final double dz = _cubicBezierDerivative(x, p1x, p2x);
      if (dz.abs() < 0.000001) break;
      x = x - z / dz;
    }

    return _cubicBezier(x, p1y, p2y);
  }

  double _cubicBezier(double t, double p1, double p2) {
    final double oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * t * p1 +
           3.0 * oneMinusT * t * t * p2 +
           t * t * t;
  }

  double _cubicBezierDerivative(double t, double p1, double p2) {
    final double oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * p1 +
           6.0 * oneMinusT * t * (p2 - p1) +
           3.0 * t * t * (1.0 - p2);
  }
}
