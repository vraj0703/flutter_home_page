import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';

class GodRayController implements ScrollObserver {
  final GodRayComponent component;
  final Vector2 screenSize;

  // Pulse animation state for Work Experience section
  double _pulseTime = 0.0;
  static const double _pulseCycleTime = 2.0; // 2 second cycle

  // Section color definitions
  static const Color _heroInner = Color(0xAAFFE082); // Default gold
  static const Color _heroOuter = Color(0xAAE68A4D);

  static const Color _philosophyInner = Color(0xAAE8A0D9); // Purple tint
  static const Color _philosophyOuter = Color(0xAAC76BB8);

  static const Color _workExpInner = Color(0xAAA0C8E8); // Blue tint
  static const Color _workExpOuter = Color(0xAA6BA8C7);

  static const Color _contactInner = Color(0xAAFFE082); // Pure gold
  static const Color _contactOuter = Color(0xAAFFD700);

  GodRayController({
    required this.component,
    required this.screenSize,
  });

  void updatePulse(double dt, double currentScroll) {
    if (currentScroll >= ScrollSequenceConfig.workExpTitleEntranceStart &&
        currentScroll <= ScrollSequenceConfig.experienceExitEnd) {
      _pulseTime += dt;
      if (_pulseTime >= _pulseCycleTime) {
        _pulseTime -= _pulseCycleTime;
      }

      final pulseProgress = _pulseTime / _pulseCycleTime;
      final pulseFactor = 1.0 + (0.15 * math.sin(pulseProgress * 2 * math.pi));
      component.sizeMultiplier = pulseFactor;
    }
  }

  @override
  void onScroll(double scrollOffset) {
    // Determine section and set colors accordingly
    if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      // Hero section - default gold
      component.currentInnerColor = _heroInner;
      component.currentOuterColor = _heroOuter;
      component.sizeMultiplier = 1.0;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyEnd) {
      // Philosophy section - purple tint
      component.currentInnerColor = _philosophyInner;
      component.currentOuterColor = _philosophyOuter;
      component.sizeMultiplier = 1.0;
    } else if (scrollOffset < ScrollSequenceConfig.experienceExitEnd) {
      // Work Experience + Experience section - blue tint with pulse
      component.currentInnerColor = _workExpInner;
      component.currentOuterColor = _workExpOuter;
      // Size multiplier updated by updatePulse()
    } else if (scrollOffset < ScrollSequenceConfig.contactEntranceStart) {
      // Between sections - fade to gold
      component.currentInnerColor = _heroInner;
      component.currentOuterColor = _heroOuter;
      component.sizeMultiplier = 1.0;
    } else {
      // Contact section (final section) - celebration bloom
      final t = (scrollOffset - ScrollSequenceConfig.contactEntranceStart) /
          ScrollSequenceConfig.contactEntranceDuration;

      if (t < 1.0) {
        // Growing bloom during entrance
        component.sizeMultiplier = 1.0 + (0.5 * t); // 1.0 -> 1.5
      } else {
        // Hold at enlarged size during contact section
        component.sizeMultiplier = 1.5;
      }

      component.currentInnerColor = _contactInner;
      component.currentOuterColor = _contactOuter;
    }
  }
}
