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

  // Local Constants
  static const double fadeInEnd = 400.0;
  static const double exitStart = 1300.0;
  static const double end = 1600.0;
  static const double peelStart = 450.0;

  PhilosophyPageController({
    required this.component,
    required this.cardStack,
    required this.initialTextPos,
    required this.initialStackPos,
  });

  @override
  void onScroll(double localOffset) {
    _handleText(localOffset);
    _handleStack(localOffset);
  }

  void _handleText(double offset) {
    const exponentialEaseOut = ExponentialEaseOut();

    double opacity = 0.0;
    double scale = 0.0;
    Vector2 pos = initialTextPos.clone();

    if (offset < 0) {
      opacity = 0.0;
      scale = 0.0;
      pos = initialTextPos;
    } else if (offset < fadeInEnd) {
      final t = (offset / fadeInEnd).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
      // Zoom in from 0.5 to 1.0
      scale = 0.5 + (0.5 * exponentialEaseOut.transform(t));
      pos = initialTextPos;
    } else if (offset < exitStart) {
      opacity = 1.0;
      scale = 1.0;
      pos = initialTextPos;
    } else if (offset < end) {
      final t = ((offset - exitStart) / (end - exitStart)).clamp(0.0, 1.0);
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

  void _handleStack(double offset) {
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = GameCurves.philosophySpring;

    // Start card after text is fully visible (fadeInEnd)
    double stackAlpha = 0.0;
    const cardDelayAfterText = 200.0;
    const cardStartScroll = fadeInEnd + cardDelayAfterText; // 600

    if (offset < cardStartScroll) {
      stackAlpha = 0.0;
    } else if (offset < cardStartScroll + 300.0) {
      stackAlpha = exponentialEaseOut.transform(
        ((offset - cardStartScroll) / 300.0).clamp(0.0, 1.0),
      );
    } else {
      stackAlpha = 1.0;
    }

    cardStack.opacity = stackAlpha;
    cardStack.position = initialStackPos;

    final cards = cardStack.cards;
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
        if (offset < peelStart) {
          alpha = stackAlpha;
        } else if (offset < myEnd) {
          final t = ((offset - myStart) / peelDuration).clamp(0.0, 1.0);
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

        if (offset < prevStart) {
          alpha = 0.0;
        } else if (offset < myStart) {
          if (offset < prevEnd) {
            final revealT = ((offset - prevStart) / peelDuration).clamp(
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
        } else if (offset < myEnd) {
          final t = ((offset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          liftVector = GameLayout.philosophyStackLiftVector * curvedT;
          rotation =
              (GameLayout.philStackRotation * 1.75) *
              curvedT *
              (i % 2 == 0 ? 1 : -1);
          alpha = 1.0 - t;
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
