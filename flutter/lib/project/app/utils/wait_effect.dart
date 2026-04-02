import 'package:flame/effects.dart';

/// A custom effect that does nothing for a specific duration.
/// Useful for staggered animations in a [SequenceEffect].
class WaitEffect extends Effect {
  WaitEffect(double duration)
      : super(PauseEffectController(duration, progress: 0.0));

  @override
  void apply(double progress) {
    // This is a no-op. It simply consumes time in the effect lifecycle.
  }
}
