import 'dart:math' as math;
import 'package:flutter/animation.dart';

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
