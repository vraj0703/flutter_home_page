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
  late GodRayComponent godRay;
  late SpriteComponent logoSprite;

  // --- FIX 1: CHANGE VARIABLES TO REPRESENT DIRECTION ---
  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  final double smoothingSpeed = 5.0;
  final double glowVerticalOffset = 15.0;

  @override
  Color backgroundColor() => const Color(0xFFE0E0E0);

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
    shadowScene = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: image,
      logoSize: logoSize,
    );
    shadowScene.logoPosition = size / 2;
    await add(shadowScene);
    logoSprite = SpriteComponent(
      sprite: sprite,
      size: logoSize,
      position: size / 2,
      anchor: Anchor.center,
      priority: 10,
    );
    await add(logoSprite);
    godRay = GodRayComponent();
    godRay.priority = 20;
    godRay.position = size / 2;
    await add(godRay);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (isLoaded) {
      logoSprite.position = newSize / 2;
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
    // --- FIX 3: UPDATE BOTH TARGETS ---
    godRay.position = event.localPosition;
    final center = size / 2;
    final cursorPosition = event.localPosition;

    // Update the target position (for the glow)
    _targetLightPosition = cursorPosition + Vector2(0, glowVerticalOffset);

    // Update the target direction (for the shadows)
    final vectorFromCenter = cursorPosition - center;
    if (vectorFromCenter.length > 0) {
      _targetLightDirection = vectorFromCenter..normalize();
    }
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

class GodRayComponent extends PositionComponent with HasGameReference<MyGame> {
  final Paint _paint = Paint();
  static const double rayRadius = 50.0;

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
      [0.0, 0.5, 1.0],
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, rayRadius, _paint);
  }
}
