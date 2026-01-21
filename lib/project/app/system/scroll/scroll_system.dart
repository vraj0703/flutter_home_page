import 'dart:ui' show lerpDouble;

import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

/// Manages the global scroll state and notifies observers.
/// Uses a Target/Current model with spring physics for snapping.
class ScrollSystem {
  double _targetScrollOffset = 0.0;
  double _currentScrollOffset = 0.0;
  double _springVelocity = 0.0; // For spring simulation
  final List<ScrollObserver> _observers = [];
  double _scrollVelocity = 0.0;
  double _lastScrollOffset = 0.0;
  double _lastUpdateTime = 0.0;
  bool _isSnapping = false;
  double _snapTarget = 0.0;

  static const List<double> snapPoints = [
    ScrollSequenceConfig.boldTextStart,
    ScrollSequenceConfig.boldTextFocus,
    ScrollSequenceConfig.boldTextEnd,
    ScrollSequenceConfig.philosophyEnd,
    ScrollSequenceConfig.workExpTitleHoldStart,
    ScrollSequenceConfig.experienceInteractionStart,
    ScrollSequenceConfig.testimonialInteractionStart,
  ];
  static const double snapZoneRadius = GamePhysics.snapZoneRadius;
  static const double snapVelocityThreshold = GamePhysics.snapVelocityThreshold;

  double get scrollOffset => _currentScrollOffset;

  double get targetScrollOffset => _targetScrollOffset;

  void register(ScrollObserver observer) {
    _observers.add(observer);
  }

  void unregister(ScrollObserver observer) {
    _observers.remove(observer);
  }

  void setScrollOffset(double offset) {
    _targetScrollOffset = offset;
    _checkSnapPoints();
  }

  void onScroll(double delta) {
    if (_isSnapping && delta.abs() > 5.0) {
      _isSnapping = false;
      _springVelocity = 0.0; // Reset spring velocity on user interrupt
    }

    _targetScrollOffset += delta;
    if (_targetScrollOffset < 0) _targetScrollOffset = 0;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (_lastUpdateTime > 0) {
      final deltaTime = currentTime - _lastUpdateTime;
      if (deltaTime > 0) {
        final deltaOffset = _targetScrollOffset - _lastScrollOffset;
        _scrollVelocity = deltaOffset / deltaTime;
      }
    }
    _lastScrollOffset = _targetScrollOffset;
    _lastUpdateTime = currentTime;

    _checkSnapPoints();
  }

  void _checkSnapPoints() {
    if (_isSnapping) return;
    if (_scrollVelocity.abs() > snapVelocityThreshold) return;

    for (final snapPoint in snapPoints) {
      final distance = (_targetScrollOffset - snapPoint).abs();
      if (distance <= snapZoneRadius) {
        _isSnapping = true;
        _snapTarget = snapPoint;
        _springVelocity = 0.0; // Start fresh spring
        break;
      }
    }
  }

  /// Main update loop with spring physics.
  void update(double dt) {
    // 1. Handle snapping with SPRING physics
    if (_isSnapping) {
      // Spring simulation: F = -kx - cv
      // x = displacement from target
      // v = velocity
      // k = stiffness, c = damping
      final stiffness = GamePhysics.snapSpringStiffness;
      final damping = GamePhysics.snapSpringDamping;

      final displacement = _targetScrollOffset - _snapTarget;
      final springForce = -stiffness * displacement;
      final dampingForce = -damping * _springVelocity;
      final acceleration = springForce + dampingForce;

      _springVelocity += acceleration * dt;
      _targetScrollOffset += _springVelocity * dt;

      // Check if spring has settled
      if (displacement.abs() < 1.0 && _springVelocity.abs() < 5.0) {
        _targetScrollOffset = _snapTarget;
        _springVelocity = 0.0;
        _isSnapping = false;
      }
    }

    // 2. Inertia: Lerp current towards target
    final inertia = GamePhysics.scrollInertia;
    _currentScrollOffset =
        lerpDouble(_currentScrollOffset, _targetScrollOffset, dt * inertia) ??
        _currentScrollOffset;

    // 3. Notify observers
    _notifyObservers();
  }

  void _notifyObservers() {
    for (final observer in _observers) {
      observer.onScroll(_currentScrollOffset);
    }
  }
}
