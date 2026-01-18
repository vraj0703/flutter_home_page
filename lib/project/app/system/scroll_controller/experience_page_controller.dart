import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import '../../interfaces/scroll_observer.dart';

class ExperiencePageController implements ScrollObserver {
  final ExperiencePageComponent component;
  final double entranceStart;
  final double interactionStart;
  final double interactionEnd;
  final double exitStart;
  final double exitEnd;
  static const double initEntranceStart =
      ScrollSequenceConfig.experienceEntranceStart;
  static const double initInteractionStart =
      ScrollSequenceConfig.experienceInteractionStart;
  static const double itemScrollHeight = 350.0;
  static const int itemCount = 5;

  ExperiencePageController({
    required this.component,
    this.entranceStart = initEntranceStart,
    this.interactionStart = initInteractionStart,
  }) : interactionEnd = ScrollSequenceConfig.experienceInteractionEnd,
       exitStart = ScrollSequenceConfig.experienceExitStart,
       exitEnd = ScrollSequenceConfig.experienceExitEnd;

  @override
  void onScroll(double scrollOffset) {
    _handleVisibility(scrollOffset);
    _handleInteraction(scrollOffset);
    _handleExit(scrollOffset);
  }

  void _handleVisibility(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    double opacity = 0.0;
    if (scrollOffset < entranceStart) {
      opacity = 0.0;
    } else if (scrollOffset <
        entranceStart + ScrollSequenceConfig.experienceFadeOffset) {
      final t =
          ((scrollOffset - entranceStart) /
                  ScrollSequenceConfig.experienceFadeOffset)
              .clamp(0.0, 1.0);
      opacity = exponentialEaseOut.transform(t);
    } else if (scrollOffset < exitStart) {
      opacity = 1.0;
    } else if (scrollOffset <
        exitStart + ScrollSequenceConfig.experienceExitFadeOffset) {
      final t =
          ((scrollOffset - exitStart) /
                  ScrollSequenceConfig.experienceExitFadeOffset)
              .clamp(0.0, 1.0);
      opacity = 1.0 - exponentialEaseOut.transform(t);
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleInteraction(double scrollOffset) {
    if (scrollOffset < interactionStart) {
      component.updateInteraction(0.0);
      return;
    }

    if (scrollOffset > interactionEnd) {
      component.updateInteraction(interactionEnd - interactionStart);
      return;
    }

    final localScroll = scrollOffset - interactionStart;
    component.updateInteraction(localScroll);
  }

  void _handleExit(double scrollOffset) {
    if (!component.isLoaded) return;

    const springCurve = GameCurves.expExitSpring;
    if (scrollOffset < exitStart) {
      component.position = component.initialPosition;
      component.setWarp(0.0);
      if (component.scale != Vector2.all(1.0)) {
        component.scale = Vector2.all(1.0);
      }
    } else if (scrollOffset < exitEnd) {
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      final curvedT = springCurve.transform(t);

      component.position =
          component.initialPosition + Vector2(0, GameLayout.expExitY * curvedT);

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
      component.position =
          component.initialPosition + Vector2(0, GameLayout.expExitY);
      component.setWarp(1.0);
      component.scale = Vector2.all(GameLayout.expInitialScale);
    }
  }
}
