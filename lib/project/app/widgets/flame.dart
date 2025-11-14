import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
        TextStyle,
        Colors;
import 'dart:ui';

import 'reveal_animation.dart';

class FlameScene extends StatelessWidget {
  const FlameScene({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: RevealScene()),
    );
  }
} // The main game class

class MyGame extends FlameGame with PointerMoveCallbacks {
  late RayMarchingShadowComponent shadowScene;
  late AdvancedGodRayComponent godRay;
  late InteractiveUIComponent interactiveUI;
  late SdfLogoComponent logoComponent;

  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  double _sceneProgress = 0.0;
  Vector2? _lastKnownPointerPosition;

  final double smoothingSpeed = 8.0;
  final double glowVerticalOffset = 10.0;

  @override
  Color backgroundColor() => const Color(0xFFD8C5B4);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = size / 2;

    // --- Set Initial Centered State ---
    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();

    sceneProgressNotifier.addListener(() {
      _sceneProgress = sceneProgressNotifier.value;
    });

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

    interactiveUI = InteractiveUIComponent();
    interactiveUI.position = size / 2;
    interactiveUI.priority = 30;
    interactiveUI.position = size / 2;
    interactiveUI.gameSize = size;
    await add(interactiveUI);
  }

  @override
  void onRemove() {
    sceneProgressNotifier.removeListener(() {
      _sceneProgress = sceneProgressNotifier.value;
    });
    super.onRemove();
  }


  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      final center = size / 2;
      logoComponent.position = center;
      shadowScene.logoPosition = center;
      interactiveUI.position = center;
      interactiveUI.gameSize = size;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // --- CORE LOGIC CHANGE ---
    // This block now decides the behavior based on the animation's progress.

    if (_sceneProgress < 1.0) {
      // Animation is NOT complete. Keep everything fixed at the center.
      final center = size / 2;
      _targetLightPosition = center;
      godRay.position = center;
      _targetLightDirection = Vector2(0, -1)..normalize();
      interactiveUI.cursorPosition = Vector2.zero();
    } else {
      // Animation IS complete. Use the last known pointer position.
      // If the user hasn't moved the mouse yet, default to the center.
      final cursorPosition = _lastKnownPointerPosition ?? size / 2;

      // Update all interactive elements based on the cursor.
      godRay.position = cursorPosition;
      _targetLightPosition = cursorPosition + Vector2(0, glowVerticalOffset);

      final vectorFromCenter = cursorPosition - size / 2;
      if (vectorFromCenter.length2 > 0) {
        _targetLightDirection = vectorFromCenter.normalized();
      }
      interactiveUI.cursorPosition = cursorPosition - interactiveUI.position;
    }

    // This smoothing logic runs every frame, ensuring a seamless transition
    // from the centered state to the user-controlled state.
    _virtualLightPosition.lerp(_targetLightPosition, smoothingSpeed * dt);
    _lightDirection.lerp(_targetLightDirection, smoothingSpeed * dt);

    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightDirection = _lightDirection;
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
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

