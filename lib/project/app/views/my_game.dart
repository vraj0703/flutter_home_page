import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/models/game_components.dart';
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
import 'package:flutter_home_page/project/app/system/scroll/game_scroll_configurator.dart';
import 'package:flutter_home_page/project/app/system/input/game_input_controller.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart'; // Added import

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

  late final Timer _inactivityTimer;
  late final GameInputController _inputController;

  final ScrollSystem scrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();
  final GameAudioSystem _audioSystem = GameAudioSystem(); // Added instance

  final GameComponentFactory _componentFactory = GameComponentFactory();
  final GameScrollConfigurator _scrollConfigurator = GameScrollConfigurator();
  final GameCursorSystem _cursorSystem = GameCursorSystem();
  final GameLogoAnimator _logoAnimator = GameLogoAnimator();

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

    _logoAnimator.initialize(
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

  // Audio Helpers
  void playEnterSound() => _audioSystem.playEnterSound();

  void playTitleLoaded() => _audioSystem.playTitleLoaded();

  void playSlideIn() => _audioSystem.playSlideIn();

  void playBouncyArrow() => _audioSystem.playBouncyArrow();

  void syncBoldTextAudio(double progress, {double velocity = 0.0}) =>
      _audioSystem.syncBoldTextAudio(progress, velocity: velocity);

  void stopBoldTextAudio() => _audioSystem.stopBoldTextAudio();

  void playTing() => _audioSystem.playTing();

  void playHover() => _audioSystem.playHover();

  void playClick() => _audioSystem.playClick();

  // Compatibility getter for components accessing godRay via game reference
  GodRayComponent get godRay => _componentFactory.godRay;

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
  }

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

  void loadTitleBackground() {
    _componentFactory.backgroundRun.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: GameCurves.backgroundFade),
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
        center + GameLayout.secTitleOffsetVector;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Delegate updates
    final isMenu = stateProvider.sceneState().maybeWhen(
      menu: (_) => true,
      title: () => true,
      orElse: () => false,
    );

    _cursorSystem.update(dt, size, enableParallax: isMenu);

    _logoAnimator.update(
      dt,
      LogoAnimationComponents(
        logoComponent: _componentFactory.logoComponent,
        shadowScene: _componentFactory.shadowScene,
      ),
    );

    scrollSystem.update(dt);

    // Update god ray pulse animation
    final godRayController = _scrollConfigurator.godRayController;
    if (godRayController != null) {
      godRayController.updatePulse(dt, scrollSystem.scrollOffset);
    }

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
        _logoAnimator.setTarget(
          position: GameLayout.logoRemovingTargetVector,
          scale: GameLayout.logoRemovingScale,
        );
      },
      titleLoading: () {},
      title: () {},
      menu: (uiOpacity) {
        // Logo animation target is handled in onGameResize or EnterMenu,
        // but update calls animate implicitly via _logoAnimator.update

        // --- 1. Arrow/UI Fade Logic ---
        // Fade out arrow immediately on scroll (0 -> 150px)
        final scroll = scrollSystem.scrollOffset;
        final newOpacity = (1.0 - (scroll / 150.0)).clamp(0.0, 1.0);

        // Only update if changed significantly to avoid Bloc spam
        if ((newOpacity - uiOpacity).abs() > 0.05 ||
            (newOpacity == 0 && uiOpacity != 0)) {
          queuer.queue(event: SceneEvent.updateUIOpacity(newOpacity));
        }

        // --- 2. Title Parallax Lift ---
        // Move titles up as we scroll down (Scroll P1: 0 -> 1200)
        // They should clear the screen relatively quickly
        if (scroll < ScrollSequenceConfig.boldTextPass1End) {
          final lift = scroll * 1.5; // Move 1.5x faster than scroll
          _componentFactory.cinematicTitle.position.y -= lift;
          _componentFactory.cinematicSecondaryTitle.position.y -= lift;
        }
      },
    );
    _inactivityTimer.update(dt);
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

  void enterMenu() {
    _logoAnimator.updateMenuLayoutTargets(size);
    _cursorSystem.activate(size / 2);

    // Delegate to ScrollConfigurator
    _scrollConfigurator.configureScroll(
      scrollOrchestrator: scrollOrchestrator,
      scrollSystem: scrollSystem,
      screenSize: size,
      stateProvider: stateProvider,
      components: GameComponents(
        cinematicTitle: _componentFactory.cinematicTitle,
        cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
        interactiveUI: _componentFactory.logoOverlay,
        dimLayer: _componentFactory.dimLayer,
        godRay: _componentFactory.godRay,
        backgroundTint: _componentFactory.backgroundTint,
        boldTextReveal: _componentFactory.boldTextReveal,
        philosophyText: _componentFactory.philosophyText,
        cardStack: _componentFactory.cardStack,
        workExperienceTitle: _componentFactory.workExperienceTitle,
        experiencePage: _componentFactory.experiencePage,
        testimonialPage: _componentFactory.testimonialPage,
        contactPage: _componentFactory.contactPage,
      ),
    );
  }

  void setCursorPosition(Vector2 position) {
    _cursorSystem.setCursorPosition(position);
  }
}
