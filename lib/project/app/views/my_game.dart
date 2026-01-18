import 'package:flutter_home_page/project/app/models/game_components.dart';

import 'components/god_ray.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/game_logo_animator.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/game_component_factory.dart';
import 'package:flutter_home_page/project/app/system/game_scroll_configurator.dart';

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

  late final Timer _inactivityTimer;
  static const double inactivityTimeout = 5.0;
  static const double uiFadeDuration = 0.5;

  final ScrollSystem scrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();

  final GameComponentFactory _componentFactory = GameComponentFactory();
  final GameScrollConfigurator _scrollConfigurator = GameScrollConfigurator();
  final GameCursorSystem _cursorSystem = GameCursorSystem();
  final GameLogoAnimator _logoAnimator = GameLogoAnimator();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _inactivityTimer = Timer(inactivityTimeout, onTick: () {}, repeat: false);
    _cursorSystem.initialize(size / 2);

    await _componentFactory.initializeComponents(
      size: size,
      stateProvider: stateProvider,
      queuer: queuer,
      scrollOrchestrator: scrollOrchestrator,
      backgroundColorCallback: backgroundColor,
    );

    // Add all components to scene
    for (final component in _componentFactory.allComponents) {
      add(component);
    }

    _logoAnimator.initialize(
      _componentFactory.logoComponent.size / 3.0,
      _componentFactory.logoComponent.position,
    );

    queuer.queue(event: const SceneEvent.gameReady());
    scrollSystem.register(scrollOrchestrator);
  }

  // Compatibility getter for components accessing godRay via game reference
  GodRayComponent get godRay => _componentFactory.godRay;

  @override
  Color backgroundColor() => const Color(0xFFC78E53);

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;
    queuer.queue(event: const SceneEvent.onScroll());

    final delta = info.scrollDelta.global.y;
    scrollSystem.onScroll(delta);

    stateProvider.sceneState().maybeWhen(
      menu: (uiOpacity) {
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
    _componentFactory.backgroundRun.add(
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
        _snapLogoToCenter(center);
        _centerTitles(center);
        _componentFactory.interactiveUI.position = center;
        _componentFactory.interactiveUI.gameSize = size;
      },
      logoOverlayRemoving: () {},
      titleLoading: () {
        _centerTitles(center);
      },
      title: () {
        _centerTitles(center);
      },
      menu: (uiOpacity) {
        _logoAnimator.updateMenuLayoutTargets(size);
      },
    );
    // Safe check if factory initialized
    try {
      _componentFactory.dimLayer.size = size;
      _componentFactory.boldTextReveal.position = center;
    } catch (_) {
      // Components might not be loaded yet during initial resize
    }
  }

  void _snapLogoToCenter(Vector2 center) {
    _componentFactory.logoComponent.position = center;
    _componentFactory.shadowScene.logoPosition = center;
  }

  void _centerTitles(Vector2 center) {
    _componentFactory.cinematicTitle.position = center;
    _componentFactory.cinematicSecondaryTitle.position =
        center + Vector2(0, 48);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Delegate updates
    _cursorSystem.update(
      dt,
      size,
      CursorDependentComponents(
        godRay: _componentFactory.godRay,
        shadowScene: _componentFactory.shadowScene,
        interactiveUI: _componentFactory.interactiveUI,
        logoComponent: _componentFactory.logoComponent,
      ),
    );

    _logoAnimator.update(
      dt,
      LogoAnimationComponents(
        logoComponent: _componentFactory.logoComponent,
        shadowScene: _componentFactory.shadowScene,
      ),
    );

    scrollSystem.updateSnap(dt);

    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {
        _centerTitles(size / 2);
        _componentFactory.interactiveUI.inactivityOpacity +=
            dt / uiFadeDuration;
      },
      logo: () {
        _componentFactory.cinematicTitle.position = size / 2;
      },
      logoOverlayRemoving: () {
        _logoAnimator.setTarget(position: Vector2(36, 36), scale: 0.3);
      },
      titleLoading: () {},
      title: () {},
      menu: (uiOpacity) {
        _cursorSystem.initialize(size / 2);
        // Logo animation target is handled in onGameResize or EnterMenu,
        // but update calls animate implicitly via _logoAnimator.update
      },
    );
    _inactivityTimer.update(dt);
  }

  void enterTitle() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _componentFactory.cinematicTitle.show(
        () => _componentFactory.cinematicSecondaryTitle.show(
          () => queuer.queue(event: SceneEvent.titleLoaded()),
        ),
      ),
    );
  }

  void enterMenu() {
    _logoAnimator.updateMenuLayoutTargets(size);

    // Delegate to ScrollConfigurator
    _scrollConfigurator.configureScroll(
      scrollOrchestrator: scrollOrchestrator,
      scrollSystem: scrollSystem,
      screenSize: size,
      stateProvider: stateProvider,
      components: GameComponents(
        cinematicTitle: _componentFactory.cinematicTitle,
        cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
        interactiveUI: _componentFactory.interactiveUI,
        dimLayer: _componentFactory.dimLayer,
        boldTextReveal: _componentFactory.boldTextReveal,
        philosophyText: _componentFactory.philosophyText,
        cardStack: _componentFactory.cardStack,
        experiencePage: _componentFactory.experiencePage,
        testimonialPage: _componentFactory.testimonialPage,
        skillsPage: _componentFactory.skillsPage,
        contactPage: _componentFactory.contactPage,
      ),
    );
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _cursorSystem.onPointerMove(event);
  }
}
