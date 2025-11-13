import 'dart:math' as Math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart'
    show
        Color,
        Paint,
        StatelessWidget,
        BuildContext,
        Widget,
        Stack,
        Scaffold,
        MaterialApp,
        Colors,
        Container,
        BoxDecoration,
        Alignment,
        RadialGradient;
import 'dart:ui';

import 'package:flutter/services.dart';

class FlameScene extends StatelessWidget {
  const FlameScene({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(children: [GameWidget(game: MyGame())]),
      ),
    );
  }
} // The main game class

class MyGame extends FlameGame with PointerMoveCallbacks {
  late RayMarchingShadowComponent shadowScene;
  late AdvancedGodRayComponent godRay;
  //late SpriteComponent logoSprite;
  late SdfLogoComponent logoComponent;

  // --- FIX 1: CHANGE VARIABLES TO REPRESENT DIRECTION ---
  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  final double smoothingSpeed = 8.0;
  final double glowVerticalOffset = 10.0;

  @override
  Color backgroundColor() => const Color(0xFFD8C5B4);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set an initial default direction
    _targetLightPosition = size / 2;
    _virtualLightPosition = size / 2;
    _targetLightDirection = Vector2(0, 1)..normalize();
    _lightDirection = _targetLightDirection.clone();

    // --- (Component loading is unchanged) ---
    final sprite = await Sprite.load('logo.png');
    final Image image = sprite.image;
    double zoom = 3;
    Vector2 logoSize =
        Vector2(image.width.toDouble(), image.height.toDouble()) * zoom;
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/god_rays.frag',
    );
    final shader = program.fragmentShader();

    final logoProgram = await FragmentProgram.fromAsset(
      'assets/shaders/logo.frag',
    );

    shadowScene = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: image,
      logoSize: logoSize,
    );
    shadowScene.logoPosition = size / 2;
    await add(shadowScene);

    /*final bgColor = backgroundColor();
    logoSprite = SpriteComponent(
      sprite: sprite,
      size: logoSize,
      position: size / 2,
      anchor: Anchor.center,
      priority: 10,
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = ColorFilter.mode(
          bgColor,          // Use the background color
          BlendMode.srcIn,  // This applies the color to the source image pixels
        ),
    );
    await add(logoSprite);*/

    final bgColor = backgroundColor();
    logoComponent = SdfLogoComponent(
      shader: logoProgram.fragmentShader(),
      logoTexture: image,
      tintColor: bgColor,
      size: logoSize,
      position: size / 2,
    );
    logoComponent.priority = 10; // Ensure it's drawn on top of the shadow
    await add(logoComponent);

    godRay = AdvancedGodRayComponent();
    godRay.priority = 20;
    godRay.position = size / 2;
    await add(godRay);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (isLoaded) {
      logoComponent.position = newSize / 2;
      shadowScene.logoPosition = newSize / 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isLoaded) {
      _virtualLightPosition.lerp(_targetLightPosition, smoothingSpeed * dt);
      _lightDirection.lerp(_targetLightDirection, smoothingSpeed * dt);

      // Pass both to the shader component
      shadowScene.lightPosition = _virtualLightPosition;
      shadowScene.lightDirection = _lightDirection;
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    godRay.position = event.localPosition;
    final center = size / 2;
    final cursorPosition = event.localPosition;

    _targetLightPosition = cursorPosition + Vector2(0, glowVerticalOffset);

    // --- THIS IS THE MOST IMPORTANT PART ---
    // We are now sending the RAW vector. DO NOT normalize it.
    final vectorFromCenter = cursorPosition - center;
    _targetLightDirection = vectorFromCenter;
  }
}

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
    // This section maps your Dart variables to the GLSL uniforms.
    // The index corresponds to the uniform's position in the shader.
    // 0, 1: uResolution (vec2)
    // 2, 3: uLightPos (vec2)
    // 4, 5: uLogoPos (vec2)
    // 6, 7: uLogoSize (vec2)
    // Sampler 0: uTexture (sampler2D)

    fragmentShader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, lightPosition.x)
      ..setFloat(3, lightPosition.y)
      ..setFloat(4, logoPosition.x)
      ..setFloat(5, logoPosition.y)
      ..setFloat(6, logoSize.x)
      ..setFloat(7, logoSize.y)
      ..setFloat(8, lightDirection.x) // Send the new direction uniform
      ..setFloat(9, lightDirection.y) // Send the new direction uniform
      ..setImageSampler(0, logoImage);

    _paint.shader = fragmentShader;
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}

class GodRayComponent extends PositionComponent {
  final Paint _paint = Paint();
  static const double rayRadius = 70.0;

  GodRayComponent() {
    anchor = Anchor.center;
    _paint.shader = Gradient.radial(
      Offset.zero,
      rayRadius,
      [
        const Color(0xF4F69E7C), // 244, 246, 158, 124
        const Color(0x80F69E7C), // 128, 246, 158, 124
        const Color(0x40EDDAD1), // 64, 237, 218, 209
      ],
      [0.0, 0.4, 1.0],
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, rayRadius, _paint);
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
  // -----------------------------------------------------------

  late final Paint _corePaint;
  late final Paint _innerGlowPaint;
  late final Paint _outerGlowPaint;

  AdvancedGodRayComponent() {
    // It's more performant to create Paint objects once.
    anchor = Anchor.center;

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

  SdfLogoComponent({
    required this.shader,
    required this.logoTexture,
    required this.tintColor,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    // Set the uniforms for our logo.frag shader
    // Index 0: uSize (vec2)
    // Sampler 0: uLogoTexture (sampler2D)
    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setImageSampler(0, logoTexture);

    // Create a Paint object that uses the shader and tints the result
    final paint = Paint()
      ..shader = shader
      ..colorFilter = ColorFilter.mode(
        tintColor,
        BlendMode.srcIn, // Apply tint to the shader's output
      );

    // Draw a rectangle covering the component's size
    canvas.drawRect(Offset.zero & size.toSize(), paint);
  }
}
