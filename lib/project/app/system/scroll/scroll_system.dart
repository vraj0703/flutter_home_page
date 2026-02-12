import 'dart:ui' show lerpDouble;

import 'package:flame/components.dart';

import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';
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
  List<Vector2> _snapRegions = [];
  bool _isSnapping = false;
  double _snapTarget = 0.0;

  double? _minScroll;
  double? _maxScroll;

  static const double snapVelocityThreshold = GamePhysics.snapVelocityThreshold;

  double get scrollOffset => _currentScrollOffset;

  double get targetScrollOffset => _targetScrollOffset;

  void setSnapRegions(List<Vector2> regions) {
    _snapRegions = regions;
  }

  void setBounds(double? min, double? max) {
    _minScroll = min;
    _maxScroll = max;
    LoggerUtil.log('ScrollSystem', 'setBounds($min, $max)');

    // Clamp current target immediately if out of bounds
    if (_minScroll != null && _maxScroll != null) {
      _targetScrollOffset = _targetScrollOffset.clamp(_minScroll!, _maxScroll!);
    }
  }

  void register(ScrollObserver observer) {
    _observers.add(observer);
  }

  void unregister(ScrollObserver observer) {
    _observers.remove(observer);
  }

  void clearObservers() {
    _observers.clear();
  }

  void setScrollOffset(double offset) {
    _targetScrollOffset = offset;
    _checkSnapPoints();
  }

  void resetScroll(double offset) {
    _targetScrollOffset = offset;
    _currentScrollOffset = offset;
    _lastScrollOffset = offset;
    _springVelocity = 0.0;
    _scrollVelocity = 0.0;
    _isSnapping = false;
  }

  void onScroll(double delta) {
    if (_isSnapping && delta.abs() > 5.0) {
      _isSnapping = false;
      _springVelocity = 0.0; // Reset spring velocity on user interrupt
    }

    _targetScrollOffset += delta;
    if (_minScroll != null && _maxScroll != null) {
      _targetScrollOffset = _targetScrollOffset.clamp(_minScroll!, _maxScroll!);
    }

    // Log if scroll system is running away (e.g. > 4000)
    if (_targetScrollOffset.abs() > 4000 &&
        _targetScrollOffset.abs() % 1000 < 50) {
      LoggerUtil.log(
        'ScrollSystem',
        'High Scroll Value Warning: ${_targetScrollOffset.toStringAsFixed(1)}',
      );
    }

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

    for (final region in _snapRegions) {
      // region.x = start of snap zone reference
      // region.y = target snap point
      // Zone covers the range between x and y.
      final double start = region.x < region.y ? region.x : region.y;
      final double end = region.x > region.y ? region.x : region.y;

      if (_targetScrollOffset >= start && _targetScrollOffset <= end) {
        // If we are already at the target (within epsilon), don't snap again
        if ((_targetScrollOffset - region.y).abs() < 1.0) continue;

        _isSnapping = true;
        _snapTarget = region.y;
        _springVelocity = 0.0; // Start fresh spring
        break;
      }
    }
  }

  /// Main update loop with spring physics.
  void update(double originalDt) {
    // Cap DT to prevent physics explosion on lag spikes
    final dt = originalDt.clamp(0.0, 0.05);

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

    // Safety Clamp: Prevent physics from overshooting bounds
    if (_minScroll != null && _maxScroll != null) {
      final oldTarget = _targetScrollOffset;
      _targetScrollOffset = _targetScrollOffset.clamp(_minScroll!, _maxScroll!);
      if (oldTarget != _targetScrollOffset) {
        // Kill momentum if we hit the wall
        _springVelocity = 0.0;
        _isSnapping = false; // Stop snapping if we hit bounds

        if (oldTarget.abs() > 3000) {
          LoggerUtil.log(
            'ScrollSystem',
            'Clamped target & Killed Velocity: $oldTarget -> $_targetScrollOffset',
          );
        }
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
