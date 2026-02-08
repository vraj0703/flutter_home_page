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
import 'package:flame/input.dart';
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
import 'package:flutter_home_page/project/app/sections/experience_section.dart';
import 'package:flutter_home_page/project/app/sections/philosophy_section.dart';
import 'package:flutter_home_page/project/app/system/transition/transition_coordinator.dart';

class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks {
  VoidCallback? onStartExitAnimation;
  final Queuer queuer;
  final StateProvider stateProvider;

  MyGame({
    this.onStartExitAnimation,
    required this.queuer,
    required this.stateProvider,
  });

  // Dual Scroll Systems for independent Philosophy and Experience ranges
  final ScrollSystem _philosophyScrollSystem = ScrollSystem();
  final ScrollSystem _experienceScrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();

  // Legacy getter for compatibility
  ScrollSystem get scrollSystem => _philosophyScrollSystem;

  // Split Runners with dedicated scroll systems
  late final SequenceRunner _primarySequenceRunner = SequenceRunner(
    scrollSystem: _philosophyScrollSystem,
  );
  late final SequenceRunner _experienceSequenceRunner = SequenceRunner(
    scrollSystem: _experienceScrollSystem,
  );

  // Input blocking during flash transition
  bool _isTransitioning = false;

  final GameAudioSystem _audioSystem = GameAudioSystem();

  GameAudioSystem get audio => _audioSystem;

  SequenceRunner get primarySequenceRunner => _primarySequenceRunner;

  SequenceRunner get experienceSequenceRunner => _experienceSequenceRunner;

