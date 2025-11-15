import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter_home_page/project/app/widgets/reveal_animation.dart';
import 'components.dart';
import 'interactive_ui_component.dart';

class MyGame extends FlameGame with PointerMoveCallbacks {
  late RayMarchingShadowComponent shadowScene;
  late AdvancedGodRayComponent godRay;
  late InteractiveUIComponent interactiveUI;
  late SdfLogoComponent logoComponent;
  late final void Function() _sceneProgressListener;

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

    _sceneProgressListener = () {
      _sceneProgress = sceneProgressNotifier.value;
    };
    // Add the listener using the variable
    sceneProgressNotifier.addListener(_sceneProgressListener);

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
    sceneProgressNotifier.removeListener(_sceneProgressListener);
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

    // This block decides the behavior based on the animation's progress.
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
