import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/shine_provider.dart';

class BoldTextRevealComponent extends TextComponent
    with HasGameReference, HasPaint
    implements ShineProvider {
  final FragmentShader shader;
  final Color baseColor;
  final Color shineColor;
  final Color edgeColor;

  double _fillProgress = 0.0;
  double _opacity = 1.0;

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

  // Full Shine Strength logic
  double _fullShineStrength = 0.0;

  set fullShineStrength(double value) {
    _fullShineStrength = value;
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
  void render(Canvas canvas) {
    // Standard text rendering would use the painter with the shader.
    // But we need to update uniforms BEFORE the text is painted.
    // TextPaint holds a Paint object. We can update that shader.

    final dpr = game.canvasSize.x / game.size.x;
    // Use toAbsoluteRect() to get the axis-aligned bounding box in World Space
    // This handles anchor and transforms automatically.
    final rect = toAbsoluteRect();
    final physicalTopLeft = rect.topLeft.toVector2() * dpr;
    // Use rect size to match
    final physicalSize = rect.size.toVector2() * dpr;

    // Metallic Shader Uniforms
    // 0: uSize.x
    // 1: uSize.y
    // 2: uOffset.x
    // 3: uOffset.y
    // 4: uTime
    // 5,6,7: uBaseColor
    // 8: uOpacity
    // 9,10: uLightPos

    // Calculate Light Position (LOCAL COORDINATES)
    // Shader now expects uLightPos relative to the component's TopLeft (0,0).
    // Wipe from -50% width to +150% width.
    final startX = -physicalSize.x * 0.5;
    final endX = physicalSize.x * 1.5;

    // Map fillProgress to Local X
    final lightX = lerpDouble(startX, endX, _fillProgress) ?? 0.0;

    // Center Vertically (Local Y = Height / 2)
    final lightY = physicalSize.y / 2;

    shader
      ..setFloat(0, physicalSize.x)
      ..setFloat(1, physicalSize.y)
      ..setFloat(2, physicalTopLeft.x)
      ..setFloat(3, physicalTopLeft.y)
      ..setFloat(4, _fullShineStrength) // REPURPOSED: uTime -> FullShine
      ..setFloat(5, baseColor.r)
      ..setFloat(6, baseColor.g)
      ..setFloat(7, baseColor.b)
      ..setFloat(8, opacity)
      ..setFloat(9, lightX)
      ..setFloat(10, lightY);
    // ..setFloat(11, _fullShineStrength); // REMOVED (Index Error)

    super.render(canvas);
  }
}
