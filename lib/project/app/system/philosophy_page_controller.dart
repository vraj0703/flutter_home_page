import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/widgets/components/peeling_card_stack_component.dart';

class PhilosophyPageController implements ScrollObserver {
  final PhilosophyTextComponent component;
  final PeelingCardStackComponent cardStack;
  final Vector2 initialTextPos;
  final Vector2 initialStackPos;

  PhilosophyPageController({
    required this.component,
    required this.cardStack,
    required this.initialTextPos,
    required this.initialStackPos,
  });

  @override
  void onScroll(double scrollOffset) {
    _handleText(scrollOffset);
    _handleStack(scrollOffset);
  }

  void _handleText(double scrollOffset) {
    // 1. Fade In Phase (2200 -> 2500)
    // 2. Hold Phase (2500 -> 3800) - Extended for delays
    // 3. Exit Phase (3800 -> 4100) - Slide Right

    double opacity = 0.0;
    Vector2 pos = initialTextPos.clone();

    if (scrollOffset < 2200) {
      opacity = 0.0;
      pos = initialTextPos;
    } else if (scrollOffset < 2500) {
      // Fade In
      opacity = ((scrollOffset - 2200) / 300).clamp(0.0, 1.0);
      pos = initialTextPos;
    } else if (scrollOffset < 3800) {
      // Hold Visible - STATIC
      opacity = 1.0;
      pos = initialTextPos;
    } else if (scrollOffset < 4100) {
      // Exit to RIGHT
      opacity = 1.0;

      final t = ((scrollOffset - 3800) / 300).clamp(0.0, 1.0);
      final curve = Curves.easeIn.transform(t);
      // Move to Right
      pos = initialTextPos + Vector2(0, -50) + Vector2(1000 * curve, 0);
    } else {
      // Gone
      opacity = 0.0;
      pos = initialTextPos + Vector2(1000, 0);
    }

    component.opacity = opacity;
    component.position = pos;
  }

  void _handleStack(double scrollOffset) {
    // Stack Container Master Opacity
    double stackAlpha = 1.0;
    if (scrollOffset < 2200) {
      stackAlpha = 0.0;
    } else if (scrollOffset < 2500) {
      stackAlpha = ((scrollOffset - 2200) / 300).clamp(0.0, 1.0);
    } else {
      stackAlpha = 1.0;
    }

    cardStack.opacity = stackAlpha;
    cardStack.position = initialStackPos;

    final cards = cardStack.cards;
    final peelStart = 2500.0;
    final peelDuration = 250.0;
    final peelDelay = 100.0; // Added Delay Gap

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      final myStart = peelStart + (i * (peelDuration + peelDelay));
      final myEnd = myStart + peelDuration;

      // Default State
      double lift = 0.0;
      double rotation = 0.0;
      double alpha = 0.0;
      double scale = 1.0;

      if (i == 0) {
        // Top Card
        if (scrollOffset < 2200) {
          alpha = 0.0;
        } else if (scrollOffset < 2500) {
          alpha = stackAlpha;
        } else if (scrollOffset < myEnd) {
          // Peeling
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          lift = -300.0 * t;
          rotation = 0.2 * t;
          alpha = 1.0 - t;
          scale = 1.0 + (0.1 * t);
        } else {
          // Gone
          alpha = 0.0;
          lift = -300.0;
        }
      } else {
        // Cards Below
        final prevStart = peelStart + ((i - 1) * (peelDuration + peelDelay));
        final prevEnd = prevStart + peelDuration;

        if (scrollOffset < prevStart) {
          // Hidden
          alpha = 0.0;
        } else if (scrollOffset < myStart) {
          // Reset/Wait/Reveal
          if (scrollOffset < prevEnd) {
            // Prev card is peeling, I am revealing
            final revealT = ((scrollOffset - prevStart) / peelDuration).clamp(
              0.0,
              1.0,
            );
            alpha = revealT;
            scale = 0.95 + (0.05 * revealT);
          } else {
            // Prev card finished peeling. I am waiting for my turn (Delay Gap)
            alpha = 1.0;
            scale = 1.0;
          }
        } else if (scrollOffset < myEnd) {
          // My Turn to Peel
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          lift = -300.0 * t;
          rotation = 0.2 * t * (i % 2 == 0 ? 1 : -1);
          alpha = 1.0 - t;
          scale = 1.0 + (0.1 * t);
        } else {
          // Gone
          alpha = 0.0;
          lift = -300.0;
        }
      }

      final center = cardStack.size / 2;
      card.position = center + Vector2(0, lift);
      card.angle = rotation;
      card.scale = Vector2.all(scale);
      card.opacity = alpha;
    }
  }
}
