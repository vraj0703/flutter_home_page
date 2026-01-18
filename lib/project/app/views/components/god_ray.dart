import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class GodRayComponent extends PositionComponent {
  // Layer 1: The hot, tight core
  final double coreSize = GameLayout.godRayCoreSize;
  final Color coreColor = GameStyles.godRayCore;
  final double coreBlurSigma = GameLayout.godRayCoreBlur;

  // Layer 2: The vibrant inner halo
  final double innerGlowSize = GameLayout.godRayInnerSize;
  final Color innerGlowColor = GameStyles.godRayInner;
  final double innerGlowBlurSigma = GameLayout.godRayInnerBlur;

  // Layer 3: The soft outer atmosphere
  final double outerGlowSize = GameLayout.godRayOuterSize;
  final Color outerGlowColor = GameStyles.godRayOuter;
  final double outerGlowBlurSigma = GameLayout.godRayOuterBlur;

  late final Paint _corePaint;
  late final Paint _innerGlowPaint;
  late final Paint _outerGlowPaint;

  GodRayComponent() {
    anchor = Anchor.center;
    _outerGlowPaint = Paint()
      ..color = outerGlowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerGlowBlurSigma);

    _innerGlowPaint = Paint()
      ..color = innerGlowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, innerGlowBlurSigma);

    _corePaint = Paint()
      ..color = coreColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreBlurSigma);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, outerGlowSize, _outerGlowPaint);
    canvas.drawCircle(Offset.zero, innerGlowSize, _innerGlowPaint);
    canvas.drawCircle(Offset.zero, coreSize, _corePaint);
  }
}
