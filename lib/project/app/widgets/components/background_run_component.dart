import 'dart:ui';
import 'package:flame/components.dart';

class BackgroundRunComponent extends PositionComponent
    with HasGameReference, HasPaint {
  final FragmentShader shader;
  double _time = 0;

  BackgroundRunComponent({required this.shader, super.size, super.priority}) {
    // Initialize opacity to 0 (hidden)
    opacity = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    // accessing 'opacity' from HasPaint.
    // If opacity is effectively 0, we can skip.
    if (opacity <= 0) return;

    // Pass LOGICAL resolution. FlutterFragCoord returns logical pixels.
    // Dividing by physical size made coordinates too small -> "Zoomed In" / Blurry.
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
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
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
