class BouncyLine {
  // --- Physics Configuration ---
  final double stiffness = 500.0; // How "strong" the spring is
  final double damping = 70.0; // How quickly it stops bouncing
  final double mass = 20.0; // The "weight" of the line

  // --- State ---
  double currentPosition = 0.0;
  double targetPosition = 0.0;
  double velocity = 0.0;

  // --- Size Animation ---
  double scale = 1.0;
  final double maxScale = 2; // How big it gets when moving fast
  final double scaleSpeed = 15.0; // How fast it scales

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
        1.0 + (velocity.abs() / 150.0).clamp(0, maxScale - 1.0);
    scale = scale + (targetScale - scale) * scaleSpeed * dt;
  }
}
