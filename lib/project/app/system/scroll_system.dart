import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/interfaces/shine_provider.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';
import 'dart:ui' show lerpDouble;

/// Manages the global scroll state and notifies observers.
class ScrollSystem {
  double _scrollOffset = 0.0;
  final List<ScrollObserver> _observers = [];

  // Velocity tracking for snap behavior
  double _scrollVelocity = 0.0;
  double _lastScrollOffset = 0.0;
  double _lastUpdateTime = 0.0;
  bool _isSnapping = false;
  double _snapTarget = 0.0;

  // Snap configuration - Updated for compressed timing (faster scroll speed)
  static const List<double> snapPoints = [500, 1700, 3100, 10400]; // Key positions: bold text, philosophy, experience, skills
  static const double snapZoneRadius = 60.0; // Slightly larger for smoother feel
  static const double snapVelocityThreshold = 40.0; // Lower threshold for easier snap
  static const double snapSpeed = 6.0; // Slower for more graceful snap
  final SpringCurve _snapCurve = const SpringCurve(mass: 1.0, stiffness: 180.0, damping: 12.0);

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
    // If user scrolls during snap, cancel snap immediately
    if (_isSnapping && delta.abs() > 5.0) {
      _isSnapping = false;
    }

    _scrollOffset += delta;
    if (_scrollOffset < 0) _scrollOffset = 0; // Clamp min

    // Update velocity tracking
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

    // Check for snap points
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
    if (distance < 5.0) {
      // Close enough, complete snap
      _scrollOffset = _snapTarget;
      _isSnapping = false;
      _notifyObservers();
    } else {
      // Continue snapping
      _scrollOffset = lerpDouble(_scrollOffset, _snapTarget, dt * snapSpeed) ?? _scrollOffset;
      _notifyObservers();
    }
  }

  void _notifyObservers() {
    for (final observer in _observers) {
      observer.onScroll(_scrollOffset);
    }
  }
}

/// Interface for objects that want to react to scroll changes.
abstract class ScrollObserver {
  void onScroll(double scrollOffset);
}

/// Base class for scroll-driven effects.
abstract class ScrollEffect<T extends PositionComponent> {
  final double startScroll;
  final double endScroll;
  final Curve curve;

  ScrollEffect({
    required this.startScroll,
    required this.endScroll,
    this.curve = Curves.linear,
  });

  /// Applies the effect to the component based on current global scrollOffset.
  void apply(T component, double scrollOffset) {
    if (scrollOffset < startScroll) {
      update(component, 0.0);
    } else if (scrollOffset > endScroll) {
      update(component, 1.0);
    } else {
      final t = (scrollOffset - startScroll) / (endScroll - startScroll);
      final curvedT = curve.transform(t);
      update(component, curvedT);
    }
  }

  /// Update the component based on progress (0.0 to 1.0).
  @protected
  void update(T component, double progress);
}

// --- Concrete Effects ---

class OpacityScrollEffect extends ScrollEffect<PositionComponent> {
  final double startOpacity;
  final double endOpacity;

  OpacityScrollEffect({
    required super.startScroll,
    required super.endScroll,
    this.startOpacity = 0.0,
    this.endOpacity = 1.0,
    super.curve,
  });

  @override
  void update(PositionComponent component, double progress) {
    final current = startOpacity + (endOpacity - startOpacity) * progress;

    if (component is OpacityProvider) {
      (component as OpacityProvider).opacity = current;
    } else if (component is HasPaint) {
      (component as HasPaint).opacity = current;
    }
  }
}

class ParallaxScrollEffect extends ScrollEffect<PositionComponent> {
  final Vector2 startOffset;
  final Vector2 endOffset;
  final Vector2 initialPosition;

  ParallaxScrollEffect({
    required super.startScroll,
    required super.endScroll,
    required this.initialPosition,
    Vector2? startOffset,
    required this.endOffset,
    super.curve,
  }) : startOffset = startOffset ?? Vector2.zero();

  @override
  void update(PositionComponent component, double progress) {
    final currentOffset = Vector2(
      startOffset.x + (endOffset.x - startOffset.x) * progress,
      startOffset.y + (endOffset.y - startOffset.y) * progress,
    );
    component.position = initialPosition + currentOffset;
  }
}

class ScaleScrollEffect extends ScrollEffect<PositionComponent> {
  final Vector2 startScale;
  final Vector2 endScale;

  ScaleScrollEffect({
    required super.startScroll,
    required super.endScroll,
    required this.startScale,
    required this.endScale,
    super.curve,
  });

  @override
  void update(PositionComponent component, double progress) {
    final currentScale = Vector2(
      startScale.x + (endScale.x - startScale.x) * progress,
      startScale.y + (endScale.y - startScale.y) * progress,
    );
    component.scale = currentScale;
  }
}

class RotateScrollEffect extends ScrollEffect<PositionComponent> {
  final double startAngle;
  final double endAngle;

  RotateScrollEffect({
    required super.startScroll,
    required super.endScroll,
    this.startAngle = 0.0,
    required this.endAngle, // Radians
    super.curve,
  });

  @override
  void update(PositionComponent component, double progress) {
    final currentAngle = startAngle + (endAngle - startAngle) * progress;
    component.angle = currentAngle;
  }
}

class ShineScrollEffect extends ScrollEffect<PositionComponent> {
  ShineScrollEffect({
    required super.startScroll,
    required super.endScroll,
    super.curve,
  });

  @override
  void update(PositionComponent component, double progress) {
    if (component is ShineProvider) {
      (component as ShineProvider).fillProgress = progress;
    }
  }
}
