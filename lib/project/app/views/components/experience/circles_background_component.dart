import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class CirclesBackgroundComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  final FragmentShader shader;
  double _time = 0.0;

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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  void setScrollProgress(double progress) {}

  bool _manualWarmup = false;
  int _manualWarmupFrames = 0;

  void warmUp() {
    _manualWarmup = true;
    _manualWarmupFrames = 0;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0 && !_manualWarmup) return;

    shader.setFloat(0, size.x); // uSize.x (logical)
    shader.setFloat(1, size.y); // uSize.y (logical)
    shader.setFloat(2, _time); // uTime
    shader.setFloat(3, 1.0); // uPixelRatio (unused, kept for uniform slot)

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium;
    // During warmup, use a tiny non-zero opacity so the shader actually runs but isn't visible
    paint.color = paint.color.withValues(alpha: _manualWarmup ? 0.01 : opacity);

    canvas.drawRect(size.toRect(), paint);

    if (_manualWarmup) {
      if (_manualWarmupFrames % 10 == 0) {
        // print('CirclesBackgroundComponent: Warmup Frame $_manualWarmupFrames');
      }
      _manualWarmupFrames++;
      if (_manualWarmupFrames > 20) {
        // print('CirclesBackgroundComponent: Warmup Completed');
        _manualWarmup = false;
      }
    }
  }
}
