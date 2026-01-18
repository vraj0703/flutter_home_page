import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import '../interfaces/scroll_observer.dart';

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
    Vector2 pos = initialTextPos.clone();

    if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      opacity = 0.0;
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyFadeInEnd) {
      final t =
          ((scrollOffset - ScrollSequenceConfig.philosophyStart) /
                  (ScrollSequenceConfig.philosophyFadeInEnd -
                      ScrollSequenceConfig.philosophyStart))
              .clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyExitStart) {
      opacity = 1.0;
      pos = initialTextPos;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyEnd) {
      final t =
          ((scrollOffset - ScrollSequenceConfig.philosophyExitStart) /
                  (ScrollSequenceConfig.philosophyEnd -
                      ScrollSequenceConfig.philosophyExitStart))
              .clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      opacity = 1.0 - curvedT;
      pos = initialTextPos + Vector2(0, -40 * curvedT);
    } else {
      // Gone
      opacity = 0.0;
      pos = initialTextPos + Vector2(0, -40);
    }

    component.opacity = opacity;
    component.position = pos;
  }

  void _handleStack(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = SpringCurve(
      mass: 0.8,
      stiffness: 140.0,
      damping: 16.0,
    );

    double stackAlpha = 1.0;
    if (scrollOffset < 1500) {
      stackAlpha = 0.0;
    } else if (scrollOffset < 1900) {
      stackAlpha = exponentialEaseOut.transform(
        ((scrollOffset - 1500) / 400).clamp(0.0, 1.0),
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
      double lift = 0.0;
      double rotation = 0.0;
      double alpha = 0.0;
      double scale = 1.0;

      if (i == 0) {
        if (scrollOffset < 1500) {
          alpha = 0.0;
        } else if (scrollOffset < 1950) {
          alpha = stackAlpha;
        } else if (scrollOffset < myEnd) {
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          lift = -350.0 * curvedT;
          rotation = 0.15 * curvedT;
          alpha = 1.0 - t;
          scale = 1.0 + (0.05 * curvedT);
        } else {
          alpha = 0.0;
          lift = -350.0;
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
            scale = 0.98 + (0.02 * curvedReveal);
          } else {
            alpha = 1.0;
            scale = 1.0;
          }
        } else if (scrollOffset < myEnd) {
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          lift = -350.0 * curvedT;
          rotation = 0.15 * curvedT * (i % 2 == 0 ? 1 : -1);
          alpha = 1.0 - t;
          scale = 1.0 + (0.05 * curvedT);
        } else {
          // Gone
          alpha = 0.0;
          lift = -350.0;
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
