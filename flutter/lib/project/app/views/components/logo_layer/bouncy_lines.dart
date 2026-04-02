import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';

class BouncyLine {
  // --- Physics Configuration ---
  final SpringCurve spring = GameCurves.bouncyLineSpring;
  final double mass = GameCurves.bouncyLineMass;

  // --- State ---
  double currentPosition = 0.0;
  double targetPosition = 0.0;
  double velocity = 0.0;

  // --- Size Animation ---
  double scale = 1.0;
  final double maxScale = GamePhysics.bouncyLineMaxScale;
  final double scaleSpeed = GamePhysics.bouncyLineScaleSpeed;

  void update(double dt) {
    // --- Spring Physics Calculation ---
    // Access properties from the initialized spring curve
    final double stiffness = spring.stiffness;
    final double damping = spring.damping;
    final double mass = spring.mass;

    final double springForce = (targetPosition - currentPosition) * stiffness;
    final double dampingForce = -velocity * damping;
    final double totalForce = springForce + dampingForce;
    final double acceleration = totalForce / mass;
    velocity += acceleration * dt;
    currentPosition += velocity * dt;

    // --- Scale Animation Calculation ---
    final double targetScale =
        1.0 +
        (velocity.abs() / GamePhysics.bouncyLineVelocityScaleFactor).clamp(
          0,
          maxScale - 1.0,
        );
    scale = scale + (targetScale - scale) * scaleSpeed * dt;
  }
}
