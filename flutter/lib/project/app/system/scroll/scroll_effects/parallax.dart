import 'package:flame/components.dart';

import 'scroll_effect.dart';

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
