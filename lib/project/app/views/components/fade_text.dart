import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class FadeTextComponent extends TextComponent with HasPaint, HasGameReference {
  final FragmentShader shader;
  final Color baseColor;
  double _time = 0;

  FadeTextComponent({
    required super.text,
    required TextStyle textStyle,
    required this.shader,
    this.baseColor = GameStyles.fadeTextDefault,
    super.position,
    super.anchor,
    super.priority,
  }) : super(
         textRenderer: TextPaint(
           style: textStyle.copyWith(
             foreground: Paint()..shader = shader,
             shadows: [
               const Shadow(
                 color: Colors.black45,
                 blurRadius: 10,
                 offset: Offset(2, 2),
               ),
             ],
           ),
         ),
       );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    // 1. Get the Device Pixel Ratio (DPR)
    final dpr = game.canvasSize.x / game.size.x;

    // 2. Translate everything to PHYSICAL coordinate space
    // This is the only way to ensure 1:1 cursor tracking on all devices
    final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
    final physicalSize = size * dpr;
    final physicalLightPos = (game as MyGame).godRay.position * dpr;

    shader
      ..setFloat(0, physicalSize.x)
      ..setFloat(1, physicalSize.y)
      ..setFloat(2, physicalTopLeft.x)
      ..setFloat(3, physicalTopLeft.y)
      ..setFloat(4, _time)
      ..setFloat(5, baseColor.r / 255)
      ..setFloat(6, baseColor.g / 255)
      ..setFloat(7, baseColor.b / 255)
      ..setFloat(8, opacity)
      ..setFloat(9, physicalLightPos.x)
      ..setFloat(10, physicalLightPos.y);

    super.render(canvas);
  }
}
