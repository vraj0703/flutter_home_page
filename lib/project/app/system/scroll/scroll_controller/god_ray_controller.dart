import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
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

  GodRayController({required this.component, required this.screenSize});

  void updatePulse(double dt, double currentScroll) {
    _pulseTime += dt;
    if (_pulseTime >= _pulseCycleTime) {
      _pulseTime -= _pulseCycleTime;
    }

    final pulseProgress = _pulseTime / _pulseCycleTime;
    final pulseFactor = 1.0 + (0.15 * math.sin(pulseProgress * 2 * math.pi));
    component.sizeMultiplier = pulseFactor;
  }

  @override
  void onScroll(double scrollOffset) {
    // Determine section and set colors accordingly
    component.currentInnerColor = _heroInner;
    component.currentOuterColor = _heroOuter;
    component.sizeMultiplier = 1.0;
  }
}
