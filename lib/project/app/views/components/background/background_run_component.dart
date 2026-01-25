import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class BackgroundRunComponent extends PositionComponent
    with HasGameReference, HasPaint {
  final FragmentShader shader;
  double _time = 0;

  // Warmup logic
  int _warmupFrames = 0;

  BackgroundRunComponent({required this.shader, super.size, super.priority}) {
    // Start with tiny opacity to force a render path (warmup)
    opacity = 0.001;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Shader Warmup: Render the first few frames to compile pipeline state
    if (_warmupFrames < 3) {
      _warmupFrames++;
      if (_warmupFrames == 3) {
        if (opacity <= 0.002) {
          opacity = 0.0;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;
    shader.setFloat(0, size.x);
    shader.setFloat(1, size.y);
    shader.setFloat(2, _time);

    final shaderPaint = Paint()..shader = shader;

    if (opacity < 1.0) {
      canvas.saveLayer(
        size.toRect(),
        Paint()..color = GameStyles.dimLayer.withValues(alpha: opacity),
      );
      canvas.drawRect(size.toRect(), shaderPaint);
      canvas.restore();
    } else {
      canvas.drawRect(size.toRect(), shaderPaint);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
