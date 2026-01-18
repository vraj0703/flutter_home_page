import 'dart:ui';
import 'package:flame/components.dart';

class GodRayComponent extends PositionComponent {
  // --- Tweak these values to customize the sun's appearance ---

  // Layer 1: The hot, tight core
  final double coreSize = 0.0;
  final Color coreColor = const Color(0xFFFFFFFF); // White-hot
  final double coreBlurSigma = 2.0;

  // Layer 2: The vibrant inner halo
  final double innerGlowSize = 24.0;
  final Color innerGlowColor = const Color(0xAAFFE082); // Golden Yellow
  final double innerGlowBlurSigma = 15.0;

  // Layer 3: The soft outer atmosphere
  final double outerGlowSize = 64.0;
  final Color outerGlowColor = const Color(0xAAE68A4D); // Dusty Orange
  final double outerGlowBlurSigma = 35.0;

  late final Paint _corePaint;
  late final Paint _innerGlowPaint;
  late final Paint _outerGlowPaint;

  GodRayComponent() {
    anchor = Anchor.center;
    // It's more performant to create Paint objects once.
    // The MaskFilter is what creates the beautiful blur effect.
    // The sigma value controls the "spread" of the blur.
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
    // We draw the layers from back to front (largest to smallest)
    // to ensure they stack correctly.
    canvas.drawCircle(Offset.zero, outerGlowSize, _outerGlowPaint);
    canvas.drawCircle(Offset.zero, innerGlowSize, _innerGlowPaint);
    canvas.drawCircle(Offset.zero, coreSize, _corePaint);
  }
}
