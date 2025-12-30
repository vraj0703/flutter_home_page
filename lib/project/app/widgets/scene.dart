import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/widgets/cinematic_title_sequence.dart';
import 'package:flutter_home_page/project/app/widgets/reveal_animation.dart';
// import 'package:flutter_home_page/project/app/widgets/jupiter_planet.dart';
import 'package:flutter_home_page/project/app/widgets/background_run_component.dart';
import 'components.dart';
import 'interactive_ui_component.dart';

enum UIState { visible, fadingOut, hidden, fadingIn }

enum HomeState { intro, transitioning, home }

class MyGame extends FlameGame with PointerMoveCallbacks, TapCallbacks {
  VoidCallback? onStartExitAnimation;
  VoidCallback? onHeaderAnimationComplete;

  MyGame({this.onStartExitAnimation});

  late RayMarchingShadowComponent shadowScene;
  late AdvancedGodRayComponent godRay;
  late InteractiveUIComponent interactiveUI;
  late SdfLogoComponent logoComponent;
  // late JupiterComponent jupiterPlanet;
  late BackgroundRunComponent backgroundRun;
  late final void Function() _sceneProgressListener;
  late CinematicTitleComponent _cinematicTitle;

  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  // Transformation targets
  Vector2 _targetLogoPosition = Vector2.zero();
  double _targetLogoScale = 3.0; // Initial zoom
  double _currentLogoScale = 3.0;
  Vector2 _baseLogoSize = Vector2.zero();

  HomeState _homeState = HomeState.intro;

  double _sceneProgress = 0.0;
  Vector2? _lastKnownPointerPosition;

  final double smoothingSpeed = 8.0;
  final double glowVerticalOffset = 10.0;

  late final Timer _inactivityTimer;
  UIState _uiState = UIState.visible;

  static const double inactivityTimeout = 5.0;
  static const double uiFadeDuration = 0.5;

  @override
  Color backgroundColor() => const Color(0xFFD8C5B4);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = size / 2;

