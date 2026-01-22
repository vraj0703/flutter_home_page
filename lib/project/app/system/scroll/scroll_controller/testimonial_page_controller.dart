import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';

class TestimonialPageController implements ScrollObserver {
  final TestimonialPageComponent component;

  // Local Constants
  // interactionStart was 9050 - 8750 = 300
  static const double interactionStart = 300.0;
  // exitStart was 12250 - 8750 = 3500
  static const double exitStart = 3500.0;
  // exitEnd was 12650 - 8750 = 3900
  static const double exitEnd = 3900.0;
  // interactionEnd was 12250 = 3500
  static const double interactionEnd = 3500.0;
  static const double fadeOffset = ScrollSequenceConfig.testimonialFadeOffset;

  TestimonialPageController({required this.component});

  @override
  void onScroll(double offset) {
    _handleVisibility(offset);
    _handleInteraction(offset);
    _handleExit(offset);
  }

  void _handleInteraction(double offset) {
    double scrollDelta = 0.0;

    if (offset < interactionStart) {
      scrollDelta = 0.0;
    } else if (offset > interactionEnd) {
      scrollDelta = interactionEnd - interactionStart;
    } else {
      scrollDelta = offset - interactionStart;
    }

    component.updateScroll(scrollDelta);
  }

  void _handleVisibility(double offset) {
    const exponentialEaseOut = ExponentialEaseOut();
    double opacity = 0.0;

    if (offset < 0) {
      opacity = 0.0;
    } else if (offset < fadeOffset) {
      final t = (offset / fadeOffset).clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (offset < exitStart) {
      opacity = 1.0;
    } else if (offset < exitEnd) {
      final t = ((offset - exitStart) / (exitEnd - exitStart)).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleExit(double offset) {
    if (!component.isLoaded) return;

    const springCurve = GameCurves.testimonialExitSpring;

    if (offset < exitStart) {
      component.position = Vector2.zero();
    } else if (offset < exitEnd) {
      if (!component.allTestimonialsFocused) {
        component.position = Vector2.zero();
        return;
      }

      final t = ((offset - exitStart) / (exitEnd - exitStart)).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);
      component.position = GameLayout.testiExitVector * curvedT;
    } else {
      component.position = GameLayout.testiExitVector;
    }
  }
}
