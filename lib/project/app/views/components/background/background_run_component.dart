import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class BackgroundRunComponent extends PositionComponent
    with HasGameReference, HasPaint {
  final FragmentShader shader;
  double _time = 0;

  BackgroundRunComponent({required this.shader, super.size, super.priority}) {
    opacity = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;
    shader.setFloat(0, size.x); // uResolution.x
    shader.setFloat(1, size.y); // uResolution.y
    shader.setFloat(2, _time); // uTime

    // We use a local paint for drawing the shader,
    // but we use the opacity from HasPaint to control visibility.
    final shaderPaint = Paint()..shader = shader;

    if (opacity < 1.0) {
      // Use saveLayer to apply transparency to the shader output
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
