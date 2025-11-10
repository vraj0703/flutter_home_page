import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/post_process.dart';
import 'package:flame_svg/svg.dart';
import 'package:flame_svg/svg_component.dart';
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
        Colors;
import 'dart:ui';

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

// Use PointerMoveCallbacks to get mouse movement events
class MyGame extends FlameGame with PointerMoveCallbacks {
  Vector2 _mousePosition = Vector2.zero();
  late GodRayComponent godRay;

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final svgAsset = await Svg.load('images/logo.svg');
    final svgComponent = SvgComponent(
      svg: svgAsset,
      position: size / 2, // Center it
      anchor: Anchor.center,
      size: Vector2.all(300), // Give it a size
    );
    svgComponent.priority = 1;
    await add(svgComponent);

    // Create and add the god ray component
    godRay = GodRayComponent();
    godRay.priority = 2;
    await add(godRay);

    godRay.position = _mousePosition;
  }

  // This callback is from PointerMoveCallbacks
  // It is triggered whenever the mouse moves over the game widget
  @override
  void onPointerMove(PointerMoveEvent event) {
    // Update the godRay's position to the mouse's game position
    // event.localPosition gives the position in the game's coordinate system
    _mousePosition = event.localPosition;
  }
}

class GodRayComponent extends PositionComponent with HasGameReference<MyGame> {
  final Paint _paint = Paint();
  static const double rayRadius = 50.0;
  final double smoothingSpeed = 5.0;

  GodRayComponent() {
    anchor = Anchor.center;

    _paint.shader = Gradient.radial(
      Offset.zero,
      rayRadius,
      [
        Colors.yellow.withOpacity(0.9),
        Colors.yellow.withOpacity(0.5),
        Colors.orange.withOpacity(0.0),
      ],
      [0.0, 0.5, 1.0],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Get the target position from the game class using `game`
    final Vector2 targetPosition = game._mousePosition;

    // Use lerp (linear interpolation) to move smoothly
    position.lerp(targetPosition, smoothingSpeed * dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, rayRadius, _paint);
  }
}
