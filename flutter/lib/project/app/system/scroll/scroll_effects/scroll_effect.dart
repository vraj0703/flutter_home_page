import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';

/// Base class for scroll-driven effects.
abstract class ScrollEffect<T extends PositionComponent> {
  final double startScroll;
  final double endScroll;
  final Curve curve;

  ScrollEffect({
    required this.startScroll,
    required this.endScroll,
    this.curve = GameCurves.standardLinear,
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
