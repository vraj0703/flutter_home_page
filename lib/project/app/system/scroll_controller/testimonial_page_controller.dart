import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';

class TestimonialPageController implements ScrollObserver {
  final TestimonialPageComponent component;
  final double entranceStart;
  final double exitStart;
  final double exitEnd;

  static const double initEntranceStart =
      ScrollSequenceConfig.testimonialEntranceStart;
  static const double initInteractionStart =
      ScrollSequenceConfig.testimonialInteractionStart;
  static const double visibleDuration =
      ScrollSequenceConfig.testimonialVisibleDuration;
  static const double exitDuration =
      ScrollSequenceConfig.testimonialExitDuration;

  final double interactionStart;
  final double interactionEnd;

  TestimonialPageController({
    required this.component,
    this.entranceStart = initEntranceStart,
  }) : interactionStart = initInteractionStart,
       interactionEnd = ScrollSequenceConfig.testimonialInteractionEnd,
       exitStart = ScrollSequenceConfig.testimonialExitStart,
       exitEnd = ScrollSequenceConfig.testimonialExitEnd;

  @override
  void onScroll(double scrollOffset) {
    _handleVisibility(scrollOffset);
    _handleInteraction(scrollOffset);
    _handleExit(scrollOffset);
  }

  void _handleInteraction(double scrollOffset) {
    double scrollDelta = 0.0;

    if (scrollOffset < interactionStart) {
      scrollDelta = 0.0;
    } else if (scrollOffset > interactionEnd) {
      scrollDelta = interactionEnd - interactionStart;
    } else {
      scrollDelta = scrollOffset - interactionStart;
    }

    component.updateScroll(scrollDelta);
  }

  void _handleVisibility(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    double opacity = 0.0;

    if (scrollOffset < entranceStart) {
      opacity = 0.0;
    } else if (scrollOffset <
        entranceStart + ScrollSequenceConfig.testimonialFadeOffset) {
      final t =
          ((scrollOffset - entranceStart) /
                  ScrollSequenceConfig.testimonialFadeOffset)
              .clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < exitStart) {
      opacity = 1.0;
    } else if (scrollOffset < exitEnd) {
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleExit(double scrollOffset) {
    if (!component.isLoaded) return;

    const springCurve = GameCurves.testimonialExitSpring;

    // Only allow exit if all testimonials have been focused
    if (scrollOffset < exitStart) {
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      // Check if all testimonials have been focused before allowing exit
      if (!component.allTestimonialsFocused) {
        // Hold at center until all are focused
        component.position = Vector2.zero();
        return;
      }

      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);
      component.position = GameLayout.testiExitVector * curvedT;
    } else {
      component.position = GameLayout.testiExitVector;
    }
  }
}
