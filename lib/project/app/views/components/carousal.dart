import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

import 'card.dart';

class ProjectCarouselComponent extends PositionComponent
    with HasGameReference<MyGame> {
  late PositionComponent _horizontalMover;
  final double cardWidth = GameLayout.carouselCardWidth;
  final double spacing = GameLayout.carouselSpacing;

  @override
  Future<void> onLoad() async {
    priority = 80;
    _horizontalMover = PositionComponent();
    add(_horizontalMover);
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
    position = Vector2(
      game.size.x / 2 - cardWidth / 2,
      game.size.y + GameLayout.carouselOffscreenY,
    );
  }

  void enter({bool reverse = false}) {
    final targetY = game.size.y / 2 - GameLayout.carouselCenterYOffset;

    if (reverse) {
      position.y = -GameLayout.carouselOffscreenY;
    } else {
      position.y = game.size.y + GameLayout.carouselOffscreenY;
    }

    add(
      MoveToEffect(
        Vector2(position.x, targetY),
        EffectController(
          duration: ScrollSequenceConfig.carouselEnterDuration,
          curve: GameCurves.standardReveal,
        ),
      ),
    );
  }

  void exit({bool reverse = false}) {
    // Reverse logic if needed, or consistent exit
    double targetY = game.size.y + GameLayout.carouselOffscreenY;
    if (reverse) {
      targetY = -GameLayout.carouselOffscreenY;
    }

    add(
      MoveToEffect(
        Vector2(position.x, targetY),
        EffectController(
          duration: ScrollSequenceConfig.carouselExitDuration,
          curve: GameCurves.carouselIn,
        ),
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

  void scrollTo(int index) {
    double targetX = -index * (cardWidth + spacing);
    _horizontalMover.add(
      MoveToEffect(
        Vector2(targetX, 0),
        EffectController(
          duration: ScrollSequenceConfig.carouselScrollDuration,
          curve: GameCurves.tabTransition,
        ),
      ),
    );
  }
}