    _inactivityTimer = Timer(
      inactivityTimeout,
      onTick: () {
        // This code runs when the user has been inactive for the timeout duration.
        // If the UI is currently fully visible, we trigger the fade-out.
        if (_uiState == UIState.visible) {
          _uiState = UIState.fadingOut;
        }
      },
      repeat:
          false, // The timer should only fire once per period of inactivity.
    );

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
    _baseLogoSize = Vector2(image.width.toDouble(), image.height.toDouble());
    Vector2 logoSize = _baseLogoSize * zoom;
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/god_rays.frag',
    );
    final shader = program.fragmentShader();

    final logoProgram = await FragmentProgram.fromAsset(
      'assets/shaders/logo.frag',
    );

    final backgroundProgram = await FragmentProgram.fromAsset(
      'assets/shaders/background_run_v2.frag',
    );

    backgroundRun = BackgroundRunComponent(
      shader: backgroundProgram.fragmentShader(),
      size: size,
      priority: 1,
    );
    await add(backgroundRun);

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

    _cinematicTitle = CinematicTitleComponent(
      primaryText: "VISHAL RAJ",
      secondaryText: "Welcome to my portfolio",
      position: size / 2, // Centered on screen
    );
    _cinematicTitle.priority = 25; // Above logo, below UI
    add(_cinematicTitle);

    interactiveUI = InteractiveUIComponent();
    interactiveUI.position = size / 2;
    interactiveUI.priority = 30;
    interactiveUI.gameSize = size;
    interactiveUI.gameSize = size;
    interactiveUI.onExitAnimationComplete = () {
      // Instead of exiting, we transition to the header state!
      animateToHeader();
      // onStartExitAnimation?.call(); // Old behavior
    };
    await add(interactiveUI);

    /*
    jupiterPlanet = JupiterComponent(
      shader: jupiterProgram.fragmentShader(),
      size: Vector2(300, 300),
      position: size / 2,
      anchor: Anchor.center,
    );
    jupiterPlanet.scale = Vector2.zero(); // Start hidden
    jupiterPlanet.priority = 5; // Behind logo, maybe equal to others
    await add(jupiterPlanet);
    */

    _inactivityTimer.start();
  }

  @override
  void onTapDown(TapDownEvent event) {
    interactiveUI.startExitAnimation();

    // Fade in background shader
    if (backgroundRun.opacity == 0) {
      backgroundRun.add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: 2.0, curve: Curves.easeInOut),
        ),
      );
    }

    super.onTapDown(event);
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
      if (_homeState == HomeState.intro) {
        logoComponent.position = center;
        shadowScene.logoPosition = center;
      }
      interactiveUI.position = center;
      interactiveUI.gameSize = size;
      /*
      if (_homeState != HomeState.home) {
        jupiterPlanet.position = center;
      } else {
        jupiterPlanet.position = center; // Always keep it centered for now
      }
      */
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    _cinematicTitle.position = size / 2;
    _inactivityTimer.update(dt);
    switch (_uiState) {
      case UIState.fadingOut:
        // Decrease the UI's opacity over the defined fade duration.
        interactiveUI.inactivityOpacity -= dt / uiFadeDuration;
        if (interactiveUI.inactivityOpacity <= 0.0) {
          interactiveUI.inactivityOpacity = 0.0;
          _uiState = UIState.hidden; // Transition to the hidden state.
        }
        break;
      case UIState.fadingIn:
        // Increase the UI's opacity over the defined fade duration.
        interactiveUI.inactivityOpacity += dt / uiFadeDuration;
        if (interactiveUI.inactivityOpacity >= 1.0) {
          interactiveUI.inactivityOpacity = 1.0;
          _uiState = UIState.visible; // Transition to the visible state.
        }
        break;
      case UIState.visible:
      case UIState.hidden:
        // In these stable states, we do nothing and wait for an event.
        break;
    }

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

    // --- Home Page Transformation Logic ---
    if (_homeState == HomeState.transitioning) {
      // Interpolate Logo Position to Top-Left
      logoComponent.position.lerp(_targetLogoPosition, dt * 5.0);
      shadowScene.logoPosition.lerp(_targetLogoPosition, dt * 5.0);

      // Interpolate Scale
      _currentLogoScale =
          lerpDouble(_currentLogoScale, _targetLogoScale, dt * 5.0) ?? 3.0;

      // Update components with new scale
      // Update components with new scale
      if (_baseLogoSize != Vector2.zero()) {
        final newSize = _baseLogoSize * _currentLogoScale;
        logoComponent.size = newSize;
        shadowScene.logoSize = newSize;
      }

      // Move UI "Vishal Raj" text to follow
      // interactiveUI is centered on screen, but we want it relative to logo?
      // Actually interactiveUI has its own logic.

      if (logoComponent.position.distanceTo(_targetLogoPosition) < 1.0) {
        _homeState = HomeState.home;
        onHeaderAnimationComplete?.call();
      }
    }
  }

  void animateToHeader() {
    _homeState = HomeState.transitioning;
    _targetLogoPosition = Vector2(60, 60); // Top Left with padding
    _targetLogoScale = 0.3; // Shrink further to fit screen

    godRay.add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(2.5),
          EffectController(duration: 0.4, curve: Curves.easeIn),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.8, curve: Curves.easeOut),
        ),
      ]),
    );

    // 2. Trigger the text reveal once the screen "flashes"
    Future.delayed(const Duration(milliseconds: 500), () {
      _cinematicTitle.show();
    });

    // 3. Existing logic for background shader
    if (backgroundRun.opacity < 1.0) {
      backgroundRun.add(OpacityEffect.to(1.0, EffectController(duration: 2.0)));
    }

    /*
    // Reveal Jupiter
    jupiterPlanet.add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 3.0, curve: Curves.easeInOut),
      ),
    );
    */

    // Also tell GodRays to fade out or move
    // godRay.add(OpacityEffect.fadeOut(EffectController(duration: 1.0)));
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}
