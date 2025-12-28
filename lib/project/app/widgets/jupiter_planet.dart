import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class JupiterComponent extends PositionComponent {
  final FragmentShader shader;
  double _time = 0;

  JupiterComponent({
    required this.shader,
    super.position,
    super.size,
    super.scale,
    super.anchor,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    shader.setFloat(0, size.x); // uResolution.x
    shader.setFloat(1, size.y); // uResolution.y
    shader.setFloat(2, _time); // uTime

    final paint = Paint()..shader = shader;
    canvas.drawRect(size.toRect(), paint);
  }
}
