import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/shine_provider.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class BoldTextRevealComponent extends TextComponent
    with HasGameReference, HasPaint
    implements ShineProvider {
  final FragmentShader shader;
  final Color baseColor;
  final Color shineColor;
  final Color edgeColor;

  double _fillProgress = 0.0;
  double _opacity = 1.0;
  double _time = 0.0;

  BoldTextRevealComponent({
    required String text,
    required TextStyle textStyle,
    required this.shader,
    this.baseColor = const Color(0xFF444444), // Dark Grey
    this.shineColor = const Color(0xFFFFFFFF), // White
    this.edgeColor = const Color(0xFFFFC107), // Gold default
    super.position,
    super.anchor = Anchor.center,
    super.priority,
  }) : super(
         text: text,
         textRenderer: TextPaint(
           style: textStyle.copyWith(foreground: Paint()..shader = shader),
         ),
       );

  // ShineProvider Implementation
  @override
  double get fillProgress => _fillProgress;

  @override
  set fillProgress(double value) {
    _fillProgress = value;
  }

  // Opacity (HasPaint override, but we need to pass it to shader)
  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    super.opacity = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    // Use same god ray position approach as FadeTextComponent (hero title)
    // This makes bold text affected by god ray lighting like the hero title

    final dpr = game.canvasSize.x / game.size.x;

    // Translate everything to PHYSICAL coordinate space
    final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
    final physicalSize = size * dpr;
    final physicalLightPos = (game as MyGame).godRay.position * dpr;

    // Metallic Shader Uniforms (same as hero title)
    // 0: uSize.x
    // 1: uSize.y
    // 2: uOffset.x
    // 3: uOffset.y
    // 4: uTime
    // 5,6,7: uBaseColor
    // 8: uOpacity
    // 9,10: uLightPos (god ray position)

    shader
      ..setFloat(0, physicalSize.x)
      ..setFloat(1, physicalSize.y)
      ..setFloat(2, physicalTopLeft.x)
      ..setFloat(3, physicalTopLeft.y)
      ..setFloat(4, _time) // Use time for animation like hero title
      ..setFloat(5, baseColor.r / 255)
      ..setFloat(6, baseColor.g / 255)
      ..setFloat(7, baseColor.b / 255)
      ..setFloat(8, opacity)
      ..setFloat(9, physicalLightPos.x)
      ..setFloat(10, physicalLightPos.y);

    super.render(canvas);
  }
}
