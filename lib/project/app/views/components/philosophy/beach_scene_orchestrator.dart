import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/lightning_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/bird_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/reflection_manager.dart';

/// Central orchestrator for the Beach Scene environmental systems.
/// Manages Lightning, Birds, Reflections, and Audio synchronization.
class BeachSceneOrchestrator extends Component with HasGameReference<MyGame> {
  final LightningController lightning;
  final BirdController birds;
  final ReflectionManager reflection;
  final BeachBackgroundComponent background;

  BeachSceneOrchestrator({required this.background})
    : lightning = LightningController(),
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
    birds.syncWithLightning(lightning.intensity);
    reflection.updateReflectionTexture();
    background.setWaterLevel(game.size.y * 0.55); // Tighter reflection spacing
  }
}
