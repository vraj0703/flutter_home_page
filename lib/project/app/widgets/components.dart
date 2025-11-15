import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/widgets/scene.dart';

class RayMarchingShadowComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final FragmentShader fragmentShader;
  final Image logoImage;
  Vector2 logoSize;
  Vector2 logoPosition = Vector2.zero();

  final Paint _paint = Paint();

  Vector2 lightPosition = Vector2.zero();
  Vector2 lightDirection = Vector2.zero();

  RayMarchingShadowComponent({
    required this.fragmentShader,
    required this.logoImage,
    required this.logoSize,
  });

  @override
  void render(Canvas canvas) {
    size = game.size;
    if (size.x == 0 || size.y == 0) return;

    // --- Uniform Mapping ---
    fragmentShader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, lightPosition.x)
      ..setFloat(3, lightPosition.y)
      ..setFloat(4, logoPosition.x)
      ..setFloat(5, logoPosition.y)
      ..setFloat(6, logoSize.x)
      ..setFloat(7, logoSize.y)
      ..setFloat(8, lightDirection.x)
      ..setFloat(9, lightDirection.y)
      ..setImageSampler(0, logoImage);

    _paint.shader = fragmentShader;
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}

class AdvancedGodRayComponent extends PositionComponent {
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

  AdvancedGodRayComponent() {
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

class SdfLogoComponent extends PositionComponent {
  final FragmentShader shader;
  final Image logoTexture;
  final Color tintColor;
  late final Paint _paint;

  SdfLogoComponent({
    required this.shader,
    required this.logoTexture,
    required this.tintColor,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    // Create a Paint object that uses the shader and tints the result
    _paint = Paint()
      ..shader = shader
      ..colorFilter = ColorFilter.mode(
        tintColor,
        BlendMode.srcIn, // Apply tint to the shader's output
      );
  }

  @override
  void render(Canvas canvas) {
    // Set the uniforms for our logo.frag shader
    // Index 0: uSize (vec2)
    // Sampler 0: uLogoTexture (sampler2D)
    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setImageSampler(0, logoTexture);

    // Draw a rectangle covering the component's size
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}
