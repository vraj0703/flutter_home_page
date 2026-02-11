import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

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

  void setScrollProgress(double progress) {
    // visual feedback for scroll
    angle = progress * 0.5;
  }

  bool _manualWarmup = false;
  int _manualWarmupFrames = 0;

  void warmUp() {
    _manualWarmup = true;
    _manualWarmupFrames = 0;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0 && !_manualWarmup) return;

    shader.setFloat(0, size.x); // uSize.x
    shader.setFloat(1, size.y); // uSize.y
    shader.setFloat(2, _time); // uTime
    shader.setFloat(3, revealProgress); // uReveal for entry bloom

    // Pass Theme Color (uThemeColor) - Index 4
    // Using GameStyles.primaryBackground (Gold/Bronze)
    final color = GameStyles.primaryBackground;
    shader.setFloat(4, color.r / 255.0);
    shader.setFloat(5, color.g / 255.0);
    shader.setFloat(6, color.b / 255.0);

    final paint = Paint()..shader = shader;
    // During warmup, use a tiny non-zero opacity so the shader actually runs but isn't visible
    paint.color = paint.color.withValues(alpha: _manualWarmup ? 0.01 : opacity);

    canvas.drawRect(size.toRect(), paint);

    if (_manualWarmup) {
      // Force a non-zero reveal during warmup to exercise that shader branch
      shader.setFloat(3, 0.5);

      if (_manualWarmupFrames % 10 == 0) {
        // print('CirclesBackgroundComponent: Warmup Frame $_manualWarmupFrames');
      }
      _manualWarmupFrames++;
      if (_manualWarmupFrames > 20) {
        // print('CirclesBackgroundComponent: Warmup Completed');
        _manualWarmup = false;
        // Reset uniform
        shader.setFloat(3, revealProgress);
      }
    }
  }
}
