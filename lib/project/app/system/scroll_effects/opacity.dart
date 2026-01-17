import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'scroll_effect.dart';

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
