import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class GodRayComponent extends PositionComponent {
  // Base sizes (multiplied by current scale multiplier)
  final double baseCoreSize = GameLayout.godRayCoreSize;
  final double baseCoreBlurSigma = GameLayout.godRayCoreBlur;
  final double baseInnerGlowSize = GameLayout.godRayInnerSize;
  final double baseInnerGlowBlurSigma = GameLayout.godRayInnerBlur;
  final double baseOuterGlowSize = GameLayout.godRayOuterSize;
  final double baseOuterGlowBlurSigma = GameLayout.godRayOuterBlur;

  // Default colors
  final Color defaultCoreColor = GameStyles.godRayCore;
  final Color defaultInnerColor = GameStyles.godRayInner;
  final Color defaultOuterColor = GameStyles.godRayOuter;

  // Dynamic state (updated by controller)
  double sizeMultiplier = 1.0;
  Color currentCoreColor = GameStyles.godRayCore;
  Color currentInnerColor = GameStyles.godRayInner;
  Color currentOuterColor = GameStyles.godRayOuter;

  late final Paint _corePaint;
  late final Paint _innerGlowPaint;
  late final Paint _outerGlowPaint;

  GodRayComponent() {
    anchor = Anchor.center;
    _outerGlowPaint = Paint()
      ..color = defaultOuterColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseOuterGlowBlurSigma);

    _innerGlowPaint = Paint()
      ..color = defaultInnerColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseInnerGlowBlurSigma);

    _corePaint = Paint()
      ..color = defaultCoreColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseCoreBlurSigma);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Update paint colors
    _outerGlowPaint.color = currentOuterColor;
    _innerGlowPaint.color = currentInnerColor;
    _corePaint.color = currentCoreColor;

    // Draw with current size multiplier
    final coreSize = baseCoreSize * sizeMultiplier;
    final innerSize = baseInnerGlowSize * sizeMultiplier;
    final outerSize = baseOuterGlowSize * sizeMultiplier;

    canvas.drawCircle(Offset.zero, outerSize, _outerGlowPaint);
    canvas.drawCircle(Offset.zero, innerSize, _innerGlowPaint);
    canvas.drawCircle(Offset.zero, coreSize, _corePaint);
  }
}
