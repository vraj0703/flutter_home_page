import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';

import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_card.dart';

class TestimonialCarouselComponent extends PositionComponent with HasPaint {
  final List<TestimonialNode> data;
  final List<TestimonialCard> _cards = [];
  final List<double> _baseXPositions = [];
  final Set<int> _focusedCards = {};

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    for (final card in _cards) {
      card.opacity = val;
    }
  }

  bool get allFocused => _focusedCards.length >= data.length;

  TestimonialCarouselComponent({required this.data});

  @override
  Future<void> onLoad() async {
    double startX = 0;
    final spacing = GameLayout.testiCardSpacing;
    startX = -GameLayout.testiCardWidth / 2;

    for (var i = 0; i < data.length; i++) {
      final node = data[i];
      final card = TestimonialCard(node: node, size: GameLayout.testiCardSize);

      final baseX =
          startX +
          (i * (GameLayout.testiCardWidth + spacing)) +
          (GameLayout.testiCardWidth / 2);
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
    final centerThreshold = GameLayout.testiCarouselThreshold;

    for (int i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      card.position.x = _baseXPositions[i] + offset;

      final dist = (card.position.x).abs();
      double t = 0.0;

      if (dist < centerThreshold) {
        t = 1.0 - (dist / centerThreshold);
        // Apply easing to the time
        t = GameCurves.standardEase.transform(t);

        // Track cards that receive significant focus
        if (t > 0.8) {
          _focusedCards.add(i);
        }
      }

      final targetScale = 1.0 + (0.15 * t);
      card.scale = Vector2.all(targetScale);

      card.highlight = t;

      card.priority = (t * 100).toInt();
    }
  }
}
