import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/widgets/components/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

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
    // Enhanced with Anticipation Curve for Dramatic Entry
    // 1. Fade In Phase (2200 -> 2500) with anticipation (slides in from slightly right)
    // 2. Hold Phase (2500 -> 3800) - Extended for delays
    // 3. Exit Phase (3800 -> 4100) - ElasticEaseOut bounce

    const anticipationCurve = AnticipationCurve(anticipationStrength: 0.12);
    const elasticEaseOut = ElasticEaseOut(amplitude: 0.4, period: 0.3);

    double opacity = 0.0;
    Vector2 pos = initialTextPos.clone();

    if (scrollOffset < 2200) {
      opacity = 0.0;
      pos = initialTextPos + Vector2(60, 0); // Start slightly right for anticipation
    } else if (scrollOffset < 2500) {
      // Fade In with Anticipation
      final t = ((scrollOffset - 2200) / 300).clamp(0.0, 1.0);
      opacity = t;
      // Anticipation curve: pulls slightly more right, then settles left
      final curvedT = anticipationCurve.transform(t);
      pos = initialTextPos + Vector2(60 * (1.0 - curvedT), 0);
    } else if (scrollOffset < 3800) {
      // Hold Visible - STATIC
      opacity = 1.0;
      pos = initialTextPos;
    } else if (scrollOffset < 4100) {
      // Exit to RIGHT with ElasticEaseOut bounce
      opacity = 1.0;

      final t = ((scrollOffset - 3800) / 300).clamp(0.0, 1.0);
      final curve = elasticEaseOut.transform(t);
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
    // Enhanced Card Peel with Dramatic Animation
    // Anticipation curve for card peel, increased rotation, enhanced timing
    const anticipationCurve = AnticipationCurve(anticipationStrength: 0.12);
    const springCurve = SpringCurve(mass: 1.0, stiffness: 180.0, damping: 12.0);

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
    final peelDuration = 200.0; // Reduced from 250 for snappier peel
    final peelDelay = 150.0; // Increased from 100 for better rhythm

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
        // Top Card with Dramatic Peel
        if (scrollOffset < 2200) {
          alpha = 0.0;
        } else if (scrollOffset < 2500) {
          alpha = stackAlpha;
        } else if (scrollOffset < myEnd) {
          // Peeling with AnticipationCurve
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = anticipationCurve.transform(t);
          // Card slightly moves toward user (scale up) before peeling away
          lift = -300.0 * curvedT;
          rotation = 0.35 * curvedT; // Increased from 0.2 for more dramatic tilt
          alpha = 1.0 - t;
          scale = 1.05 + (0.15 * curvedT); // Increased scale emphasis
        } else {
          // Gone
          alpha = 0.0;
          lift = -300.0;
        }
      } else {
        // Cards Below with SpringCurve Bounce
        final prevStart = peelStart + ((i - 1) * (peelDuration + peelDelay));
        final prevEnd = prevStart + peelDuration;

        if (scrollOffset < prevStart) {
          // Hidden
          alpha = 0.0;
        } else if (scrollOffset < myStart) {
          // Reset/Wait/Reveal with Spring Bounce
          if (scrollOffset < prevEnd) {
            // Prev card is peeling, I am revealing with bounce
            final revealT = ((scrollOffset - prevStart) / peelDuration).clamp(
              0.0,
              1.0,
            );
            alpha = revealT;
            // SpringCurve for reveal creates subtle bounce effect
            final curvedReveal = springCurve.transform(revealT);
            scale = 0.95 + (0.05 * curvedReveal);
          } else {
            // Prev card finished peeling. I am waiting for my turn (Delay Gap)
            alpha = 1.0;
            scale = 1.0;
          }
        } else if (scrollOffset < myEnd) {
          // My Turn to Peel with AnticipationCurve
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = anticipationCurve.transform(t);
          lift = -300.0 * curvedT;
          rotation = 0.35 * curvedT * (i % 2 == 0 ? 1 : -1); // Increased rotation
          alpha = 1.0 - t;
          scale = 1.05 + (0.15 * curvedT); // More dramatic scale
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
