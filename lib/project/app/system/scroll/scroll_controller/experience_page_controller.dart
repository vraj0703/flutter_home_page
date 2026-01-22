import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

class ExperiencePageController implements ScrollObserver {
  final ExperiencePageComponent component;

  // Local Constants
  // interactionStart was 6700 - 6400 = 300
  static const double interactionStart = 300.0;
  // exitStart was 8450 - 6400 = 2050
  static const double exitStart = 2050.0;
  // exitEnd was 8750 - 6400 = 2350
  static const double exitEnd = 2350.0;
  // interactionEnd was exitEnd (or close to it) in old config?
  // Old config: interactionEnd = 8750 (same as exitEnd)
  static const double interactionEnd = 2350.0;

  static const double fadeOffset =
      ScrollSequenceConfig.experienceFadeOffset; // 400?

  ExperiencePageController({required this.component});

  @override
  void onScroll(double offset) {
    _handleVisibility(offset);
    _handleInteraction(offset);
    _handleExit(offset);
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
      // fade out during exit
      final t = ((offset - exitStart) / (exitEnd - exitStart)).clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleInteraction(double offset) {
    if (offset < interactionStart) {
      component.updateInteraction(0.0);
      return;
    }

    if (offset > interactionEnd) {
      component.updateInteraction(interactionEnd - interactionStart);
      return;
    }

    final localScroll = offset - interactionStart;
    component.updateInteraction(localScroll);
  }

  void _handleExit(double offset) {
    if (!component.isLoaded) return;

    const springCurve = GameCurves.expExitSpring;
    if (offset < exitStart) {
      component.position = component.initialPosition;
      component.setWarp(0.0);
      if (component.scale != Vector2.all(1.0)) {
        component.scale = Vector2.all(1.0);
      }
    } else if (offset < exitEnd) {
      final t = ((offset - exitStart) / (exitEnd - exitStart)).clamp(0.0, 1.0);
      final curvedT = springCurve.transform(t);

      component.position =
          component.initialPosition + (GameLayout.expExitVector * curvedT);

      component.setWarp(t);
      double scale = 1.0;
      if (t < 0.5) {
        scale = 1.0 - ((1.0 - GameLayout.expExitScale) * (t / 0.5));
      } else {
        scale =
            GameLayout.expExitScale -
            ((GameLayout.expExitScale - GameLayout.expInitialScale) *
                ((t - 0.5) / 0.5));
      }
      component.scale = Vector2.all(scale);
    } else {
      // Fully exited
      component.position = component.initialPosition + GameLayout.expExitVector;
      component.setWarp(1.0);
      component.scale = Vector2.all(GameLayout.expInitialScale);
    }
  }
}
