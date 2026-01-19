/// State of the fluid indicator component
enum IndicatorState {
  /// At rest as a circle at target position
  idle,

  /// Morphing into capsule and moving to new position
  moving,

  /// Full-width sweep animation
  sweeping,
}
