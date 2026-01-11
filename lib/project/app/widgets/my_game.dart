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
import 'components/logo.dart';
import 'components/logo_overlay.dart';
import 'components/grid_component.dart';
import 'components/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/bold_text_controller.dart';
import 'package:flutter/material.dart' as material;

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

  BoldTextRevealComponent? boldTextReveal;

  late final GridComponent gridComponent;
  RectangleComponent? _dimLayer;

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
  // late NavigationTabsComponent _tabs;
  // late ProjectCarouselComponent _carousel;

  final ScrollSystem scrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();

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

    // Register Orchestrator
    scrollSystem.register(scrollOrchestrator);
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
      position: size / 2 + Vector2(0, 48),
    );
    cinematicSecondaryTitle.priority = 24;
    add(cinematicSecondaryTitle);

    // Bold Text Reveal ("Crafting Clarity from Chaos.")
    // We use shine_text.frag which now houses the "Corrected Metallic" logic
    final shineProgram = await FragmentProgram.fromAsset(
      'assets/shaders/shine_text.frag',
    );

    boldTextReveal = BoldTextRevealComponent(
      text: "Crafting Clarity from Chaos.",
      textStyle: material.TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w500,
        fontFamily: 'InconsolataNerd',
        letterSpacing: 2.0,
      ),
      shader: shineProgram.fragmentShader(),
      baseColor: const Color(0xFFCCCCCC), // Lighter Grey to fix "Blur"/Darkness
      // Shine/Edge colors are unused by the ported logic
      position: size / 2,
    );
    boldTextReveal!.priority = 26; // High priority
    // Initially invisible, handled by scroll effect
    boldTextReveal!.opacity = 0.0;
    await add(boldTextReveal!);

    // _tabs = NavigationTabsComponent(shader: metallicShader);
    // await add(_tabs);

    // Grid Component (Initially hidden/transparent handled by component)
    gridComponent = GridComponent(
      shader: metallicShader,
      scrollOrchestrator: scrollOrchestrator,
    );
    await add(gridComponent);

    // Dim Layer (Overlay)
    _dimLayer = RectangleComponent(
      priority: 2, // Above background (1), below content (likely > 2)
      size: size,
      paint: Paint()..color = const Color(0xFF000000).withValues(alpha: 0.0),
    );
    await add(_dimLayer!);

    // 3. Load the carousel
    //_carousel = ProjectCarouselComponent();
    // await add(_carousel);
  }

  @override
  Color backgroundColor() => const Color(0xFFC78E53);

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;
    queuer.queue(event: const SceneEvent.onScroll());

    // Always update global ScrollSystem to ensure continuity across state transitions
    final delta = info.scrollDelta.global.y;
    scrollSystem.onScroll(delta);

    stateProvider.sceneState().maybeWhen(
      menu: (uiOpacity) {
        // Dispatch requested event based on delta (for other listeners if any)
        queuer.queue(event: SceneEvent.onScrollSequence(delta));
      },
      orElse: () {},
    );
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
      menu: (uiOpacity) {
        // Opacity handled by bindings, but we trigger layout update
        _updateMenuLayoutTargets();
        // _tabs.updateLayout(size);
        // Grid auto-updates via onGameResize
      },
    );
    _dimLayer?.size = size;
    // Keep boldTextReveal centered reference for parallax
    boldTextReveal?.position = center;
  }

  void _updateMenuLayoutTargets() {
    final logoScale = 0.25;
    final logoW = _baseLogoSize.x * logoScale;
    final headerY = MyGame.headerY;
    final startX = 60.0;
    final logoCX = startX + (logoW / 2);
    _targetLogoPosition = Vector2(logoCX, headerY);
    _targetLogoScale = logoScale;
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
      menu: (uiOpacity) {
        _targetLightPosition = size / 2; // Assuming _centerPosition is size / 2
        _animateLogo(dt);
      },
    );
    _inactivityTimer.update(dt);
  }

  void _animateLogo(double dt) {
    logoComponent.position.lerp(_targetLogoPosition, dt * 5.0);
    shadowScene.logoPosition.lerp(_targetLogoPosition, dt * 5.0);
    _currentLogoScale =
        lerpDouble(_currentLogoScale, _targetLogoScale, dt * 5.0) ?? 3.0;

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
    _virtualLightPosition.lerp(_targetLightPosition, smoothingSpeed * dt);
    _lightDirection.lerp(_targetLightDirection, smoothingSpeed * dt);
    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightDirection = _lightDirection;
    shadowScene.logoSize = logoComponent.size;
  }

  void enterTitle() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () => cinematicTitle.show(
        () => cinematicSecondaryTitle.show(
          () => queuer.queue(event: SceneEvent.titleLoaded()),
        ),
      ),
    );
  }

  void enterMenu() {
    _updateMenuLayoutTargets();

    // Ensure clean scroll state
    scrollSystem.setScrollOffset(0.0);

    // 1. Reset Title State if needed (ensure visible)
    cinematicTitle.show(() {});
    cinematicSecondaryTitle.show(() {});

    // 2. Bind Titles to Scroll System (Parallax Upwards)
    // They are centered. As we scroll, they move up.
    // initialPosition is set in _updateMenuLayoutTargets or standard layout for 'menu' state.
    // We want them to scroll away.

    // Bind Cinematic Title
    scrollOrchestrator.addBinding(
      cinematicTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: 1000,
        initialPosition: cinematicTitle.position.clone(),
        endOffset: Vector2(0, -1000),
      ),
    );
    // Title Fade Out (Ensure it's gone before Bold Text enters at 500)
    scrollOrchestrator.addBinding(
      cinematicTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 500,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
    );

    // Bind Secondary Title Position
    scrollOrchestrator.addBinding(
      cinematicSecondaryTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: 1000,
        initialPosition: cinematicSecondaryTitle.position.clone(),
        endOffset: Vector2(0, -1000),
      ),
    );

    // Bind Secondary Title Fade Out (Faster)
    scrollOrchestrator.addBinding(
      cinematicSecondaryTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
    );

    // Bind LogoOverlay Fade Out (Interactive UI)
    scrollOrchestrator.addBinding(
      interactiveUI,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
      ),
    );

    // Bind Dim Layer Fade In
    scrollOrchestrator.addBinding(
      _dimLayer!,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 300,
        startOpacity: 0.0,
        endOpacity: 0.6,
      ),
    );

    // --- BOLD TEXT SEQUENCE ---
    // Controller manages Position, Opacity, and Shine via ScrollObserver
    // This resolves conflicts by having a single source of truth for the logic.
    scrollSystem.register(
      BoldTextController(
        component: boldTextReveal!,
        screenWidth: size.x,
        centerPosition: size / 2,
      ),
    );

    // --- GRID SEQUENCE ---
    // Page 3: Grid
    // Enters as Bold Text leaves (1500+)
    gridComponent.opacity = 0.0;

    // Position: Pin until 1600, then scroll up.
    // Content starts at size.y (below fold). Moving up brings it into view.
    scrollOrchestrator.addBinding(
      gridComponent,
      ParallaxScrollEffect(
        startScroll: 1600,
        endScroll: 101600, // Continuous scroll
        initialPosition: Vector2.zero(),
        endOffset: Vector2(0, -100000),
      ),
    );

    scrollOrchestrator.addBinding(
      gridComponent,
      OpacityScrollEffect(
        startScroll: 1600, // Starts after Bold Text begins exit
        endScroll: 1900,
        startOpacity: 0.0,
        endOpacity: 1.0,
      ),
    );

    // Observe Scroll for UI Opacity (Down Arrow Sync)
    scrollSystem.register(UIOpacityObserver(stateProvider: stateProvider));
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}

class UIOpacityObserver extends ScrollObserver {
  final StateProvider stateProvider;

  UIOpacityObserver({required this.stateProvider});

  @override
  void onScroll(double scrollOffset) {
    // Fades out over first 100 pixels
    final opacity = (1.0 - (scrollOffset / 100)).clamp(0.0, 1.0);
    stateProvider.updateUIOpacity(opacity);
  }
}
