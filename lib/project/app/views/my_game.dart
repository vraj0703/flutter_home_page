import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/models/cursor_dependent_components.dart';
import 'package:flutter_home_page/project/app/models/game_components.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_effects/opacity.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_effects/parallax.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/cursor/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/animator/game_logo_animator.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/registration/game_component_factory.dart';
import 'package:flutter_home_page/project/app/system/scroll/managers/bold_text_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/managers/philosophy_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/god_ray_controller.dart';
import 'package:flutter_home_page/project/app/system/input/game_input_controller.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';

class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector {
  VoidCallback? onStartExitAnimation;
  final Queuer queuer;
  final StateProvider stateProvider;

  MyGame({
    this.onStartExitAnimation,
    required this.queuer,
    required this.stateProvider,
  });

  final ScrollSystem scrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();
  final GameAudioSystem _audioSystem = GameAudioSystem();
  final GameComponentFactory _componentFactory = GameComponentFactory();
  final GameCursorSystem _cursorSystem = GameCursorSystem();
  final GameLogoAnimator logoAnimator = GameLogoAnimator();
  late final Timer _inactivityTimer;
  late final GameInputController _inputController;
  late final GameComponents _gameComponents;
  GodRayController? _godRayController;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _inactivityTimer = Timer(
      ScrollSequenceConfig.inactivityTimeout,
      onTick: () {},
      repeat: false,
    );
    _cursorSystem.initialize(size / 2);
    await _audioSystem.initialize(); // Initialize audio

    await _componentFactory.initializeComponents(
      size: size,
      stateProvider: stateProvider,
      queuer: queuer,
      scrollOrchestrator: scrollOrchestrator,
      backgroundColorCallback: backgroundColor,
      onSectionTap: _handleSectionTap,
    );

    // Add all components to scene
    for (final component in _componentFactory.allComponents) {
      add(component);
    }

    logoAnimator.initialize(
      _componentFactory.logoComponent.size / 3.0,
      _componentFactory.logoComponent.position,
    );

    // Bind cursor components once
    _cursorSystem.bindComponents(
      CursorDependentComponents(
        godRay: _componentFactory.godRay,
        shadowScene: _componentFactory.shadowScene,
        interactiveUI: _componentFactory.logoOverlay,
        logoComponent: _componentFactory.logoComponent,
        cinematicTitle: _componentFactory.cinematicTitle,
        cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      ),
    );

    // Initialize GameComponents helper
    _gameComponents = GameComponents(
      cinematicTitle: _componentFactory.cinematicTitle,
      cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      interactiveUI: _componentFactory.logoOverlay,
      godRay: _componentFactory.godRay,
      backgroundTint: _componentFactory.backgroundTint,
      boldTextReveal: _componentFactory.boldTextReveal,
      beachBackground: _componentFactory.beachBackground,
      philosophyText: _componentFactory.philosophyText,
      philosophyTrail: _componentFactory.philosophyTrail,
    );

    // Initialize Global Config
    _configureGlobal();

    // Initialize Section Managers
    _initializeSections();

    // Initialize and add Input Controller
    _inputController = GameInputController(
      queuer: queuer,
      scrollSystem: scrollSystem,
      audioSystem: _audioSystem,
      cursorSystem: _cursorSystem,
      stateProvider: stateProvider,
    );
    add(_inputController);

