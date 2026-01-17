import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';
import 'wrapped_text_component.dart';

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
    final dimFactor = 0.5 + (0.5 * _highlight);
    final combined = opacity * dimFactor;

    quoteText.opacity = combined;

    authorText.textRenderer = TextPaint(
      style: (authorText.textRenderer as TextPaint).style.copyWith(
        color: Colors.white.withValues(alpha: combined),
      ),
    );

    roleText.textRenderer = TextPaint(
      style: (roleText.textRenderer as TextPaint).style.copyWith(
        color: Colors.white.withValues(
          alpha: 0.6 * combined,
        ), // Keep relative hierarchy
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final double alpha = opacity;
    if (alpha <= 0.01) return;

    final highlightFactor = 0.4 + (0.6 * _highlight);
    final finalAlpha = alpha * highlightFactor;

    final rrect = RRect.fromRectAndRadius(size.toRect(), Radius.circular(16));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05 * finalAlpha)
        ..style = PaintingStyle.fill,
    );

    final borderAlpha = 0.1 + (0.4 * _highlight);

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: borderAlpha * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + (1.0 * _highlight),
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
            fontFamily: 'Inter',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      size.x - 48,
    );
    quoteText.position = Vector2(24, 24);
    add(quoteText);

    // Author
    authorText = TextComponent(
      text: node.name,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      position: Vector2(24, size.y - 60),
    );
    add(authorText);

    // Role
    roleText = TextComponent(
      text: "${node.role}, ${node.company}",
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      position: Vector2(24, size.y - 36),
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
