import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class FlameScene extends StatelessWidget {
  const FlameScene({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // 1. The Flame GameWidget lives in the background
            GameWidget(game: ShadowGame()),
            // 2. The Flutter UI (button) lives on top
            //const Center(child: ClickAnywhereButton()),
          ],
        ),
      ),
    );
  }
}

class ShadowGame extends FlameGame with MouseMovementDetector {
  // A factor to control how much the shadow moves.
  // A smaller number means the "light" is "further away".
  final double _shadowFactor = 0.1;

  late SpriteComponent _faintLogo;
  late SpriteComponent _shadowLogo;
  late SpriteComponent _light;
  late Vector2 _center;
  Vector2 _targetPosition = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFFEBEBEB); // The hazy background color from the video

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cache the center of the screen
    _center = size / 2;

    // Step 2: Load the faint, static company logo
    _faintLogo = SpriteComponent.fromImage(
      await images.load('logo.png'),
      anchor: Anchor.center,
      position: _center,
      size: Vector2(300, 300),
      // Change opacity from 0.05 to 0.1
      paint: Paint()..color = Colors.black.withOpacity(1),
    );
    add(_faintLogo);

    _shadowLogo = SpriteComponent.fromImage(
      await images.load('shadow_logo.png'),
      anchor: Anchor.center,
      position: _center,
      size: Vector2(300, 300),
      // Add this line to make the shadow semi-transparent
      paint: Paint()..color = Colors.white.withOpacity(0.5),
    );
    add(_shadowLogo);

    // Step 4: Load the light source
    _light = SpriteComponent.fromImage(
      await images.load('sun.png'),
      anchor: Anchor.center,
      position: _center,
      size: Vector2(80, 80), // Adjust size as needed
    );
    add(_light);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _targetPosition = info.eventPosition.widget;
    super.onMouseMove(info);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // --- SMOOTHING LOGIC ---
    // 'dt' is 'delta time' - the time since the last frame.
    // We move the light 10% of the way to the target each frame.
    // This creates a smooth "chasing" effect.
    final double lerpFactor = 10.0 * dt;

    // Smoothly move the light's position towards the target
    _light.position.lerp(_targetPosition, lerpFactor);

    // --- SHADOW LOGIC ---
    // This logic is the same, but now it's in update()
    // so the shadow moves smoothly with the light.
    final lightVector = _light.position - _center;
    _shadowLogo.position = _center - (lightVector * _shadowFactor);
  }
}


class ClickAnywhereButton extends StatelessWidget {
  const ClickAnywhereButton({super.key});

  @override
  Widget build(BuildContext context) {
    const Color crosshairColor = Color(0x33000000); // Faint black
    const double crosshairThickness = 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          print('Clicked!');
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Horizontal crosshair
            Container(
              width: 150, // Match button size
              height: crosshairThickness,
              color: crosshairColor,
            ),
            // Vertical crosshair
            Container(
              width: crosshairThickness,
              height: 150, // Match button size
              color: crosshairColor,
            ),
            // The button
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: crosshairColor, width: 1.0),
              ),
              child: Center(
                child: Text(
                  'CLICK ANYWHERE',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


