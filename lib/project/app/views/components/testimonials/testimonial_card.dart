import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';
import '../wrapped_text_component.dart';

class TestimonialCard extends PositionComponent with HasPaint {
  final TestimonialNode node;

  TestimonialCard({required this.node, required Vector2 size})
    : super(size: size);

  late WrappedTextComponent quoteText;
  late TextComponent authorText;
  late TextComponent roleText;

  double _highlight = 0.0;

  set highlight(double val) {
    if (_highlight == val) return;
    _highlight = val;
    if (isLoaded) _updateTextOpacity();
  }

  void _updateTextOpacity() {
    final dimFactor =
        GameStyles.testiDimFactorBase +
        (GameStyles.testiDimFactorBase * _highlight);
    final combined = opacity * dimFactor;

    quoteText.opacity = combined;

    authorText.textRenderer = TextPaint(
      style: (authorText.textRenderer as TextPaint).style.copyWith(
        color: Colors.white.withValues(alpha: combined),
      ),
    );

    roleText.textRenderer = TextPaint(
      style: (roleText.textRenderer as TextPaint).style.copyWith(
        color: Colors.white.withValues(alpha: 0.6 * combined),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final double alpha = opacity;
    if (alpha <= 0.01) return;

    final highlightFactor = 0.4 + (0.6 * _highlight);
    final finalAlpha = alpha * highlightFactor;

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      Radius.circular(GameLayout.testiCardRadius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(
          alpha: GameStyles.testiFillAlpha * finalAlpha,
        )
        ..style = PaintingStyle.fill,
    );

    final borderAlpha =
        GameStyles.testiBorderAlphaBase +
        ((0.5 - GameStyles.testiBorderAlphaBase) * _highlight);

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: borderAlpha * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameStyles.testiBorderWidth + (1.0 * _highlight),
    );
  }

  @override
  Future<void> onLoad() async {
    // Quote
    quoteText = WrappedTextComponent(
      TextPainter(
        text: TextSpan(
          text: '"${node.quote}"',
          style: TextStyle(
            fontFamily: GameStyles.fontInter,
            fontSize: GameStyles.testiQuoteFontSize,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: GameStyles.testiQuoteAlpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      size.x - (GameLayout.testiCardPadding * 2),
    );
    quoteText.position = Vector2(
      GameLayout.testiCardPadding,
      GameLayout.testiCardPadding,
    );
    add(quoteText);

    // Author
    authorText = TextComponent(
      text: node.name,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.testiAuthorFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      position: Vector2(
        GameLayout.testiCardPadding,
        size.y - GameLayout.testiAuthorBtmMargin,
      ),
    );
    add(authorText);

    // Role
    roleText = TextComponent(
      text: "${node.role}, ${node.company}",
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.testiRoleFontSize,
          color: GameStyles.white.withValues(alpha: 0.6),
        ),
      ),
      position: Vector2(
        GameLayout.testiCardPadding,
        size.y - GameLayout.testiRoleBtmMargin,
      ),
    );
    add(roleText);

    _updateTextOpacity();
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (isLoaded) _updateTextOpacity();
  }
}
