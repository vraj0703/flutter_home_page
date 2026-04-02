import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/lightning_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/bird_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/reflection_manager.dart';
import 'dart:math' as math;

/// Central orchestrator for the Beach Scene environmental systems.
/// Manages Lightning, Birds, Reflections, and Audio synchronization.
class BeachSceneOrchestrator extends Component with HasGameReference<MyGame> {
  final LightningController lightning;
  final BirdController birds;
  final ReflectionManager reflection;
  final BeachBackgroundComponent background;

  double _currentCrackStrength = 0.0;
  double holdProgress = 0.0;

  BeachSceneOrchestrator({
    required this.background,
  }) : lightning = LightningController(),
       birds = BirdController(),
       reflection = ReflectionManager();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    addAll([lightning, birds, reflection]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final double progress = holdProgress;

    // 2. SYNC RAIN & PANIC
    birds.panicLevel = progress;
    // game.audio.playSpatialThunder(progress); // Moved to lightning trigger

    // 3. SYNC PROBABILISTIC LIGHTNING
    if (progress > 0.5) {
      // Frequency increases as progress nears 1.0
      double strikeChance = math.pow(progress, 4.0) * 0.03;
      if (math.Random().nextDouble() < strikeChance) {
        // Pass current progress to trigger the dynamic thunder delay
        lightning.triggerFlash(progress);
        game.audio.playSpatialThunder(progress);
      }
    }

    // Trigger cracks only at 100% progress during a lightning strike
    // Trigger cracks earlier (at 80% progress) and with any visible lightning
    double crackTarget = (progress > 0.8 && lightning.intensity > 0.1)
        ? 1.0
        : 0.0;
    _currentCrackStrength = lerpDouble(
      _currentCrackStrength,
      crackTarget,
      dt * 10.0,
    )!;

    // 5. HOUSEKEEPING
    birds.syncWithLightning(lightning.intensity);
    reflection.updateReflectionTexture();
    background.shader.setFloat(12, lightning.intensity);
  }
}
