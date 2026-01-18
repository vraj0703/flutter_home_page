import 'dart:ui' show lerpDouble;

import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import '../interfaces/scroll_observer.dart';

/// Manages the global scroll state and notifies observers.
class ScrollSystem {
  double _scrollOffset = 0.0;
  final List<ScrollObserver> _observers = [];
  double _scrollVelocity = 0.0;
  double _lastScrollOffset = 0.0;
  double _lastUpdateTime = 0.0;
  bool _isSnapping = false;
  double _snapTarget = 0.0;

  static const List<double> snapPoints = [
    ScrollSequenceConfig.boldTextFadeInStart,
    ScrollSequenceConfig.boldTextEnd,
    ScrollSequenceConfig.philosophyEnd,
    ScrollSequenceConfig.workExpTitleHoldStart,
    ScrollSequenceConfig.skillsInteractEnd,
  ];
  static const double snapZoneRadius = GamePhysics.snapZoneRadius;
  static const double snapVelocityThreshold = GamePhysics.snapVelocityThreshold;
  static const double snapSpeed = GamePhysics.snapSpeed;

  double get scrollOffset => _scrollOffset;

  void register(ScrollObserver observer) {
    _observers.add(observer);
  }

  void unregister(ScrollObserver observer) {
    _observers.remove(observer);
  }

  void setScrollOffset(double offset) {
    _scrollOffset = offset;
    _notifyObservers();
  }

  void onScroll(double delta) {
    if (_isSnapping && delta.abs() > 5.0) {
      _isSnapping = false;
    }

    _scrollOffset += delta;
    if (_scrollOffset < 0) _scrollOffset = 0;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (_lastUpdateTime > 0) {
      final deltaTime = currentTime - _lastUpdateTime;
      if (deltaTime > 0) {
        final deltaOffset = _scrollOffset - _lastScrollOffset;
        _scrollVelocity = deltaOffset / deltaTime;
      }
    }
    _lastScrollOffset = _scrollOffset;
    _lastUpdateTime = currentTime;

    _checkSnapPoints();

    _notifyObservers();
  }

  /// Check if we should trigger snap to nearest point
  void _checkSnapPoints() {
    if (_isSnapping) return; // Already snapping

    // Only snap if velocity is low
    if (_scrollVelocity.abs() > snapVelocityThreshold) return;

    // Check if we're in any snap zone
    for (final snapPoint in snapPoints) {
      final distance = (_scrollOffset - snapPoint).abs();
      if (distance <= snapZoneRadius) {
        // Trigger snap
        _isSnapping = true;
        _snapTarget = snapPoint;
        break;
      }
    }
  }

  /// Update snap animation (called from game loop)
  void updateSnap(double dt) {
    if (!_isSnapping) return;

    // Lerp toward snap target with spring curve
    final distance = (_snapTarget - _scrollOffset).abs();
    if (distance < GamePhysics.snapDistanceThreshold) {
      _scrollOffset = _snapTarget;
      _isSnapping = false;
      _notifyObservers();
    } else {
      // Continue snapping
      _scrollOffset =
          lerpDouble(_scrollOffset, _snapTarget, dt * snapSpeed) ??
          _scrollOffset;
      _notifyObservers();
    }
  }

  void _notifyObservers() {
    for (final observer in _observers) {
      observer.onScroll(_scrollOffset);
    }
  }
}
