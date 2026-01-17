import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';

import 'testimonial_card.dart';

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
    double startX = 0;
    final cardWidth = 400.0;
    final cardHeight = 250.0;
    final spacing = 40.0;
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

      card.opacity = opacity;

      _cards.add(card);
      add(card);
    }
  }

  void updateScroll(double delta) {
    final offset = -delta * 0.7;
    final centerThreshold = 300.0;

    for (int i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      card.position.x = _baseXPositions[i] + offset;

      final dist = (card.position.x).abs();
      double t = 0.0;

      if (dist < centerThreshold) {
        t = 1.0 - (dist / centerThreshold);
        t = Curves.easeOutQuad.transform(t);
      }

      final targetScale = 1.0 + (0.15 * t);
      card.scale = Vector2.all(targetScale);

      card.highlight = t;

      card.priority = (t * 100).toInt();
    }
  }
}
