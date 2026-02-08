import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class CirclesBackgroundComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  final FragmentShader shader;
  double _time = 0.0;
  double revealProgress = 0.0; // 0.0 to 1.0 for entry bloom effect

  CirclesBackgroundComponent({
    required this.shader,
    super.size,
    super.anchor = Anchor.topLeft,
  }) {
    opacity = 0.0; // Start hidden per architecture
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;

    shader.setFloat(0, size.x); // uSize.x
    shader.setFloat(1, size.y); // uSize.y
    shader.setFloat(2, _time); // uTime
    shader.setFloat(3, revealProgress); // uReveal for entry bloom

    final paint = Paint()..shader = shader;
    paint.color = paint.color.withOpacity(opacity);

    canvas.drawRect(size.toRect(), paint);
  }
}
