import 'package:flutter/animation.dart';

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
