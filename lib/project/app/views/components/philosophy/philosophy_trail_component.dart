import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'philosophy_card.dart';

class PhilosophyTrailComponent extends PositionComponent
    with HasGameReference, HasPaint {
  final List<PhilosophyCard> cards = [];
  final List<bool> _hasPlayedAudio = [false, false, false, false];

  // We store the calculated positions here
  final List<Vector2> _targetPositions = [];

  PhilosophyTrailComponent()
    : super(anchor: Anchor.topLeft); // Use topLeft for the container

  @override
  Future<void> onLoad() async {
    // 1. Ensure the component itself covers the whole screen
    size = game.size;

    for (int i = 0; i < 4; i++) {
      final card = PhilosophyCard(data: cardData[i], index: i, totalCards: 4);

      card.opacity = 0.0;
      card.parentOpacity = 1.0;
      card.anchor = Anchor.center; // Critical for the math below
      cards.add(card);
      _targetPositions.add(Vector2.zero());
      add(card);
    }

    _layoutCards();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size; // Maintain full-screen size
    _layoutCards();
  }

  void _layoutCards() {
    if (cards.isEmpty) return;

    // MATH CALCULATION FOR CENTERING
    final n = cards.length;

    // 1. Determine card size based on screen width (roughly 18% of screen)
    double cardWidth = (size.x * 0.18).clamp(150.0, 250.0);
    double cardHeight = cardWidth * 1.4;
    double spacing = 20.0; // Gap between cards

    // 2. Calculate the total width of the 4-card block
    double totalBlockWidth = (n * cardWidth) + ((n - 1) * spacing);

    // 3. Find the starting X (left edge of the first card)
    // We subtract half the block width from the screen center
    double startX = (size.x / 2) - (totalBlockWidth / 2);

    // 4. Center Y (Middle of screen)
    double centerY = size.y / 2;

    for (int i = 0; i < n; i++) {
      cards[i].size = Vector2(cardWidth, cardHeight);

      // Target X is startX + previous cards + half of own width (because anchor is center)
      double targetX = startX + (i * (cardWidth + spacing)) + (cardWidth / 2);

      _targetPositions[i].setValues(targetX, centerY);

      // If progress hasn't started yet, keep them at target but invisible
      // OR move them off-screen if you want them to fly in later
      if (cards[i].opacity == 0) {
        cards[i].position = Vector2(
          targetX,
          centerY + 500,
        ); // Start below screen
      }
    }
  }

  /// Call this from your Page/Game scroll listener
  void updateTrailAnimation(double progress) {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // Staggered arrival logic
      final double startTrigger = i * 0.1;
      final double endTrigger = startTrigger + 0.4;
      double t = ((progress - startTrigger) / (endTrigger - startTrigger))
          .clamp(0.0, 1.0);

      if (t <= 0) {
        card.opacity = 0;
        continue;
      }

      // Physics: Use a smooth Ease-Out curve
      final curve = Curves.easeOutCubic.transform(t);

      final targetPos = _targetPositions[i];
      // Fly in from bottom-center
      final startPos = Vector2(targetPos.x, size.y + 200);

      // Interpolate position
      card.position = startPos + (targetPos - startPos) * curve;

      // Fade and scale
      card.opacity = t;
      card.scale = Vector2.all(0.8 + (0.2 * curve));

      // Subtilt: Card 0 & 1 tilt left, 2 & 3 tilt right
      double maxTilt = 0.05; // radians
      card.angle = (i < 2 ? -maxTilt : maxTilt) * (1 - curve);

      // Sound trigger
      if (t > 0.95 && !_hasPlayedAudio[i]) {
        (game as MyGame).playTrailCardSound(i);
        _hasPlayedAudio[i] = true;
      }
    }
  }
}
