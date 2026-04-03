import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

/// A text component rendered with a metallic fragment shader.
///
/// IMPORTANT: Each instance creates its OWN [FragmentShader] from the given
/// [shaderProgram]. This is critical because Flutter's canvas records draw
/// commands lazily — if multiple components share one shader and each sets
/// different uniforms (position, opacity), later components overwrite the
/// uniforms before earlier components' draws execute on the GPU, causing
/// flickering and opacity contamination.
class FadeTextComponent extends TextComponent with HasPaint, HasGameReference {
  final FragmentProgram shaderProgram;
  late final FragmentShader _ownShader;
  final Color baseColor;
  double _time = 0;

  FadeTextComponent({
    required super.text,
    required TextStyle textStyle,
    required this.shaderProgram,
    this.baseColor = GameStyles.fadeTextDefault,
    super.position,
    super.anchor,
    super.priority,
  }) : _ownShader = shaderProgram.fragmentShader(),
       super(
         textRenderer: TextPaint(
           style: textStyle.copyWith(
             // Placeholder paint — replaced in onLoad with own shader instance
             foreground: Paint(),
             shadows: [
               const Shadow(
                 color: GameStyles.textShadowColor,
                 blurRadius: GameStyles.textShadowBlur,
                 offset: Offset(
                   GameStyles.textShadowOffsetX,
                   GameStyles.textShadowOffsetY,
                 ),
               ),
             ],
           ),
         ),
       ) {
    // Set the TextPaint's foreground shader to our OWN instance
    final currentStyle = (textRenderer as TextPaint).style;
    textRenderer = TextPaint(
      style: currentStyle.copyWith(
        foreground: Paint()..shader = _ownShader,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    final dpr = game.canvasSize.x / game.size.x;
    final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
    final physicalSize = size * dpr;
    final physicalLightPos = (game as MyGame).godRay.position * dpr;

    _ownShader
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
