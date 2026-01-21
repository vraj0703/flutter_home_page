import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

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
    const exponentialEaseOut = ExponentialEaseOut();

    double opacity = 0.0;
    double scale = 0.0;
    Vector2 pos = initialTextPos.clone();

    if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      opacity = 0.0;
      scale = 0.0;
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyFadeInEnd) {
      final t =
          ((scrollOffset - ScrollSequenceConfig.philosophyStart) /
                  (ScrollSequenceConfig.philosophyFadeInEnd -
                      ScrollSequenceConfig.philosophyStart))
              .clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
      // Zoom in from 0.5 to 1.0
      scale = 0.5 + (0.5 * exponentialEaseOut.transform(t));
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyExitStart) {
      opacity = 1.0;
      scale = 1.0;
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyEnd) {
      final t =
          ((scrollOffset - ScrollSequenceConfig.philosophyExitStart) /
                  (ScrollSequenceConfig.philosophyEnd -
                      ScrollSequenceConfig.philosophyExitStart))
              .clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      opacity = 1.0 - curvedT;
      scale = 1.0;
      pos = initialTextPos + (GameLayout.philExitVector * curvedT);
    } else {
      scale = 1.0;
      pos = initialTextPos + GameLayout.philExitVector;
    }

    component.opacity = opacity;
    component.scale = Vector2.all(scale);
    component.position = pos;
  }

  void _handleStack(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = GameCurves.philosophySpring;

    // Start card after text is fully visible (philosophyFadeInEnd)
    double stackAlpha = 0.0;
    const cardDelayAfterText = 200.0; // 200px delay after text appears
    final cardStartScroll =
        ScrollSequenceConfig.philosophyFadeInEnd + cardDelayAfterText;

    if (scrollOffset < cardStartScroll) {
      stackAlpha = 0.0;
    } else if (scrollOffset < cardStartScroll + 300.0) {
      stackAlpha = exponentialEaseOut.transform(
        ((scrollOffset - cardStartScroll) / 300.0).clamp(0.0, 1.0),
      );
    } else {
      stackAlpha = 1.0;
    }

    cardStack.opacity = stackAlpha;
    cardStack.position = initialStackPos;

    final cards = cardStack.cards;
    final peelStart = ScrollSequenceConfig.philosophyPeelStart;
    final peelDuration = ScrollSequenceConfig.philosophyPeelDuration;
    final peelDelay = ScrollSequenceConfig.philosophyPeelDelay;

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      final myStart = peelStart + (i * (peelDuration + peelDelay));
      final myEnd = myStart + peelDuration;

      // Default State
      Vector2 liftVector = Vector2.zero();
      double rotation = 0.0;
      double alpha = 0.0;
      double scale = 1.0;

      if (i == 0) {
        if (scrollOffset < ScrollSequenceConfig.dimLayerStart) {
          alpha = 0.0;
        } else if (scrollOffset < ScrollSequenceConfig.philosophyPeelStart) {
          alpha = stackAlpha;
        } else if (scrollOffset < myEnd) {
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          liftVector = GameLayout.philosophyStackLiftVector * curvedT;
          rotation = GameLayout.philStackRotation * curvedT;
          alpha = 1.0 - t;
          scale = 1.0 + ((GameLayout.philStackScaleMax - 1.0) * curvedT);
        } else {
          alpha = 0.0;
          liftVector = GameLayout.philosophyStackLiftVector;
        }
      } else {
        final prevStart = peelStart + ((i - 1) * (peelDuration + peelDelay));
        final prevEnd = prevStart + peelDuration;

        if (scrollOffset < prevStart) {
          alpha = 0.0;
        } else if (scrollOffset < myStart) {
          if (scrollOffset < prevEnd) {
            final revealT = ((scrollOffset - prevStart) / peelDuration).clamp(
              0.0,
              1.0,
            );
            alpha = exponentialEaseOut.transform(revealT);
            final curvedReveal = gentleSpring.transform(revealT);
            scale =
                GameLayout.philStackScaleMin +
                ((1.0 - GameLayout.philStackScaleMin) * curvedReveal);
          } else {
            alpha = 1.0;
            scale = 1.0;
          }
        } else if (scrollOffset < myEnd) {
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          liftVector = GameLayout.philosophyStackLiftVector * curvedT;
          // More dramatic rotation (0.2 → 0.35 for planning.md spec)
          rotation =
              (GameLayout.philStackRotation * 1.75) *
              curvedT *
              (i % 2 == 0 ? 1 : -1);
          alpha = 1.0 - t;
          // More dramatic scale change (planning.md: 1.05+0.15t instead of 1.0+0.1t)
          scale = 1.05 + (0.15 * curvedT);
        } else {
          // Gone
          alpha = 0.0;
          liftVector = GameLayout.philosophyStackLiftVector;
        }
      }

      final center = cardStack.size / 2;
      card.position = center + liftVector;
      card.angle = rotation;
      card.scale = Vector2.all(scale);
      card.opacity = alpha;
    }
  }
}
