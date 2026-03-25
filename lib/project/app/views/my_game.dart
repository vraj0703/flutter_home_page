import 'dart:async';
import 'dart:ui';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/models/cursor_dependent_components.dart';

import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_bloc/flame_bloc.dart';

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

  final ScrollSystem _philosophyScrollSystem = ScrollSystem();

  ScrollSystem get scrollSystem => _philosophyScrollSystem;

  late final SequenceRunner _primarySequenceRunner = SequenceRunner(
    scrollSystem: _philosophyScrollSystem,
  );
  bool _isTransitioning = false;

  final GameAudioSystem _audioSystem = GameAudioSystem();

  GameAudioSystem get audio => _audioSystem;

  SequenceRunner get primarySequenceRunner => _primarySequenceRunner;

  final GameComponentFactory _componentFactory = GameComponentFactory();

  // Component Accessors (Decoupled Lookup)
  ExperienceSection get experienceSection =>
      _primarySequenceRunner.sections.whereType<ExperienceSection>().first;

  PhilosophySection get philosophySection =>
      _primarySequenceRunner.sections.whereType<PhilosophySection>().first;
  final GameCursorSystem _cursorSystem = GameCursorSystem();

  GameCursorSystem get cursorSystem => _cursorSystem;
  final GameLogoAnimator logoAnimator = GameLogoAnimator();
  late final Timer _inactivityTimer;
  late final GameInputController _inputController;

  GodRayController? _godRayController;
  late final TransitionCoordinator transitionCoordinator;

  late final FlameBlocProvider<SceneBloc, SceneState> _blocProvider;

  StreamSubscription? _stateSubscription;
  bool _warmupComplete = false;
  bool _gameReadyDispatched = false;

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
      backgroundColorCallback: backgroundColor,
      onSectionTap: _handleSectionTap,
    );

    // Create and store FlameBlocProvider
    _blocProvider = FlameBlocProvider<SceneBloc, SceneState>.value(
      value: stateProvider as SceneBloc,
      children: _componentFactory.allComponents,
    );

    await add(_blocProvider);

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

    _primarySequenceRunner.warmUpAll().whenComplete(() {
      _warmupComplete = true;
    });

    // Explicitly warm up components not managed by the sequence runner's warmUp
    _componentFactory.rainTransition.warmUp();
    _componentFactory.circlesBackground.warmUp();

    // Register controllers to philosophy scroll system
    _philosophyScrollSystem.register(_primarySequenceRunner);

    // Initialize TransitionCoordinator
    transitionCoordinator = TransitionCoordinator(this);

    // Pre-warm Flash Shader
    await _loadFlashShader();

    // State Listener for One-Shot Events (State Purity)
    _stateSubscription = stateProvider.stream.listen((state) {
      state.maybeWhen(
        loadingExperience: () => hideTitles(),
        experience: (_) => hideTitles(),
        orElse: () {},
      );
    });
  }

  late final FragmentShader flashShader;

  Future<void> _loadFlashShader() async {
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/flash_transition.frag',
    );
    flashShader = program.fragmentShader();
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
    if (_isTransitioning) return; // Block ALL scroll during transitions

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
    super.onMouseMove(info);
    _inputController.handleMouseMove(info);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Check State
    final state = stateProvider.sceneState();

    _godRayController?.updatePulse(dt);

    // Update Runner
    state.maybeWhen(
      active: (_, __) {
        _philosophyScrollSystem.update(dt);
        _primarySequenceRunner.update(dt);
      },
      loadingExperience: () {
        _philosophyScrollSystem.update(dt);
        _primarySequenceRunner.update(dt);
      },
      orElse: () {},
    );

    // Base Updates
    _cursorSystem.update(
      dt,
      size,
      enableParallax: true,
    ); // Always enable parallax for consistency?

    // Intro State Handlers
    state.maybeWhen(
      loading: (isSvgReady, isGameReady) {
        _componentFactory.logoOverlay.inactivityOpacity +=
            dt / ScrollSequenceConfig.uiFadeDuration;

        // Drive the sequence runner to allow components to tick (if needed)
        _primarySequenceRunner.update(dt);

        // Dispatch Game Ready only when warmup is fully complete
        if (_warmupComplete && !_gameReadyDispatched) {
          _gameReadyDispatched = true;
          queuer.queue(event: const SceneEvent.gameReady());
        }
      },
      logoOverlayRemoving: () {
        final isDone = logoAnimator.update(
          dt,
          LogoAnimationComponents(
            logoComponent: _componentFactory.logoComponent,
            shadowScene: _componentFactory.shadowScene,
          ),
        );

        if (isDone) {
          queuer.queue(event: const SceneEvent.loadTitle());
        }
      },
      orElse: () {},
    );

    _inactivityTimer.update(dt);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _primarySequenceRunner.onResize(size);
    if (!isLoaded) return;
    _snapLogoToCenter(size);
    _centerTitles(size);
  }

  void _snapLogoToCenter(Vector2 gameSize) {
    stateProvider.sceneState().maybeWhen(
      loading: (_, __) {
        _componentFactory.logoComponent.position = gameSize / 2;
        _componentFactory.shadowScene.logoPosition = gameSize / 2;
        _componentFactory.logoOverlay.position = gameSize / 2;
      },
      logo: () {
        _componentFactory.logoComponent.position = gameSize / 2;
        _componentFactory.shadowScene.logoPosition = gameSize / 2;
        _componentFactory.logoOverlay.position = gameSize / 2;
      },
      orElse: () {},
    );
  }

  void _centerTitles(Vector2 gameSize) {
    stateProvider.sceneState().maybeWhen(
      logoOverlayRemoving: () {
        _componentFactory.cinematicTitle.position = gameSize / 2;
        _componentFactory.cinematicSecondaryTitle.position =
            gameSize / 2 + GameLayout.secTitleOffsetVector;
      },
      titleLoading: () {
        _componentFactory.cinematicTitle.position = gameSize / 2;
        _componentFactory.cinematicSecondaryTitle.position =
            gameSize / 2 + GameLayout.secTitleOffsetVector;
      },
      title: () {
        _componentFactory.cinematicTitle.position = gameSize / 2;
        _componentFactory.cinematicSecondaryTitle.position =
            gameSize / 2 + GameLayout.secTitleOffsetVector;
      },
      orElse: () {},
    );
  }

  // Handle section progress indicator taps
  void _handleSectionTap(int section) {
    if (!isLoaded) return;
    audio.playClick();
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

  /// One-shot: sets the logo animator target for the logo→title shrink.
  /// Called by StatefulScene.listener on logoOverlayRemoving entry.
  void startLogoRemoval() {
    logoAnimator.setTarget(
      position: GameLayout.logoRemovingTargetVector,
      scale: GameLayout.logoRemovingScale,
    );
  }

  void  enterTitle() {
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

  /// Hides the cinematic title and secondary title components.
  /// Called when transitioning away from the Title/BoldText states
  /// to ensure they don't bleed into Philosophy or Experience sections.
  void hideTitles() {
    _componentFactory.cinematicTitle.opacity = 0.0;
    _componentFactory.cinematicTitle.hide();
    _componentFactory.cinematicSecondaryTitle.opacity = 0.0;
  }

  void _configureGlobal() {
    _godRayController = GodRayController(
      component: _componentFactory.godRay,
      screenSize: size,
    );
    scrollSystem.register(_godRayController!);
  }

  void _initSequence() {
    // 1. Bold Text
    final boldSection = BoldTextSection(
      boldTextComponent: _componentFactory.boldTextReveal,
      backgroundRun: _componentFactory.backgroundRun,
      cinematicTitle: _componentFactory.cinematicTitle,
      cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      logoOverlay: _componentFactory.logoOverlay,
      centerPosition: size / 2,
    );
    boldSection.onComplete = () {};

    // 2. Philosophy
    final philosophySection = PhilosophySection(
      titleComponent: _componentFactory.philosophyText,
      cloudBackground: _componentFactory.beachBackground,
      trailComponent: _componentFactory.philosophyTrail,
      nextButton: _componentFactory.nextButton,
      rainTransition: _componentFactory.rainTransition,
      whiteOverlay: _componentFactory.whiteOverlay,
      screenSize: size,
      playEntrySound: audio.playPhilosophyEntry,
      playCompletionSound: audio.playPhilosophyComplete,
    );

    // Configure components via binding-like logic (formerly addBoldTextBindings)
    _componentFactory.boldTextReveal.opacity = 0.0;
    // Philosophy text setup
    _componentFactory.philosophyText.priority = 20;
    _componentFactory.philosophyText.anchor = Anchor.center;
    _componentFactory.philosophyText.position = Vector2(
      size.x / 2,
      size.y * GameLayout.philosophyTextYRatio,
    );
    _componentFactory.philosophyText.scale = Vector2.all(
      GameLayout.philosophyTextScale,
    );
    _componentFactory.philosophyText.opacity = 0.0;

    // 3. Experience
    final experienceSection = ExperienceSection(
      circlesBackground: _componentFactory.circlesBackground,
      queuer: queuer,
      screenSize: size,
    );
    _blocProvider.add(experienceSection);

    _primarySequenceRunner.init([
      boldSection,
      philosophySection,
      experienceSection,
    ]);

    // Wiring Handoff
    _primarySequenceRunner.onSequenceComplete = () async {
      await _primarySequenceRunner.stop();
      queuer.queue(event: const SceneEvent.enterExperience());
    };
  }

  @override
  void onRemove() {
    _stateSubscription?.cancel();
    super.onRemove();
  }
}
