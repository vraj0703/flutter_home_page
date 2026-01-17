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
    // Refined for minimal, futuristic feel - smooth glide in/out
    // Overlaps with bold text fade for smooth transition
    // 1. Fade In Phase (1500 -> 1900) - Compressed timing, overlaps with bold text fade
    // 2. Hold Phase (1900 -> 2800) - Compressed but sufficient viewing time
    // 3. Exit Phase (2800 -> 3100) - Smooth fade to experience

    const exponentialEaseOut = ExponentialEaseOut();

    double opacity = 0.0;
    Vector2 pos = initialTextPos.clone();

    if (scrollOffset < 1500) {
      opacity = 0.0;
      pos = initialTextPos;
    } else if (scrollOffset < 1900) {
      // Fade In - Simple, elegant entrance
      final t = ((scrollOffset - 1500) / 400).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
      pos = initialTextPos;
    } else if (scrollOffset < 2800) {
      // Hold Visible - Sufficient breathing room
      opacity = 1.0;
      pos = initialTextPos;
    } else if (scrollOffset < 3100) {
      // Exit - Smooth fade with minimal upward drift
      final t = ((scrollOffset - 2800) / 300).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      opacity = 1.0 - curvedT;
      // Minimal upward float for space theme
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
    // Refined for minimal theme - smooth, elegant card reveals
    // Compressed timing for faster scroll speed
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = SpringCurve(mass: 0.8, stiffness: 140.0, damping: 16.0);

    // Stack Container Master Opacity
    double stackAlpha = 1.0;
    if (scrollOffset < 1500) {
      stackAlpha = 0.0;
    } else if (scrollOffset < 1900) {
      stackAlpha = exponentialEaseOut.transform(((scrollOffset - 1500) / 400).clamp(0.0, 1.0));
    } else {
      stackAlpha = 1.0;
    }

    cardStack.opacity = stackAlpha;
    cardStack.position = initialStackPos;

    final cards = cardStack.cards;
    final peelStart = 1950.0; // Compressed from 2700
    final peelDuration = 250.0; // Compressed from 300
    final peelDelay = 150.0; // Compressed from 200

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
        // Top Card - Smooth, minimal peel
        if (scrollOffset < 1500) {
          alpha = 0.0;
        } else if (scrollOffset < 1950) {
          alpha = stackAlpha;
        } else if (scrollOffset < myEnd) {
          // Peeling with smooth exponential curve
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          // Gentle upward movement
          lift = -350.0 * curvedT;
          rotation = 0.15 * curvedT; // Minimal rotation for clean aesthetic
          alpha = 1.0 - t;
          scale = 1.0 + (0.05 * curvedT); // Subtle scale change
        } else {
          // Gone
          alpha = 0.0;
          lift = -350.0;
        }
      } else {
        // Cards Below - Gentle spring reveal
        final prevStart = peelStart + ((i - 1) * (peelDuration + peelDelay));
        final prevEnd = prevStart + peelDuration;

        if (scrollOffset < prevStart) {
          // Hidden
          alpha = 0.0;
        } else if (scrollOffset < myStart) {
          // Reset/Wait/Reveal with gentle spring
          if (scrollOffset < prevEnd) {
            // Prev card is peeling, I am revealing smoothly
            final revealT = ((scrollOffset - prevStart) / peelDuration).clamp(
              0.0,
              1.0,
            );
            alpha = exponentialEaseOut.transform(revealT);
            // Gentle spring for minimal bounce
            final curvedReveal = gentleSpring.transform(revealT);
            scale = 0.98 + (0.02 * curvedReveal);
          } else {
            // Prev card finished peeling. I am waiting for my turn
            alpha = 1.0;
            scale = 1.0;
          }
        } else if (scrollOffset < myEnd) {
          // My Turn to Peel - smooth and graceful
          final t = ((scrollOffset - myStart) / peelDuration).clamp(0.0, 1.0);
          final curvedT = exponentialEaseOut.transform(t);
          lift = -350.0 * curvedT;
          rotation = 0.15 * curvedT * (i % 2 == 0 ? 1 : -1); // Minimal rotation
          alpha = 1.0 - t;
          scale = 1.0 + (0.05 * curvedT); // Subtle scale
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
