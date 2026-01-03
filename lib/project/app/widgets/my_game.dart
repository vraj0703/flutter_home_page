import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/widgets/components/cinematic_title.dart';
import 'package:flutter_home_page/project/app/widgets/components/background_run_component.dart';
import 'components/god_ray.dart';
import 'components/carousal.dart';
import 'components/logo.dart';
import 'components/navigation_tabs.dart';
import 'components/logo_overlay.dart';

class MyGame extends FlameGame with PointerMoveCallbacks, TapCallbacks {
  VoidCallback? onStartExitAnimation;
  final Queuer queuer;
  final StateProvider stateProvider;

  MyGame({
    this.onStartExitAnimation,
    required this.queuer,
    required this.stateProvider,
  });

  late RayMarchingShadowComponent shadowScene;
  late GodRayComponent godRay;
  late LogoOverlayComponent interactiveUI;
  late LogoComponent logoComponent;
  late FragmentShader metallicShader;

  late BackgroundRunComponent backgroundRun;
  late CinematicTitleComponent cinematicTitle;

  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  // Transformation targets
  Vector2 _targetLogoPosition = Vector2.zero();
  double _targetLogoScale = 3.0; // Initial zoom
  double _currentLogoScale = 3.0;
  Vector2 _baseLogoSize = Vector2.zero();

  Vector2? _lastKnownPointerPosition;

  final double smoothingSpeed = 8.0;
  final double glowVerticalOffset = 10.0;

  late final Timer _inactivityTimer;
  static const double inactivityTimeout = 5.0;
  static const double uiFadeDuration = 0.5;

  // Unified State
  //GameState _gameState = GameState.introIdle;
  late NavigationTabsComponent _tabs;
  late ProjectCarouselComponent _carousel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = size / 2;

    _inactivityTimer = Timer(
      inactivityTimeout,
      onTick: () {},
      // The timer should only fire once per period of inactivity.
      repeat: false,
    );

    // --- Set Initial Centered State ---
    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();

    await loadLogoLayer();
    await loadLayerLineAndStart();
    await loadLayerName();

    queuer.queue(event: const SceneEvent.gameReady());
  }

  Future<void> loadLogoLayer() async {
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
    shadowScene = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: image,
      logoSize: logoSize,
    );
    shadowScene.logoPosition = size / 2;
    await add(shadowScene);

    final bgColor = backgroundColor();
    logoComponent = LogoComponent(
      shader: logoProgram.fragmentShader(),
      logoTexture: image,
      tintColor: bgColor,
      size: logoSize,
      position: size / 2,
    );
    logoComponent.priority = 10; // Ensure it's drawn on top of the shadow
    await add(logoComponent);

    godRay = GodRayComponent();
    godRay.priority = 20;
    godRay.position = size / 2;
    await add(godRay);
  }

  Future<void> loadLayerLineAndStart() async {
    interactiveUI = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    interactiveUI.position = size / 2;
    interactiveUI.priority = 30;
    interactiveUI.gameSize = size;
    interactiveUI.gameSize = size;
    await add(interactiveUI);
  }

  Future<void> loadLayerName() async {
    final backgroundProgram = await FragmentProgram.fromAsset(
      'assets/shaders/background_run_v2.frag',
    );

    backgroundRun = BackgroundRunComponent(
      shader: backgroundProgram.fragmentShader(),
      size: size,
      priority: 1,
    );
    await add(backgroundRun);

    final metallicTextProgram = await FragmentProgram.fromAsset(
      'assets/shaders/metallic_text.frag',
    );
    metallicShader = metallicTextProgram.fragmentShader();

    cinematicTitle = CinematicTitleComponent(
      primaryText: "VISHAL RAJ",
      secondaryText: "Welcome to my space",
      shader: metallicShader,
      position: size / 2, // Centered on screen
    );
    cinematicTitle.priority = 25; // Above logo, below UI
    add(cinematicTitle);

    _tabs = NavigationTabsComponent(shader: metallicShader);
    await add(_tabs);

    // 3. Load the carousel
    _carousel = ProjectCarouselComponent();
    await add(_carousel);
  }

  @override
  Color backgroundColor() => const Color(0xFFC78E53);

  @override
  void onTapDown(TapDownEvent event) {
    queuer.queue(event: SceneEvent.tapDown(event));
    super.onTapDown(event);
  }

  void loadTitleBackground() {
    // Fade in background shader
    backgroundRun.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        final center = size / 2;
        logoComponent.position = center;
        shadowScene.logoPosition = center;
        cinematicTitle.position = center;

        interactiveUI.position = center;
        interactiveUI.gameSize = size;
      },
      logoOverlayRemoving: () {},
      titleLoading: () {},
      title: () {},
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    final cursorPosition = _lastKnownPointerPosition ?? size / 2;
    followCursor(dt, cursorPosition);
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {
        cinematicTitle.position = size / 2;
        interactiveUI.inactivityOpacity += dt / uiFadeDuration;
      },
      logo: () {
        cinematicTitle.position = size / 2;
      },
      logoOverlayRemoving: () {
        zoomLogo(dt);
      },
      titleLoading: () {},
      title: () {},
    );
    _inactivityTimer.update(dt);
  }

  void zoomLogo(double dt) {
    _targetLogoPosition = Vector2(36, 36); // Top Left with padding
    _targetLogoScale = 0.3; // Shrink further to fit screen
    // Interpolate Logo Position to Top-Left
    logoComponent.position.lerp(_targetLogoPosition, dt * 5.0);
    shadowScene.logoPosition.lerp(_targetLogoPosition, dt * 5.0);

    // Interpolate Scale
    _currentLogoScale =
        lerpDouble(_currentLogoScale, _targetLogoScale, dt * 5.0) ?? 3.0;

    // Update components with new scale
    if (_baseLogoSize != Vector2.zero()) {
      final newSize = _baseLogoSize * _currentLogoScale;
      logoComponent.size = newSize;
      shadowScene.logoSize = newSize;
    }
  }

  void followCursor(double dt, Vector2 position) {
    godRay.position = position;
    _targetLightPosition = position + Vector2(0, glowVerticalOffset);

    final vectorFromCenter = position - size / 2;
    if (vectorFromCenter.length2 > 0) {
      _targetLightDirection = vectorFromCenter.normalized();
    }
    interactiveUI.cursorPosition = position - interactiveUI.position;

    // This smoothing logic runs every frame, ensuring a seamless transition
    // from the centered state to the user-controlled state.
    _virtualLightPosition.lerp(_targetLightPosition, smoothingSpeed * dt);
    _lightDirection.lerp(_targetLightDirection, smoothingSpeed * dt);

    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightDirection = _lightDirection;

    // --- FIX: Ensure shadow size always matches logo size ---
    // This handles both the manual lerp in 'update' AND the SizeEffects
    shadowScene.logoSize = logoComponent.size;
  }

  void enterTitle() {
    // 2. Trigger the text reveal once the screen "flashes"
    Future.delayed(const Duration(milliseconds: 500), () {
      cinematicTitle.show(() {
        queuer.queue(event: SceneEvent.titleLoaded());
      });
    });

    // Also tell GodRays to fade out or move
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}
