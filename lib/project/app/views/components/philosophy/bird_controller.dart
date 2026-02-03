import 'dart:ui';
import 'package:flame/components.dart';

class BirdController extends Component {
  double panicLevel = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    // Decay panic level over time (will be updated by orchestrator)
    panicLevel = lerpDouble(panicLevel, 0.0, dt * 1.5)!;
  }

  /// Called by orchestrator to sync panic with lightning intensity
  void syncWithLightning(double lightningIntensity) {
    // Panic spikes instantly but lingers via decay in update()
    if (lightningIntensity > panicLevel) {
      panicLevel = lightningIntensity;
    }
  }
}
