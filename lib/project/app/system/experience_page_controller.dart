import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/components/experience_page_component.dart';

class ExperiencePageController implements ScrollObserver {
  final ExperiencePageComponent component;
  final double entranceStart;
  final double interactionStart;
  final double interactionEnd;
  final double exitStart;
  final double exitEnd;

  ExperiencePageController({
    required this.component,
    this.entranceStart = 4200,
    this.interactionStart = 4600,
  }) : // 5 items * 1000px = 5000px interaction
       interactionEnd = interactionStart + (5 * 1000),
       exitStart = interactionStart + (5 * 1000),
       exitEnd = interactionStart + (5 * 1000) + 1000;

  @override
  void onScroll(double scrollOffset) {
    _handleVisibility(scrollOffset);
    _handleInteraction(scrollOffset);
    _handleExit(scrollOffset);
  }

  void _handleVisibility(double scrollOffset) {
    double opacity = 0.0;

    // 1. Entrance (Fade In)
    if (scrollOffset < entranceStart) {
      opacity = 0.0;
    } else if (scrollOffset < entranceStart + 400) {
      opacity = ((scrollOffset - entranceStart) / 400).clamp(0.0, 1.0);
    } else if (scrollOffset < exitStart) {
      opacity = 1.0;
    } else if (scrollOffset < exitStart + 500) {
      // Exit Fade Out
      final t = ((scrollOffset - exitStart) / 500).clamp(0.0, 1.0);
      opacity = 1.0 - t;
    } else {
      opacity = 0.0;
    }

    component.opacity = opacity;
  }

  void _handleInteraction(double scrollOffset) {
    if (scrollOffset < interactionStart) {
      // Reset to initial state
      component.updateInteraction(0.0);
      return;
    }

    if (scrollOffset > interactionEnd) {
      // Lock to final state
      component.updateInteraction(interactionEnd - interactionStart);
      return;
    }

    final localScroll = scrollOffset - interactionStart;
    component.updateInteraction(localScroll);
  }

  void _handleExit(double scrollOffset) {
    if (!component.isLoaded) return;

    // Parallax Slide Up + Warp
    if (scrollOffset < exitStart) {
      component.position = component.initialPosition;
      component.setWarp(0.0);
    } else if (scrollOffset < exitEnd) {
      // 0.0 to 1.0 progress
      final t = ((scrollOffset - exitStart) / (exitEnd - exitStart)).clamp(
        0.0,
        1.0,
      );
      // Move up by 1000px
      component.position = component.initialPosition + Vector2(0, -1000 * t);
      // Trigger Warp
      component.setWarp(t);
    } else {
      // Final state
      component.position = component.initialPosition + Vector2(0, -1000);
      component.setWarp(1.0);
    }
  }
}
