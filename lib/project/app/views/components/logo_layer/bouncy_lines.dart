import 'package:flutter_home_page/project/app/config/game_physics.dart';

class BouncyLine {
  // --- Physics Configuration ---
  final double stiffness =
      GamePhysics.bouncyLineStiffness; // How "strong" the spring is
  final double damping =
      GamePhysics.bouncyLineDamping; // How quickly it stops bouncing
  final double mass = GamePhysics.bouncyLineMass; // The "weight" of the line

  // --- State ---
  double currentPosition = 0.0;
  double targetPosition = 0.0;
  double velocity = 0.0;

  // --- Size Animation ---
  double scale = 1.0;
  final double maxScale =
      GamePhysics.bouncyLineMaxScale; // How big it gets when moving fast
  final double scaleSpeed =
      GamePhysics.bouncyLineScaleSpeed; // How fast it scales

  void update(double dt) {
    // --- Spring Physics Calculation ---
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