  ScrollSystem get experienceScrollSystem => _experienceScrollSystem;
  final GameComponentFactory _componentFactory = GameComponentFactory();
  final GameCursorSystem _cursorSystem = GameCursorSystem();
  final GameLogoAnimator logoAnimator = GameLogoAnimator();
  late final Timer _inactivityTimer;
  late final GameInputController _inputController;
  late final GameComponents _gameComponents;
  GodRayController? _godRayController;
  late final TransitionCoordinator transitionCoordinator;

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
        logoOverlay: _componentFactory.logoOverlay,
        logoComponent: _componentFactory.logoComponent,
        cinematicTitle: _componentFactory.cinematicTitle,
        cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      ),
    );

    // Initialize GameComponents helper
    _gameComponents = GameComponents(
      cinematicTitle: _componentFactory.cinematicTitle,
      cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      logoOverlay: _componentFactory.logoOverlay,
      godRay: _componentFactory.godRay,
      backgroundTint: _componentFactory.backgroundTint,
      backgroundRun: _componentFactory.backgroundRun,
      boldTextReveal: _componentFactory.boldTextReveal,
      beachBackground: _componentFactory.beachBackground,
      philosophyText: _componentFactory.philosophyText,
      philosophyTrail: _componentFactory.philosophyTrail,
      nextButton: _componentFactory.nextButton,
      rainTransition: _componentFactory.rainTransition,
      circlesBackground: _componentFactory.circlesBackground,
      experienceRotator: _componentFactory.experienceRotator,
      //skillsKeyboard: _componentFactory.skillsKeyboard,
      //testimonialPage: _componentFactory.testimonialPage,
      //contactPage: _componentFactory.contactPage,
    );

    // Initialize Global Config
    _configureGlobal();

    // Initialize Sections
    _initSequence();

    // Initialize and add Input Controller
    _inputController = GameInputController(
      queuer: queuer,
      scrollSystem: _philosophyScrollSystem,
      audioSystem: _audioSystem,
      cursorSystem: _cursorSystem,
      stateProvider: stateProvider,
    );
    add(_inputController);

    // Warm up all sections (Shaders & Textures) via Runner
    // This architecturally ensures all current and future sections are primed.
    await _primarySequenceRunner.warmUpAll();
    await _experienceSequenceRunner.warmUpAll();

    queuer.queue(event: const SceneEvent.gameReady());

    // Register controllers to philosophy scroll system
    _philosophyScrollSystem.register(scrollOrchestrator);
    _philosophyScrollSystem.register(_primarySequenceRunner);

    // Register experience scroll system
    _experienceScrollSystem.register(_experienceSequenceRunner);

    // Initialize TransitionCoordinator
    transitionCoordinator = TransitionCoordinator(this);
  }

  // Compatibility getter for components accessing godRay via game reference
  GodRayComponent get godRay => _componentFactory.godRay;

  void setCursorPosition(Vector2 position) {
    _cursorSystem.setCursorPosition(position);
  }

  Vector2 get cursorPosition => _cursorSystem.lastKnownPosition;

  // Input blocking control for flash transition
  void blockInput() => _isTransitioning = true;

  void unblockInput() => _isTransitioning = false;

  @override
  Color backgroundColor() => GameStyles.primaryBackground;

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;

    // Block input during flash transition
    if (_isTransitioning) return;

    stateProvider.sceneState().maybeWhen(
      active: (_) {
        // Route to Philosophy scroll system
        _philosophyScrollSystem.onScroll(info.scrollDelta.global.y);
      },
      loadingExperience: () {
        // Block scroll during transition
      },
      experience: (_) {
        // Route to Experience scroll system (independent range)
        _experienceScrollSystem.onScroll(info.scrollDelta.global.y);
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
    super.onMouseMove(info);
    _inputController.handleMouseMove(info);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Check State
    final state = stateProvider.sceneState();

    // Update Runner
    state.maybeWhen(
      active: (_) => _primarySequenceRunner.update(dt),
      loadingExperience: () => _primarySequenceRunner.update(dt),
      experience: (_) => _experienceSequenceRunner.update(dt),
      orElse: () {},
    );

    // Listen to Start Trigger
    state.maybeWhen(
      active: (_) => _primarySequenceRunner.start(),
      loadingExperience: () => _primarySequenceRunner.start(),
      experience: (_) => _experienceSequenceRunner.start(),
      orElse: () {},
    );

    // Base Updates
    _cursorSystem.update(
      dt,
      size,
      enableParallax: true,
    ); // Always enable parallax for consistency?

    // Update active scroll system based on state
    state.maybeWhen(
      active: (_) => _philosophyScrollSystem.update(dt),
      loadingExperience: () => _philosophyScrollSystem.update(dt),
      experience: (_) => _experienceScrollSystem.update(dt),
      orElse: () => _philosophyScrollSystem.update(dt),
    );
    _godRayController?.updatePulse(dt, _philosophyScrollSystem.scrollOffset);

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

    _primarySequenceRunner.onResize(size);
    _experienceSequenceRunner.onResize(size);

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
    try {} catch (_) {}
  }

  // Handle section progress indicator taps
  void _handleSectionTap(int section) {
    if (!isLoaded) return;
    audio.playClick();
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

  void loadBouncingLines() {
    _componentFactory.logoOverlay.opacity = 1.0;
  }

  void enterTitle() {
    Future.delayed(ScrollSequenceConfig.enterTitleDelayDuration, () {
      audio.playTitleLoaded(); // Play sound when main title starts entering
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
      backgroundRun: _gameComponents.backgroundRun,
      cinematicTitle: _gameComponents.cinematicTitle,
      cinematicSecondaryTitle: _gameComponents.cinematicSecondaryTitle,
      logoOverlay: _gameComponents.logoOverlay,
      centerPosition: size / 2,
    );
    boldSection.onComplete = () {};

    // 2. Philosophy
    final philSection = PhilosophySection(
      titleComponent: _gameComponents.philosophyText,
      cloudBackground: _gameComponents.beachBackground,
      trailComponent: _gameComponents.philosophyTrail,
      nextButton: _gameComponents.nextButton,
      rainTransition: _gameComponents.rainTransition,
      screenSize: size,
      playEntrySound: audio.playPhilosophyEntry,
      playCompletionSound: audio.playPhilosophyComplete,
    );

    // Configure components via binding-like logic (formerly addBoldTextBindings)
    _gameComponents.boldTextReveal.opacity = 0.0;
    // Philosophy text setup
    _gameComponents.philosophyText.priority = 20;
    _gameComponents.philosophyText.anchor = Anchor.center;
    _gameComponents.philosophyText.position = Vector2(size.x / 2, size.y * 0.7);
    _gameComponents.philosophyText.scale = Vector2.all(0.1);
    _gameComponents.philosophyText.opacity = 0.0;

    // 3. Experience
    final expSection = ExperienceSection(
      circlesBackground: _gameComponents.circlesBackground,
      queuer: queuer,
      screenSize: size,
    );

    _primarySequenceRunner.init([boldSection, philSection]);
    _experienceSequenceRunner.init([expSection]);

    // Wiring Handoff
    _primarySequenceRunner.onSequenceComplete = () async {
      await _primarySequenceRunner.stop();
      queuer.queue(event: const SceneEvent.enterExperience());
    };

    // Wiring Reverse Handoff (Experience -> Philosophy)
    _experienceSequenceRunner.onSequenceReverse = () async {
      await _experienceSequenceRunner.stop();
      queuer.queue(event: const SceneEvent.titleLoaded());
      await _primarySequenceRunner.resumeReverse();
    };
  }
}
