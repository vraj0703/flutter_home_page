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
    final double dampedOmega =
        omega * math.sqrt(1.0 - dampingRatio * dampingRatio);

    // Damped harmonic oscillator formula
    final double envelope = math.exp(-dampingRatio * omega * t);
    final double phase = dampedOmega * t;
    final double value =
        1.0 -
        envelope *
            (math.cos(phase) +
                (dampingRatio * omega / dampedOmega) * math.sin(phase));

    // Ensure we end at exactly 1.0
    return value.clamp(0.0, 1.0);
  }
}
