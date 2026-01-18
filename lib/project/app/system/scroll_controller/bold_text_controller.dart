import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

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

    // Constants
    const entranceStart = ScrollSequenceConfig.boldTextEntranceStart;
    const entranceDuration = ScrollSequenceConfig.boldTextEntranceDuration;
    final entranceEnd = ScrollSequenceConfig.boldTextEntranceEnd;
    const driftStart = ScrollSequenceConfig.boldTextDriftStart;
    const driftDuration = ScrollSequenceConfig.boldTextDriftDuration;
    final driftEnd = ScrollSequenceConfig.boldTextDriftEnd;
    const scrollEnd = ScrollSequenceConfig.boldTextEnd;

    // Movement Logic
    if (scrollOffset < entranceStart) {
      offsetX = -screenWidth;
    } else if (scrollOffset < entranceEnd) {
      // Entrance
      final t = ((scrollOffset - entranceStart) / entranceDuration).clamp(
        0.0,
        1.0,
      );
      final curvedT = exponentialEaseOut.transform(t);
      offsetX = -screenWidth + (screenWidth * curvedT);
    } else if (scrollOffset < driftEnd) {
      // Drifting
      final t = ((scrollOffset - driftStart) / driftDuration).clamp(0.0, 1.0);
      offsetX = 0.0 + (ScrollSequenceConfig.boldTextDriftOffset * t);
    } else {
      // Exit Phase
      final t = ((scrollOffset - driftEnd) / (scrollEnd - driftEnd)).clamp(
        0.0,
        1.0,
      );
      final curvedT = Curves.easeInCubic.transform(t);
      offsetX =
          ScrollSequenceConfig.boldTextDriftOffset + (screenWidth * curvedT);
    }

    component.position = centerPosition + Vector2(offsetX, offsetY);

    // Opacity Logic
    double opacity = 0.0;
    const fadeInStart = ScrollSequenceConfig.boldTextFadeInStart;
    const fadeInDuration = ScrollSequenceConfig.boldTextFadeInDuration;
    final fadeInEnd = ScrollSequenceConfig.boldTextFadeInEnd;
    const fadeOutRegion = ScrollSequenceConfig.boldTextFadeOutRegion;

    if (scrollOffset < fadeInStart) {
      opacity = 0.0;
    } else if (scrollOffset < fadeInEnd) {
      final t = ((scrollOffset - fadeInStart) / fadeInDuration).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < scrollEnd - fadeOutRegion) {
      opacity = 1.0;
    } else {
      final t = ((scrollOffset - (scrollEnd - fadeOutRegion)) / fadeOutRegion)
          .clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    }
    component.opacity = opacity;

    // Shine Logic
    double shine = 0.0;
    const shineStart = ScrollSequenceConfig.boldTextShineStart;
    const shineDuration = ScrollSequenceConfig.boldTextShineDuration;

    if (scrollOffset >= shineStart && scrollOffset < driftEnd) {
      shine = ((scrollOffset - shineStart) / shineDuration).clamp(0.0, 1.0);
      shine = exponentialEaseOut.transform(shine);
    } else if (scrollOffset >= driftEnd) {
      shine = 1.0;
    }
    component.fillProgress = shine;
  }
}
