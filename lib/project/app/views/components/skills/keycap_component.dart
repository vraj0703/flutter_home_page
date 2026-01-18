import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class KeycapComponent extends PositionComponent with HasPaint, HasGameReference {
  final String label;
  final FragmentShader? shader;
  final bool isHeroKey;
  double _time = 0.0;

  KeycapComponent({
    required this.label,
    required Vector2 size,
    this.shader,
  })  : isHeroKey = ["Flutter", "Dart", "Flame"].contains(label),
        super(size: size);

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    // Update text child
    for (final child in children) {
      if (child is TextComponent) {
        final style = (child.textRenderer as TextPaint).style;
        child.textRenderer = TextPaint(
          style: style.copyWith(color: style.color?.withValues(alpha: val)),
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void renderTree(Canvas canvas) {
    if (opacity == 0.0) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0.0) return;

    // Set shader uniforms for hero keys
    if (isHeroKey && shader != null) {
      final dpr = game.canvasSize.x / game.size.x;
      final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
      final physicalSize = size * dpr;
      final physicalLightPos = (game as MyGame).godRay.position * dpr;

      shader!
        ..setFloat(0, physicalSize.x)
        ..setFloat(1, physicalSize.y)
        ..setFloat(2, physicalTopLeft.x)
        ..setFloat(3, physicalTopLeft.y)
        ..setFloat(4, _time)
        ..setFloat(5, 0.9) // Bright silver base color
        ..setFloat(6, 0.9)
        ..setFloat(7, 0.95)
        ..setFloat(8, opacity)
        ..setFloat(9, physicalLightPos.x)
        ..setFloat(10, physicalLightPos.y);
    }

    final depth = GameLayout.keyboardKeyDepth;
    final radius = GameLayout.keyboardKeyRadius;

    // Cast shadow on chassis
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-2, depth + 2, size.x + 4, 3),
        Radius.circular(radius),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // Side Face (Darker)
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, depth, size.x, size.y),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      sideRect,
      Paint()..color = GameStyles.keySide.withValues(alpha: opacity),
    ); // Dark Side

    // Top Face with gradient lighting
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(radius),
    );

    final color = isHeroKey ? GameStyles.keyHighlight : GameStyles.keyTop;

    // Create gradient lighting for enhanced 3D effect
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: opacity * 1.0),
        color.withValues(alpha: opacity * 0.7),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..shader = topGradient.createShader(rect);

    canvas.drawRRect(topRect, paint);

    super.render(canvas);
  }

  @override
  Future<void> onLoad() async {
    TextStyle textStyle = TextStyle(
      fontFamily: GameStyles.fontInter,
      fontSize: isHeroKey ? 12.0 : GameStyles.keyFontSize,
      fontWeight: isHeroKey ? FontWeight.w900 : FontWeight.bold,
      color: isHeroKey
          ? const Color(0xFFFFD700)
          : GameStyles.keyTextNormal,
    );

    // For hero keys: apply shader to foreground
    if (isHeroKey && shader != null) {
      textStyle = textStyle.copyWith(
        foreground: Paint()..shader = shader,
      );
    }

    final queryText = TextComponent(
      text: label,
      textRenderer: TextPaint(style: textStyle),
    );
    queryText.anchor = Anchor.center;
    queryText.position = Vector2(size.x / 2, size.y / 2);
    add(queryText);
  }
}
