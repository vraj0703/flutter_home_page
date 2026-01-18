import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

class BoldTextController implements ScrollObserver {
  final BoldTextRevealComponent component;
  final double screenWidth;
  final Vector2 centerPosition;

  BoldTextController({
    required this.component,
    required this.screenWidth,
    required this.centerPosition,
  });

  @override
  void onScroll(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    double offsetX = -screenWidth;
    double offsetY = 0;

    if (scrollOffset < 400) {
      offsetX = -screenWidth;
    } else if (scrollOffset < 900) {
      final t = ((scrollOffset - 400) / 500).clamp(0.0, 1.0);
      final curvedT = exponentialEaseOut.transform(t);
      offsetX = -screenWidth + (screenWidth * curvedT);
      offsetY = 0;
    } else if (scrollOffset < 1400) {
      final t = ((scrollOffset - 900) / 500).clamp(0.0, 1.0);
      offsetX = 0.0 + (50 * t);
      offsetY = 0;
    } else {
      // Exit Phase
      final t =
          ((scrollOffset - 1400) / (ScrollSequenceConfig.boldTextEnd - 1400))
              .clamp(0.0, 1.0);
      final curvedT = Curves.easeInCubic.transform(t);
      offsetX = 50 + (screenWidth * curvedT);
      offsetY = 0;
    }
    component.position = centerPosition + Vector2(offsetX, offsetY);
    double opacity = 0.0;

    if (scrollOffset < 500) {
      opacity = 0.0;
    } else if (scrollOffset < 750) {
      final t = ((scrollOffset - 500) / 250).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < ScrollSequenceConfig.boldTextEnd - 200) {
      opacity = 1.0;
    } else {
      final t =
          ((scrollOffset - (ScrollSequenceConfig.boldTextEnd - 200)) / 200)
              .clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    }
    component.opacity = opacity;

    double shine = 0.0;
    if (scrollOffset >= 1050 && scrollOffset < 1400) {
      shine = ((scrollOffset - 1050) / 350).clamp(0.0, 1.0);
      shine = exponentialEaseOut.transform(shine);
    } else if (scrollOffset >= 1400) {
      shine = 1.0;
    }
    component.fillProgress = shine;
  }
}
