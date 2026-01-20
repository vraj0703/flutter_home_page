import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class BoldTextController implements ScrollObserver {
  final BoldTextRevealComponent component;
  final double screenWidth;
  final Vector2 centerPosition;

  bool _hasPlayedEntrySound = false;
  bool _hasPlayedExitSound = false;

  BoldTextController({
    required this.component,
    required this.screenWidth,
    required this.centerPosition,
  });

  @override
  void onScroll(double scrollOffset) {
    // 3-Pass Animation Logic
    // Total Range: 0 to 3000 (ScrollSequenceConfig.boldTextEnd)

    // Normalize progress p (0.0 to 1.0)
    final p = (scrollOffset / ScrollSequenceConfig.boldTextEnd).clamp(0.0, 1.0);

    double offsetX = -screenWidth;
    double opacity = 0.0;
    double shine = 0.0;

    // Reset flags if scrolled back up significantly
    if (p < 0.05) _hasPlayedEntrySound = false;
    if (p < 0.5) _hasPlayedExitSound = false;

    if (p < 0.4) {
      // --- Pass 1: The Entrance (0.0 - 0.4) ---
      // Motion: -100vw -> 0 (Center)
      // Damping: Use a gentle easeOut
      final activeP = (p / 0.4).clamp(0.0, 1.0);

      // Sound Trigger: On Start
      if (activeP > 0.01 && !_hasPlayedEntrySound) {
        _hasPlayedEntrySound = true;
        (component.game as MyGame).playBoldText();
      }

      // Easing
      const ease = ExponentialEaseOut();
      final t = ease.transform(activeP);

      offsetX = -screenWidth * (1.0 - t); // -100vw to 0

      // Opacity: 0->1 in first 15% (0.0 to 0.15 relative to total, so 0.0 to 0.375 activeP)
      final opacityP = (activeP / 0.375).clamp(0.0, 1.0);
      opacity = opacityP;
    } else if (p < 0.6) {
      // --- Pass 2: The Shine (0.4 - 0.6) ---
      // Motion: Stationary (Center)
      offsetX = 0;
      opacity = 1.0;

      // Shine: 0 -> 1 linear
      // Relative progress within 0.4-0.6
      shine = ((p - 0.4) / 0.2).clamp(0.0, 1.0);
    } else {
      // --- Pass 3: The Exit (0.6 - 1.0) ---
      // Motion: 0 -> 100vw
      // Easing: Accelerate slightly (EaseIn)
      final activeP = ((p - 0.6) / 0.4).clamp(0.0, 1.0);

      // Sound Trigger: On Exit Start
      if (activeP > 0.01 && !_hasPlayedExitSound) {
        _hasPlayedExitSound = true;
        (component.game as MyGame).playBoldText();
      }

      // Simple acceleration
      final t = activeP * activeP;
      offsetX = screenWidth * t;

      // Opacity: 1->0 in last 15% (0.85-1.0 total => last 0.15 => relative to 0.4 segment = 0.375)
      // Wait, user said p=0.85 to 1.0.
      // 0.85 is (0.85 - 0.6) / 0.4 = 0.625 activeP.
      if (activeP > 0.625) {
        final fadeP = ((activeP - 0.625) / (1.0 - 0.625)).clamp(0.0, 1.0);
        opacity = 1.0 - fadeP;
      } else {
        opacity = 1.0;
      }
    }

    component.position = centerPosition + Vector2(offsetX, 0);
    component.opacity = opacity;
    component.fillProgress = shine;
  }
}
