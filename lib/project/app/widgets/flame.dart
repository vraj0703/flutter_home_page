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
  late SpriteComponent logoSprite; // The Visible Logo
  Vector2 _mousePosition = Vector2.zero();
  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();

  final double smoothingSpeed = 10;
  final double glowVerticalOffset = 2.0;

  @override
  Color backgroundColor() => const Color(0xFFE0E0E0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _targetLightPosition = size / 2;
    _virtualLightPosition = size / 2;
    // 1. Setup Assets
    final sprite = await Sprite.load('logo.png');
    final Image image = sprite.image;

    // Define Logo Size (Adjust this to match your design)
    double zoom = 0.8;
    Vector2 logoSize =
        Vector2(image.width.toDouble(), image.height.toDouble()) * zoom;

    // 2. Load Shader
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/god_rays.frag',
    );
    final shader = program.fragmentShader();

    // 3. Add Shadow Layer (Background)
    shadowScene = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: image,
      logoSize: logoSize, // Tell shader exactly how big the logo is
    );
    // Position it centered (logically)
    shadowScene.logoPosition = size / 2;
    await add(shadowScene);

    // 4. Add Logo Layer (Foreground)
    // This sits EXACTLY where the shader thinks the logo is
    logoSprite = SpriteComponent(
      sprite: sprite,
      size: logoSize,
      position: size / 2,
      anchor: Anchor.center,
      priority: 10, // Ensure it renders ON TOP of the shadow
    );
    await add(logoSprite);

    _mousePosition = size / 2 + Vector2(200, -100);

    godRay = GodRayComponent();
    godRay.priority = 100;
    await add(godRay);

    godRay.position = _mousePosition;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (isLoaded) {
      // Keep logo centered
      logoSprite.position = newSize / 2;
      shadowScene.logoPosition = newSize / 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isLoaded) {
      // Smoothly interpolate the virtual light towards its target.
      _virtualLightPosition.lerp(_targetLightPosition, smoothingSpeed * dt);

      // Pass the smoothed, virtual position to the shader.
      shadowScene.lightPosition = _virtualLightPosition;
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    // 1. The visible glow snaps directly to the cursor.
    godRay.position = event.localPosition;

    // --- FINAL, SIMPLIFIED LOGIC ---
    // 2. The light's target position is now taken directly from the cursor.
    // The "push" effect has been removed for a more direct feel.
    final cursorPosition = event.localPosition;

    // 3. Assemble the final target position.
    // It's simply the cursor's position plus the constant vertical offset.
    _targetLightPosition = Vector2(
      cursorPosition.x,
      cursorPosition.y + glowVerticalOffset,
    );
  }
}

class RayMarchingShadowComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final FragmentShader fragmentShader;
  final Image logoImage;
  Vector2 logoSize;
  Vector2 logoPosition = Vector2.zero();
  Vector2 lightPosition = Vector2.zero();

  final Paint _paint = Paint();

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
