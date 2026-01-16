import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';
import 'package:flutter_home_page/project/app/widgets/components/wrapped_text_component.dart';

class TestimonialCarouselComponent extends PositionComponent with HasPaint {
  final List<TestimonialNode> data;
  final List<TestimonialCard> _cards = [];
  final List<double> _baseXPositions = [];

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    for (final card in _cards) {
      card.opacity = val;
    }
  }

  TestimonialCarouselComponent({required this.data});

  @override
  Future<void> onLoad() async {
    // Layout cards horizontally centered
    // For now, static layout or simple list
    // Ideally we want a swipeable carousel but user asked for "ProjectCarouselComponent" style.
    // Let's implement a simple horizontal row that centers the items.

    double startX = 0;
    final cardWidth = 400.0;
    final cardHeight = 250.0;
    final spacing = 40.0;

    // Center the first card at 0
    startX = -cardWidth / 2;

    for (var i = 0; i < data.length; i++) {
      final node = data[i];
      final card = TestimonialCard(
        node: node,
        size: Vector2(cardWidth, cardHeight),
      );

      final baseX = startX + (i * (cardWidth + spacing)) + (cardWidth / 2);
      _baseXPositions.add(baseX);

      card.position = Vector2(baseX, 0);
      card.anchor = Anchor.center;

      // Apply initial opacity
      card.opacity = opacity;

      _cards.add(card);
      add(card);
    }
  }

  void updateScroll(double delta) {
    // Move left as delta increases
    final offset = -delta * 0.7; // Speed ratio
    final centerThreshold = 300.0; // Distance where highlight starts fading

    for (int i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      card.position.x = _baseXPositions[i] + offset;

      // Highlight Logic
      final dist = (card.position.x).abs();
      double t = 0.0; // 0 = far, 1 = center

      if (dist < centerThreshold) {
        t = 1.0 - (dist / centerThreshold);
        t = Curves.easeOutQuad.transform(t); // Smooth curve
      }

      // Apply Scale
      final targetScale = 1.0 + (0.15 * t); // 1.0 -> 1.15
      card.scale = Vector2.all(targetScale);

      // Apply Highlight
      card.highlight = t;

      // Optional: Z-index (priority)
      // center one on top
      card.priority = (t * 100).toInt();
    }
  }
}

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
    // Combined alpha = global opacity * (dim factor based on highlight)
    // dim factor: 0.5 (side) -> 1.0 (center)
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

    // Dim non-highlighted cards
    // Base alpha for "dimmed" state = 0.5?
    final highlightFactor = 0.4 + (0.6 * _highlight);
    final finalAlpha = alpha * highlightFactor;

    // Card Background
    final rrect = RRect.fromRectAndRadius(size.toRect(), Radius.circular(16));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05 * finalAlpha)
        ..style = PaintingStyle.fill,
    );

    // Border - Highlight gets brighter border
    final borderAlpha = 0.1 + (0.4 * _highlight);

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
            .withValues(alpha: borderAlpha * alpha) // Border glow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + (1.0 * _highlight), // Thicker border
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

    // Ensure initial text opacity matches card opacity
    _updateTextOpacity();
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (isLoaded) _updateTextOpacity();
  }
}
