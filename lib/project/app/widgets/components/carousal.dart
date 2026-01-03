import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

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

  void enter() {
    add(
      MoveToEffect(
        Vector2(position.x, game.size.y / 2 - 100),
        EffectController(duration: 0.8, curve: Curves.easeOut),
      ),
    );
  }

  void exit() {
    add(
      MoveToEffect(
        Vector2(position.x, game.size.y + 400),
        EffectController(duration: 0.6, curve: Curves.easeIn),
      ),
    );
  }

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
