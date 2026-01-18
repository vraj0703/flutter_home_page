import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class KeycapComponent extends PositionComponent with HasPaint {
  final String label;

  KeycapComponent({required this.label, required Vector2 size})
    : super(size: size);

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
  void renderTree(Canvas canvas) {
    if (opacity == 0.0) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0.0) return;

    final depth = GameLayout.keyboardKeyDepth;
    final radius = GameLayout.keyboardKeyRadius;

    // Side Face (Darker)
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, depth, size.x, size.y),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      sideRect,
      Paint()..color = GameStyles.keySide.withValues(alpha: opacity),
    ); // Dark Side

    // Top Face
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(radius),
    );

    final isHighlighted = ["Flutter", "Dart", "Flame"].contains(label);
    final color = isHighlighted ? GameStyles.keyHighlight : GameStyles.keyTop;

    canvas.drawRRect(
      topRect,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  Future<void> onLoad() async {
    final isHighlighted = ["Flutter", "Dart", "Flame"].contains(label);
    final queryText = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.keyFontSize,
          fontWeight: FontWeight.bold,
          color: isHighlighted
              ? GameStyles.keyTextHighlight
              : GameStyles.keyTextNormal,
        ),
      ),
    );
    queryText.anchor = Anchor.center;
    queryText.position = Vector2(size.x / 2, size.y / 2);
    add(queryText);
  }
}
