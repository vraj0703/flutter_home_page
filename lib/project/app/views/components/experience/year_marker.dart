import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class YearMarker extends TextComponent with HasGameReference, HasPaint {
  YearMarker({super.position}) : super(anchor: Anchor.centerLeft);

  @override
  Future<void> onLoad() async {
    textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: 100.0,
        fontWeight: FontWeight.w100,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = GameStyles.white70
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0),
      ),
    );
  }

  void animateReveal(double progress) {
    // Aggressive Fade:
    // progress 0.0 -> Opacity 1.0 (Visible)
    // progress 0.3 -> Opacity 0.0 (Invisible)
    // This makes the text dissolve quickly into the light bloom.

    final p = progress.clamp(0.0, 1.0);

    // Scale up from 1.0 to 1.15
    scale = Vector2.all(1.0 + (0.15 * p));

    // Opacity: Map 0.0-0.4 to 1.0-0.0
    final fadeC = (1.0 - (p * 2.5)).clamp(0.0, 1.0);
    opacity = fadeC;
  }
}
