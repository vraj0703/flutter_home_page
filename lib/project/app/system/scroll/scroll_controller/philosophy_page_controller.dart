import 'dart:math';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flame/components.dart';

/// Controller for Philosophy section with floating balloon title animation
class PhilosophyPageController implements ScrollObserver {
  final PhilosophyTextComponent titleComponent;
  final Vector2 screenSize;
  final void Function()? onComplete;

  bool _hasPlayedSound = false;

  PhilosophyPageController({
    required this.titleComponent,
    required this.screenSize,
    this.onComplete,
  });

  @override
  void onScroll(double scrollOffset) {
    _updateFloatingTitleAnimation(scrollOffset);
  }

  void _updateFloatingTitleAnimation(double scrollOffset) {
    // Floating balloon animation over 500px
    const animationDuration = 500.0;

    final progress = (scrollOffset / animationDuration).clamp(0.0, 1.0);

    if (progress == 0.0) {
      // Hidden at start
      titleComponent.opacity = 0.0;
      titleComponent.scale = Vector2.all(0.1);
      titleComponent.position = Vector2(screenSize.x / 2, screenSize.y * 0.7);
      titleComponent.showReflection = false;
      _hasPlayedSound = false;
      return;
    }

    // Enable reflection
    titleComponent.showReflection = true;
    titleComponent.waterLineY = screenSize.y * 0.55;

    // Gentle ease-out for balloon float
    final eased = _easeOutQuad(progress);

    // Fade in gently
    titleComponent.opacity = (progress * 1.5).clamp(0.0, 1.0);

    // Gentle scale growth (like balloon inflating)
    final scale = 0.1 + (eased * 0.9); // 0.1 -> 1.0
    titleComponent.scale = Vector2.all(scale);

    // Float up from below screen to top
    final startY = screenSize.y * 0.7; // Start below center
    final endY = screenSize.y * 0.15; // Float to top
    final currentY = startY + (endY - startY) * eased;

    // Add gentle horizontal sway (like balloon drifting)
    final swayAmount = 20.0;
    final sway = sin(progress * pi * 2) * swayAmount * (1 - eased);

    titleComponent.position = Vector2(screenSize.x / 2 + sway, currentY);

    // Play sound when animation completes
    if (progress >= 1.0 && !_hasPlayedSound && onComplete != null) {
      onComplete!();
      _hasPlayedSound = true;
    }
  }

  /// Gentle ease-out quad for smooth balloon motion
  double _easeOutQuad(double t) {
    return 1 - (1 - t) * (1 - t);
  }
}
