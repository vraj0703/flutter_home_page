import 'package:flame/components.dart';
import 'scroll_effect.dart';

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
