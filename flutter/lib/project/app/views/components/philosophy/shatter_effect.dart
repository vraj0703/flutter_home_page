import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/rain_transition_component.dart';

class ShatterEffect extends Component with HasGameReference<MyGame> {
  final VoidCallback onFinish;
  final VoidCallback? onComplete;
  final RainTransitionComponent rainTransition;
  double _timer = 0.0;
  final double duration = 0.6;
  bool _hasShattered = false;
  bool _hasCompleted = false;

  ShatterEffect({
    required this.onFinish,
    required this.rainTransition,
    this.onComplete,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    double progress = (_timer / duration).clamp(0.0, 1.0);

    // Apply easing for "snap" feel
    // explicit curve replacement for missing expoIn
    double easedProgress = Curves.easeInQuint.transform(progress);

    // 1. Update Shader
    rainTransition.setShatterProgress(easedProgress);

    // 2. Audio Trigger at "Snap" point
    if (progress > 0.1 && !_hasShattered) {
      _hasShattered = true;
      game.audio.playAsset('glass_break.mp3');
      HapticFeedback.heavyImpact();
    }

    // 3. Completion
    if (progress >= 1.0 && !_hasCompleted) {
      _hasCompleted = true;
      onComplete?.call();
      onFinish();
      removeFromParent();
    }
  }
}
