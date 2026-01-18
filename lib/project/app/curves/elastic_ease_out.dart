import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// ElasticEaseOut - Bouncy elastic with multiple oscillations
/// Creates 2-3 bounces that decay exponentially
class ElasticEaseOut extends Curve {
  final double amplitude;
  final double period;

  const ElasticEaseOut({this.amplitude = 0.4, this.period = 0.3});

  @override
  double transformInternal(double t) {
    if (t == 0.0 || t == 1.0) return t;

    final double s = period / 4.0;
    final double value =
        math.pow(2.0, -10.0 * t) *
            math.sin((t - s) * (math.pi * 2.0) / period) *
            amplitude +
        1.0;

    return value.clamp(0.0, 1.2); // Allow slight overshoot
  }
}
