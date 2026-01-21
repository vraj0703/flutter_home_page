import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/shine_provider.dart';
import 'scroll_effect.dart';

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