    queuer.queue(event: const SceneEvent.gameReady());
    scrollSystem.register(scrollOrchestrator);
  }

  // Compatibility getter for components accessing godRay via game reference
  GodRayComponent get godRay => _componentFactory.godRay;

  @override
  Color backgroundColor() => GameStyles.primaryBackground;

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;
    _inputController.handleScroll(info);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _inputController.handleTapDown(event);
    super.onTapDown(event);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _inputController.handlePointerMove(event);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _inputController.handleMouseMove(info);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Delegate updates
    final isMenu = stateProvider.sceneState().maybeWhen(
      boldText: (_, _) => true,
      philosophy: (_) => true,
      workExperience: (_) => true,
      experience: (_) => true,
      testimonials: (_) => true,
      contact: (_) => true,
      title: () => true,
      orElse: () => false,
    );

    _cursorSystem.update(dt, size, enableParallax: isMenu);
    scrollSystem.update(dt);
    _godRayController?.updatePulse(dt, scrollSystem.scrollOffset);

    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {
        _centerTitles(size / 2);
        _componentFactory.logoOverlay.inactivityOpacity +=
            dt / ScrollSequenceConfig.uiFadeDuration;
      },
      logo: () {
        _componentFactory.cinematicTitle.position = size / 2;
      },
      logoOverlayRemoving: () {
        logoAnimator.setTarget(
          position: GameLayout.logoRemovingTargetVector,
          scale: GameLayout.logoRemovingScale,
        );
        logoAnimator.update(
          dt,
          LogoAnimationComponents(
            logoComponent: _componentFactory.logoComponent,
            shadowScene: _componentFactory.shadowScene,
          ),
        );
      },
      titleLoading: () {},
      title: () {},
      boldText: (_, uiOpacity) => _handleBoldTextUpdate(uiOpacity),
      philosophy: (_) {},
      workExperience: (_) {},
      experience: (_) {},
      testimonials: (_) {},
      contact: (_) {},
    );
    _inactivityTimer.update(dt);
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
        _componentFactory.logoOverlay.position = center;
        _componentFactory.logoOverlay.gameSize = size;
      },
      logoOverlayRemoving: () {},
      titleLoading: () {
        _centerTitles(center);
      },
      title: () {
        _centerTitles(center);
      },
      boldText: (_, uiOpacity) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
      philosophy: (_) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
      workExperience: (_) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
      experience: (_) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
      testimonials: (_) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
      contact: (_) {
        logoAnimator.updateMenuLayoutTargets(size);
      },
    );
    // Safe check if factory initialized
    try {
      // _componentFactory.dimLayer.size = size;
      _componentFactory.boldTextReveal.position = center;
    } catch (_) {
      // Components might not be loaded yet during initial resize
    }
  }

  // Handle section progress indicator taps
  void _handleSectionTap(int section) {
    if (!isLoaded) return;
    if (section < 0 ||
        section >= ScrollSequenceConfig.sectionJumpTargets.length) {
      return;
    }

    // We can use the controller for the click sound if we want, or keep it here.
    // Since this is a UI callback from Factory, it's slightly different from a Game generic tap.
    // But we should probably use the audio system directly.
    playClick();

    final targetScroll = ScrollSequenceConfig.sectionJumpTargets[section];
    scrollSystem.setScrollOffset(targetScroll);
    // Sync Bloc State
    queuer.queue(event: SceneEvent.forceScrollOffset(targetScroll));
  }

  void _snapLogoToCenter(Vector2 center) {
    _componentFactory.logoComponent.position = center;
    _componentFactory.shadowScene.logoPosition = center;
  }

  void _centerTitles(Vector2 center) {
    _componentFactory.cinematicTitle.position = center;
    _componentFactory.cinematicSecondaryTitle.position =
        center + GameLayout.secTitleOffsetVector;
  }

  void loadTitleBackground() {
    _componentFactory.backgroundRun.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: GameCurves.backgroundFade),
      ),
    );
  }

  void enterTitle() {
    Future.delayed(ScrollSequenceConfig.enterTitleDelayDuration, () {
      playTitleLoaded(); // Play sound when main title starts entering
      _componentFactory.cinematicTitle.show(() {
        _componentFactory.cinematicSecondaryTitle.show(
          () => queuer.queue(event: SceneEvent.titleLoaded()),
        );
      });
    });
  }

  void activateTitleCursorSystem() {
    _cursorSystem.activate(size / 2);
  }

  void _configureGlobal() {
    _godRayController = GodRayController(
      component: _gameComponents.godRay,
      screenSize: size,
    );
    scrollSystem.register(_godRayController!);
  }

  void _initializeSections() {
    // Bold text section
    final boldTextController = BoldTextController(
      component: _gameComponents.boldTextReveal,
      screenWidth: size.x,
      centerPosition: size / 2,
    );

    final boldManager = BoldTextManager(
      controller: boldTextController,
      beachBackground: _gameComponents.beachBackground,
    );

    // philosophy section
    final philosophyTitle = _gameComponents.philosophyText;
    philosophyTitle.priority = 20;
    philosophyTitle.anchor = Anchor.center;
    philosophyTitle.position = Vector2(size.x / 2, size.y * 0.7); // Start below
    philosophyTitle.scale = Vector2.all(0.1); // Start small
    philosophyTitle.opacity = 0.0;

    final philosophyController = PhilosophyPageController(
      titleComponent: philosophyTitle,
      cloudBackground: _gameComponents.beachBackground,
      trailComponent: _gameComponents.philosophyTrail,
      // Added
      screenSize: size,
      onComplete: playPhilosophyComplete,
    );

    final philManager = PhilosophyManager(
      controller: philosophyController,
      playSound: playPhilosophyEntry,
    );

    // 3. Register with Bloc
    queuer.queue(
      event: SceneEvent.registerSections([boldManager, philManager]),
    );
  }

  void addPhilosophyBindings() {
    _gameComponents.boldTextReveal.opacity = 0.0;
    _gameComponents.philosophyText.opacity = 1.0;
    _gameComponents.philosophyTrail.opacity = 1.0;
    _gameComponents.beachBackground.opacity = 1.0;
  }

  void addBoldTextBindings() {
    _gameComponents.boldTextReveal.opacity = 1;
    _gameComponents.cinematicTitle.position = size / 2;
    _gameComponents.cinematicTitle.scale = Vector2.all(1.0);
    _gameComponents.cinematicSecondaryTitle.position =
        size / 2 + GameLayout.secTitleOffsetVector;

    scrollOrchestrator.addBinding(
      _gameComponents.cinematicTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.titleParallaxEnd,
        initialPosition: _gameComponents.cinematicTitle.position.clone(),
        endOffset: GameLayout.parallaxEndVector,
        curve: GameCurves.defaultSpring,
      ),
    );

    scrollOrchestrator.addBinding(
      _gameComponents.cinematicSecondaryTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.secondaryTitleParallaxEnd,
        initialPosition: _gameComponents.cinematicSecondaryTitle.position
            .clone(),
        endOffset: GameLayout.parallaxEndVector,
        curve: GameCurves.logoSpring,
      ),
    );

    // Fade Effects
    scrollOrchestrator.addBinding(
      _gameComponents.cinematicTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.titleFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      _gameComponents.cinematicSecondaryTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.secondaryTitleFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      _gameComponents.interactiveUI,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.uiFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );
  }

  void setCursorPosition(Vector2 position) {
    _cursorSystem.setCursorPosition(position);
  }

  void _handleBoldTextUpdate(double uiOpacity) {
    final scroll = scrollSystem.scrollOffset;
    final newOpacity = (1.0 - (scroll / 150.0)).clamp(0.0, 1.0);

    if ((newOpacity - uiOpacity).abs() > 0.05 ||
        (newOpacity == 0 && uiOpacity != 0)) {
      queuer.queue(event: SceneEvent.updateUIOpacity(newOpacity));
    }
  }

  // Audio Helpers
  void playEnterSound() => _audioSystem.playEnterSound();

  void playTitleLoaded() => _audioSystem.playTitleLoaded();

  void playSlideIn() => _audioSystem.playSlideIn();

  void playBouncyArrow() => _audioSystem.playBouncyArrow();

  void playPhilosophyEntry() => _audioSystem.playPhilosophyEntry();

  void playPhilosophyComplete() => _audioSystem.playPhilosophyComplete();

  void syncBoldTextAudio(double progress, {double velocity = 0.0}) =>
      _audioSystem.syncBoldTextAudio(progress, velocity: velocity);

  void stopBoldTextAudio() => _audioSystem.stopBoldTextAudio();

  void playTing() => _audioSystem.playTing();

  void playHover() => _audioSystem.playHover();

  void playClick() => _audioSystem.playClick();

  void playTrailCardSound(int index) => _audioSystem.playTrailCardSound(index);
}
