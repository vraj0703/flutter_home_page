import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

/// Manages the global scroll state and notifies observers.
class ScrollSystem {
  double _scrollOffset = 0.0;
  final List<ScrollObserver> _observers = [];

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
    _scrollOffset += delta;
    _notifyObservers();
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