/// A component that renders an interactive UI element with circles, text,
/// and four lines that animate based on the cursor's position.
class InteractiveUIComponent extends PositionComponent
    with PointerMoveCallbacks {
  // --- Configuration ---
  final double ratio = 1;
  final double outerRadius = 135.0;
  final double innerRadius = 95.0;

  final double horizontalLineLength = 80.0;
  final double horizontalLineGap = 120.0;
  final double horizontalThreshold = 300.0;

  final double verticalLineLength = 70.0;
  final double verticalLineGap = 120.0;
  final double verticalThreshold = 150.0;

  final String _fullText = 'START';
  double _sceneProgress = 0.0;

  final Color uiColor = const Color(0xFFF9F8F6);

  final double startThickness = 3.0; // Thickness near the center
  final double endThickness = 0.5; // Thickness at the far end

  final List<Color> glassyColors = [
    const Color.fromRGBO(255, 255, 255, 0.2), // Faint Edge Highlight
    const Color.fromRGBO(255, 255, 255, 0.05), // Darker transparent part
    const Color.fromRGBO(255, 255, 255, 0.7), // Sharp Central Highlight
    const Color.fromRGBO(255, 255, 255, 0.05), // Darker transparent part
    const Color.fromRGBO(255, 255, 255, 0.2), // Faint Edge Highlight
  ];
  final List<double> glassyStops = [
    0.0, // Start edge
    0.4, // Start of central highlight
    0.5, // Peak of highlight
    0.6, // End of central highlight
    1.0, // End edge
  ];

  final BouncyLine _rightLine = BouncyLine();
  final BouncyLine _leftLine = BouncyLine();
  final BouncyLine _topLine = BouncyLine();
  final BouncyLine _bottomLine = BouncyLine();

  // --- State ---
  late final TextComponent _textComponent;
  late final Paint _materialPaint;

  Vector2 cursorPosition = Vector2.zero();
  Vector2 gameSize = Vector2.zero();

  InteractiveUIComponent() {
    sceneProgressNotifier.addListener(() {
      _sceneProgress = sceneProgressNotifier.value;
    });
  }

  // NEW: Add onRemove to clean up the listener
  @override
  void onRemove() {
    sceneProgressNotifier.removeListener(() {});
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set the component's anchor to its center for easy positioning.
    anchor = Anchor.center;

    // Configure the paint object for drawing circles and lines.
    _materialPaint = Paint()..style = PaintingStyle.fill;

    // Create and add the central text.
    _textComponent = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 15.0,
          color: uiColor,
          letterSpacing: 10.0,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: const Color(0xFF867665), // Shadow color with opacity
              offset: const Offset(5.0, 5.0), // X and Y displacement
              blurRadius: 10.0, // Blur radius of the shadow
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2, // Positioned at the center of this component
    );
    add(_textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final textProgress = ((_sceneProgress - 0.5) / 0.5).clamp(0.0, 1.0);
    final charCount = (_fullText.length * textProgress).floor();
    _textComponent.text = _fullText.substring(0, charCount);
    // --- NEW: NORMALIZED MOVEMENT LOGIC ---
    // Ensure gameSize is valid to avoid division by zero errors on the first frame.
    if (gameSize.x == 0 || gameSize.y == 0) return;

    // 1. Calculate the maximum possible cursor displacement from the center.
    final maxDisplacementX = gameSize.x / 2;
    final maxDisplacementY = gameSize.y / 2;

    // 2. Calculate the proportion of the cursor's displacement relative to the max.
    // This value is normalized to be between 0.0 and 1.0.
    final proportionX = (cursorPosition.x.abs() / maxDisplacementX).clamp(
      0.0,
      1.0,
    );
    final proportionY = (cursorPosition.y.abs() / maxDisplacementY).clamp(
      0.0,
      1.0,
    );

    // 3. Map this normalized proportion to the desired threshold for the lines' movement.
    final horizontalOffset = proportionX * horizontalThreshold;
    final verticalOffset = proportionY * verticalThreshold;

    // 4. Set the target positions for the physics simulation using the new offsets.
    _rightLine.targetPosition = horizontalOffset;
    _leftLine.targetPosition = -horizontalOffset;
    _bottomLine.targetPosition = verticalOffset;
    _topLine.targetPosition = -verticalOffset;

    // --- Physics and Rotation updates (unchanged) ---
    _rightLine.update(dt);
    _leftLine.update(dt);
    _topLine.update(dt);
    _bottomLine.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final fadeProgress = ((_sceneProgress - 0.2) / 0.8).clamp(0.0, 1.0);
    if (fadeProgress == 0.0) return;

    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withOpacity(fadeProgress),
    );
    super.render(canvas);
    final center = Vector2.zero();

    // Right line
    final rightPath = Path();
    final rightScaledLength = horizontalLineLength * _rightLine.scale;
    final rightStartX = _rightLine.currentPosition + horizontalLineGap;
    final rightEndX = rightStartX + rightScaledLength;
    rightPath.moveTo(rightStartX, center.y - startThickness / 2);
    rightPath.lineTo(rightEndX, center.y - endThickness / 2);
    rightPath.lineTo(rightEndX, center.y + endThickness / 2);
    rightPath.lineTo(rightStartX, center.y + startThickness / 2);
    rightPath.close();
    _materialPaint.shader = Gradient.linear(
      Offset(rightStartX, center.y - startThickness),
      Offset(rightStartX, center.y + startThickness),
      glassyColors,
      glassyStops,
    );
    canvas.drawPath(rightPath, _materialPaint);

    // Left line
    final leftPath = Path();
    final leftScaledLength = horizontalLineLength * _leftLine.scale;
    final leftStartX = _leftLine.currentPosition - horizontalLineGap;
    final leftEndX = leftStartX - leftScaledLength;
    leftPath.moveTo(leftStartX, center.y - startThickness / 2);
    leftPath.lineTo(leftEndX, center.y - endThickness / 2);
    leftPath.lineTo(leftEndX, center.y + endThickness / 2);
    leftPath.lineTo(leftStartX, center.y + startThickness / 2);
    leftPath.close();
    _materialPaint.shader = Gradient.linear(
      Offset(leftStartX, center.y - startThickness),
      Offset(leftStartX, center.y + startThickness),
      glassyColors,
      glassyStops,
    );
    canvas.drawPath(leftPath, _materialPaint);

    // Bottom line
    final bottomPath = Path();
    final bottomScaledLength = verticalLineLength * _bottomLine.scale;
    final bottomStartY = _bottomLine.currentPosition + verticalLineGap;
    final bottomEndY = bottomStartY + bottomScaledLength;
    bottomPath.moveTo(center.x - startThickness / 2, bottomStartY);
    bottomPath.lineTo(center.x - endThickness / 2, bottomEndY);
    bottomPath.lineTo(center.x + endThickness / 2, bottomEndY);
    bottomPath.lineTo(center.x + startThickness / 2, bottomStartY);
    bottomPath.close();
    _materialPaint.shader = Gradient.linear(
      Offset(center.x - startThickness, bottomStartY),
      Offset(center.x + startThickness, bottomStartY),
      glassyColors,
      glassyStops,
    );
    canvas.drawPath(bottomPath, _materialPaint);

    // Top line
    final topPath = Path();
    final topScaledLength = verticalLineLength * _topLine.scale;
    final topStartY = _topLine.currentPosition - verticalLineGap;
    final topEndY = topStartY - topScaledLength;
    topPath.moveTo(center.x - startThickness / 2, topStartY);
    topPath.lineTo(center.x - endThickness / 2, topEndY);
    topPath.lineTo(center.x + endThickness / 2, topEndY);
    topPath.lineTo(center.x + startThickness / 2, topStartY);
    topPath.close();
    _materialPaint.shader = Gradient.linear(
      Offset(center.x - startThickness, topStartY),
      Offset(center.x + startThickness, topStartY),
      glassyColors,
      glassyStops,
    );
    canvas.drawPath(topPath, _materialPaint);

    canvas.restore();
  }
}

class BouncyLine {
  // --- Physics Configuration ---
  final double stiffness = 500.0; // How "strong" the spring is
  final double damping = 70.0; // How quickly it stops bouncing
  final double mass = 20.0; // The "weight" of the line

  // --- State ---
  double currentPosition = 0.0;
  double targetPosition = 0.0;
  double velocity = 0.0;

  // --- Size Animation ---
  double scale = 1.0;
  final double maxScale = 2; // How big it gets when moving fast
  final double scaleSpeed = 15.0; // How fast it scales

  void update(double dt) {
    // --- Spring Physics Calculation ---
    final double springForce = (targetPosition - currentPosition) * stiffness;
    final double dampingForce = -velocity * damping;
    final double totalForce = springForce + dampingForce;
    final double acceleration = totalForce / mass;
    velocity += acceleration * dt;
    currentPosition += velocity * dt;

    // --- Scale Animation Calculation ---
    final double targetScale =
        1.0 + (velocity.abs() / 150.0).clamp(0, maxScale - 1.0);
    scale = scale + (targetScale - scale) * scaleSpeed * dt;
  }
}
