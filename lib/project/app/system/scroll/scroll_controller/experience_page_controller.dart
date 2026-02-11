/// Controller for the Experience Section's scroll physics and state.
/// Ports the Spring Simulation from PhilosophyTrailComponent.
class ExperiencePageController {
  // Spring Physics Configuration
  static const double stiffness = 50.0;
  static const double damping = 15.0;
  static const double mass = 1.0;

  // State
  double _targetScroll = 0.0;
  double get targetScroll => _targetScroll;

  double _currentScroll = 0.0;
  double get currentScroll => _currentScroll;

  double _velocity = 0.0;

  // Callbacks
  void Function(double scroll)? onScrollUpdate;

  void setTargetScroll(double scroll) {
    _targetScroll = scroll;
  }

  void update(double dt) {
    final displacement = _targetScroll - _currentScroll;
    final force = displacement * stiffness - _velocity * damping;
    final acceleration = force / mass;

    _velocity += acceleration * dt;
    _currentScroll += _velocity * dt;

    // Snap if close and slow
    if (displacement.abs() < 0.5 && _velocity.abs() < 10.0) {
      _currentScroll = _targetScroll;
      _velocity = 0.0;
    }

    onScrollUpdate?.call(_currentScroll);
  }

  void reset() {
    _targetScroll = 0.0;
    _currentScroll = 0.0;
    _velocity = 0.0;
  }
}
