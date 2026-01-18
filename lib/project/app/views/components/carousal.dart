import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

import 'card.dart';

class ProjectCarouselComponent extends PositionComponent
    with HasGameReference<MyGame> {
  late PositionComponent _horizontalMover;
  final double cardWidth = 550;
  final double spacing = 50;

  @override
  Future<void> onLoad() async {
    priority = 80;
    _horizontalMover = PositionComponent();
    add(_horizontalMover);

    // Position cards inside horizontal mover
    for (int i = 0; i < 5; i++) {
      _horizontalMover.add(
        ProjectCard(
          index: i,
          size: Vector2(cardWidth, 350),
          position: Vector2(i * (cardWidth + spacing), 0),
        ),
      );
    }
    // Start HIDDEN below screen
    position = Vector2(game.size.x / 2 - cardWidth / 2, game.size.y + 400);
  }

  void enter({bool reverse = false}) {
    // Target Y: Centered (game.size.y / 2 - 100) or wherever needed.
    // Let's align with the previous target.
    final targetY = game.size.y / 2 - 100;

    if (reverse) {
      // Coming from Contact (Tab 2) -> Enter from Top
      position.y = -400;
    } else {
      // Coming from Timeline (Tab 0) -> Enter from Bottom
      position.y = game.size.y + 400;
    }

    add(
      MoveToEffect(
        Vector2(position.x, targetY),
        EffectController(duration: 0.8, curve: Curves.easeOut),
      ),
    );
  }

  void exit({bool reverse = false}) {
    final targetY = reverse ? game.size.y + 400.0 : -400.0;

    add(
      MoveToEffect(
        Vector2(position.x, targetY),
        EffectController(duration: 0.6, curve: Curves.easeIn),
      ),
    );
  }

  double get _maxScroll => (4 * (cardWidth + spacing)); // 5 cards (0-4)

  bool get isAtEnd {
    if (!isLoaded) return false;
    return _horizontalMover.position.x <= -_maxScroll - 50;
  }

  bool get isAtStart {
    if (!isLoaded) return true;
    return _horizontalMover.position.x >= 0;
  }

  void scroll(double delta) {
    if (!isLoaded) return;
    double newX = _horizontalMover.position.x - delta;

    if (newX > 0) newX = 0;
    if (newX < -_maxScroll - 100) newX = -_maxScroll - 100;

    _horizontalMover.position.x = newX;
  }

  // Keep scrollTo for potentially programmatic navigation, or remove if unused.
  void scrollTo(int index) {
    double targetX = -index * (cardWidth + spacing);
    _horizontalMover.add(
      MoveToEffect(
        Vector2(targetX, 0),
        EffectController(duration: 0.7, curve: Curves.easeInOutCubic),
      ),
    );
  }
}
