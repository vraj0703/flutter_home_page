import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/models/cursor_dependent_components.dart';
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
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/god_ray_controller.dart';
import 'package:flutter_home_page/project/app/system/input/game_input_controller.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/sequence/sequence_runner.dart';
import 'package:flutter_home_page/project/app/sections/bold_text_section.dart';
import 'package:flutter_home_page/project/app/sections/philosophy_section.dart';

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
  final SequenceRunner _sequenceRunner = SequenceRunner();

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

    // Initialize Sections
    _initSequence();

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

  void setCursorPosition(Vector2 position) {
    _cursorSystem.setCursorPosition(position);
  }

  @override
  Color backgroundColor() => GameStyles.primaryBackground;

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;

    // Check if Active, if so, bypass standard input controller for scroll
    // OR keep input controller updating scroll system, but use scroll system to drive runner?
    // Plan says: "Explicit Entry when user scrolls... transitioning to first active section"

    stateProvider.sceneState().maybeWhen(
      active: (_) {
        // Direct control to sequence runner
        // We might want to use some smoothing from InputController later,
        // but for now, raw delta or smoothed delta from ScrollSystem?
        // InputController feeds ScrollSystem. ScrollSystem has 'scrollOffset'.
        // Let's use the delta directly for 'Callback-Driven' feel without physics lag for now
        // as per "Zero Math Dependencies" goal.
        _sequenceRunner.handleScroll(info.scrollDelta.global.y);
      },
      orElse: () {
        _inputController.handleScroll(info);
      },
    );
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

    // Check State
    final state = stateProvider.sceneState();

    // Update Runner
    state.maybeWhen(active: (_) => _sequenceRunner.update(dt), orElse: () {});

    // Listen to Start Trigger
    state.maybeWhen(active: (_) => _sequenceRunner.start(), orElse: () {});

    // Base Updates
    _cursorSystem.update(
      dt,
      size,
      enableParallax: true,
    ); // Always enable parallax for consistency?
    scrollSystem.update(dt);
    _godRayController?.updatePulse(dt, scrollSystem.scrollOffset);

    // Intro State Handlers
    state.maybeWhen(
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
      orElse: () {},
    );

    _inactivityTimer.update(dt);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final center = size / 2;

    _sequenceRunner.onResize(size);

    stateProvider.sceneState().maybeWhen(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        _snapLogoToCenter(center);
        _centerTitles(center);
        _componentFactory.logoOverlay.position = center;
        _componentFactory.logoOverlay.gameSize = size;
      },
      titleLoading: () => _centerTitles(center),
      title: () => _centerTitles(center),
      orElse: () {},
    );

    // Safe check if factory initialized
    try {
      // _componentFactory.dimLayer.size = size;
      // Recenter bold text locally if needed, but onResize handled it in section
    } catch (_) {}
  }

  // Handle section progress indicator taps
  void _handleSectionTap(int section) {
    if (!isLoaded) return;
    playClick();
    // Simplified: Just log or ignored for now as absolute offsets are gone
    // Logic for jumping to section index would need SequenceRunner.jumpTo(index)
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

  void _initSequence() {
    // 1. Bold Text
    final boldSection = BoldTextSection(
      boldTextComponent: _gameComponents.boldTextReveal,
      beachBackground: _gameComponents.beachBackground,
      centerPosition: size / 2,
    );

    // 2. Philosophy
    final philSection = PhilosophySection(
      titleComponent: _gameComponents.philosophyText,
      cloudBackground: _gameComponents.beachBackground,
      trailComponent: _gameComponents.philosophyTrail,
      screenSize: size,
      playEntrySound: playPhilosophyEntry,
      playCompletionSound: playPhilosophyComplete,
    );

    // Configure components via binding-like logic (formerly addBoldTextBindings)
    _gameComponents.boldTextReveal.opacity = 0.0;
    // Philosophy text setup
    _gameComponents.philosophyText.priority = 20;
    _gameComponents.philosophyText.anchor = Anchor.center;
    _gameComponents.philosophyText.position = Vector2(size.x / 2, size.y * 0.7);
    _gameComponents.philosophyText.scale = Vector2.all(0.1);
    _gameComponents.philosophyText.opacity = 0.0;

    _sequenceRunner.init([boldSection, philSection]);
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
