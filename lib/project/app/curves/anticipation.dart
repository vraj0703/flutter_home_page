import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// AnticipationCurve - Pull back before moving forward
/// Creates dramatic effect by going slightly negative before progressing
class AnticipationCurve extends Curve {
  final double anticipationStrength;

  const AnticipationCurve({this.anticipationStrength = 0.12});

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
      return -anticipationStrength +
          (1.2 + anticipationStrength) * _easeInOutCubic(phaseT);
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
