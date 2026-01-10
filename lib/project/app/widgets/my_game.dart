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
import 'package:flutter_home_page/project/app/widgets/components/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/widgets/components/background_run_component.dart';
import 'components/god_ray.dart';
import 'components/carousal.dart';
import 'components/logo.dart';
import 'components/navigation_tabs.dart';
import 'components/logo_overlay.dart';

class MyGame extends FlameGame
    with PointerMoveCallbacks, TapCallbacks, ScrollDetector {
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
  late CinematicSecondaryTitleComponent cinematicSecondaryTitle;

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
  static const double headerY = 60.0;

  // Unified State
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
      shader: metallicShader,
      position: size / 2, // Centered on screen
    );
    cinematicTitle.priority = 25; // Above logo, below UI
    add(cinematicTitle);

    cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: "Welcome to my space",
      shader: metallicShader,
      position:
          size / 2 +
          Vector2(
            0,
            48 + 17,
          ), // Match previous relative offset (48) + internal offset fix (17) ??
      // Wait, primary title moved its internal offset to (0, 17).
      // Secondary was at (0, 48).
      // So if both are centered at size/2...
      // Primary Text is at size/2 + (0, 17).
      // Secondary Text was at size/2 + (0, 48). (Relative to parent center)
      // So I should position the component at size/2 + (0, 48).
    );
    // Actually, Secondary Text was anchored Center.
    // CinematicTitleComponent was centered.
    // Secondary relative position was (0, 48).
    // So absolute position is size/2 + (0, 48).

    cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: "Welcome to my space",
      shader: metallicShader,
      position: size / 2 + Vector2(0, 48),
    );
    cinematicSecondaryTitle.priority = 24;
    add(cinematicSecondaryTitle);

    _tabs = NavigationTabsComponent(shader: metallicShader);
    await add(_tabs);

    // 3. Load the carousel
    _carousel = ProjectCarouselComponent();
    // await add(_carousel);
  }

  @override
  Color backgroundColor() => const Color(0xFFC78E53);

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;
    queuer.queue(event: const SceneEvent.onScroll());
  }

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
    final center = size / 2;
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        logoComponent.position = center;
        shadowScene.logoPosition = center;
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);

        interactiveUI.position = center;
        interactiveUI.gameSize = size;
      },
      logoOverlayRemoving: () {},
      titleLoading: () {
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);
      },
      title: () {
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);
      },
      menu: () {
        _updateMenuLayoutTargets();
        // Title logic is now handled by enterMenu's one-off animation
        // In menu state, title should disappear, so we don't need to update it here
        // to avoid it snapping back.
        // If we are resizing while menu is active, just update tabs.
        // Note: we might want to check if tabs are visible to update their layout?
        // _tabs.updateLayout checks internal items list so it's safe.
        // Collision logic is gone since title becomes a tab.
        _tabs.updateLayout(size);
      },
    );
  }

  void _updateMenuLayoutTargets() {
    final logoScale = 0.25;
    final logoW = _baseLogoSize.x * logoScale;
    // final gap = 15.0; // Unused
    final headerY =
        MyGame.headerY; // Standardized vertical center for header elements

    final startX = 60.0; // Left Margin

    // Logo Left align (center of logo relative to startX)
    final logoCX = startX + (logoW / 2);
    _targetLogoPosition = Vector2(logoCX, headerY);
    _targetLogoScale = logoScale;

    // Title alignment logic removed as it transitions to a tab.
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
        cinematicSecondaryTitle.position = size / 2 + Vector2(0, 48);
        interactiveUI.inactivityOpacity += dt / uiFadeDuration;
      },
      logo: () {
        cinematicTitle.position = size / 2;
      },
      logoOverlayRemoving: () {
        _targetLogoPosition = Vector2(36, 36);
        _targetLogoScale = 0.3;
        _animateLogo(dt);
      },
      titleLoading: () {},
      title: () {},
      menu: () {
        _animateLogo(dt);
      },
    );
    _inactivityTimer.update(dt);
  }

  void _animateLogo(double dt) {
    // Interpolate Logo Position
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

    // --- Ensure shadow size always matches logo size ---
    // This handles both the manual lerp in 'update' AND the SizeEffects
    shadowScene.logoSize = logoComponent.size;
  }

  void enterTitle() {
    Future.delayed(const Duration(milliseconds: 500), () {
      cinematicTitle.show(() {
        // Once Primary Title finishes, show Secondary Title
        cinematicSecondaryTitle.show(() {
          // Once Secondary Title finishes, fire readiness event (Arrow)
          queuer.queue(event: SceneEvent.titleLoaded());
        });
      });
    });
  }

  void enterMenu() {
    _updateMenuLayoutTargets();

    // 1. Calculate Target Position (First Tab)
    // We get the position where the "Vishal Raj" tab will be.
    final firstTabPos = _tabs.getFirstTabPosition(size);

    // 2. Animate Title to becomes the first tab
    // Target scale: Tab Font (20) / Title Font (54)
    final targetScale = 20.0 / 54.0;

    // Hide Secondary Title immediately/fade out
    cinematicSecondaryTitle.hide();

    cinematicTitle.animateToTab(firstTabPos, targetScale, () {
      // 3. On Complete: Title stays visible as the "first tab"
      _tabs.show(hideFirst: true);
    });

    _tabs.setActive(0);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}
