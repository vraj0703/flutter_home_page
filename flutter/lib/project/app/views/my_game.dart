import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/models/cursor_dependent_components.dart';

import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_bloc/flame_bloc.dart';

import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/transition_context.dart';
import 'package:flutter_home_page/project/app/system/cursor/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/animator/game_logo_animator.dart';
import 'package:flutter_home_page/project/app/system/intro/intro_flow_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/registration/game_component_factory.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/god_ray_controller.dart';
import 'package:flutter_home_page/project/app/system/input/game_input_controller.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/sequence/sequence_runner.dart';
import 'package:flutter_home_page/project/app/sections/bold_text_section.dart';
import 'package:flutter_home_page/project/app/sections/philosophy_section.dart';
import 'package:flutter_home_page/project/app/system/transition/transition_coordinator.dart';

class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks
    implements TransitionContext {
  VoidCallback? onStartExitAnimation;
  bool _handoffSent = false;
  @override
  final Queuer queuer;
  final StateProvider stateProvider;
  final SceneBloc _bloc;

  MyGame({
    this.onStartExitAnimation,
    required SceneBloc bloc,
  })  : _bloc = bloc,
        queuer = bloc,
        stateProvider = bloc;

  final ScrollSystem _philosophyScrollSystem = ScrollSystem();

  ScrollSystem get scrollSystem => _philosophyScrollSystem;

  late final SequenceRunner _primarySequenceRunner = SequenceRunner(
    scrollSystem: _philosophyScrollSystem,
  );
  bool _isTransitioning = false;

  final GameAudioSystem _audioSystem = GameAudioSystem();

  @override
  GameAudioSystem get audio => _audioSystem;

  @override
  SequenceRunner get primarySequenceRunner => _primarySequenceRunner;

  final GameComponentFactory _componentFactory = GameComponentFactory();

  final GameCursorSystem _cursorSystem = GameCursorSystem();

  GameCursorSystem get cursorSystem => _cursorSystem;

  /// Notifier for showing/hiding the testimonial form overlay.
  /// Flame components set this to `true`; the Flutter overlay reads it.
  final ValueNotifier<bool> showTestimonialForm = ValueNotifier<bool>(false);

  final GameLogoAnimator logoAnimator = GameLogoAnimator();
  late final Timer _inactivityTimer;
  late final GameInputController _inputController;

  GodRayController? _godRayController;
  late final TransitionCoordinator transitionCoordinator;
  late final IntroFlowController introFlow;

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

    // Create and store FlameBlocProvider — uses the concrete SceneBloc directly
    // instead of casting from StateProvider, eliminating the unsafe runtime cast.
    _blocProvider = FlameBlocProvider<SceneBloc, SceneState>.value(
      value: _bloc,
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

    // Initialize Intro Flow Controller (manages logo → title → active transitions)
    introFlow = IntroFlowController(
      logoOverlay: _componentFactory.logoOverlay,
      cinematicTitle: _componentFactory.cinematicTitle,
      cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      backgroundRun: _componentFactory.backgroundRun,
      audioSystem: _audioSystem,
      cursorSystem: _cursorSystem,
      logoAnimator: logoAnimator,
      queuer: queuer,
      game: this,
    );

    // Initialize Global Config
    _configureGlobal();

    // Initialize TransitionCoordinator (before _initSequence, which injects it into sections)
    transitionCoordinator = TransitionCoordinator(this);

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

    // Listen for React messages (goto-philosophy)
    if (kIsWeb) {
      web.window.addEventListener(
        'message',
        (web.Event event) {
          final msgEvent = event as web.MessageEvent;
          final data = msgEvent.data;
          if (data == null) return;
          final dartData = data.dartify();
          if (dartData is Map && dartData['type'] == 'goto-philosophy') {
            debugPrint('[Flutter] Received goto-philosophy');
            _handoffSent = false; // Allow future handoffs
            _startPhilosophySection();
          }
        }.toJS,
      );
    }

    // Explicitly warm up components not managed by the sequence runner's warmUp
    _componentFactory.rainTransition.warmUp();
    _componentFactory.circlesBackground.warmUp();

    // Register controllers to philosophy scroll system
    _philosophyScrollSystem.register(_primarySequenceRunner);

    // Pre-warm Flash Shader
    await _loadFlashShader();

    // State Listener for One-Shot Events (State Purity)
    _stateSubscription = stateProvider.stream.listen((state) {
      state.maybeWhen(
        loadingExperience: () => introFlow.hideTitles(),
        experience: (_) => introFlow.hideTitles(),
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
  @override
  void blockInput() => _isTransitioning = true;

  @override
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

    // Handoff is now triggered by philosophy button hold complete
    // (see philosophy_section.dart onHoldComplete callback)

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

  /// The latest testimonial nodes from the BLoC (Firestore).
  /// [TestimonialPageComponent] reads this via `game.testimonialNodes` to
  /// populate the carousel. Falls back to the hardcoded [testimonialData]
  /// when `null`.
  List<TestimonialNode>? get testimonialNodes => _pendingTestimonialData;

  /// Update the testimonial carousel with fresh data from the BLoC.
  ///
  /// Called from [StatefulScene] when [TestimonialLoaded] fires.
  /// Stores the data so any [TestimonialPageComponent] can access it,
  /// and notifies already-loaded carousel components if they exist.
  void updateTestimonials(List<TestimonialNode> data) {
    _pendingTestimonialData = data;

    // If a TestimonialPageComponent is already in the tree, push data now.
    final sections = _primarySequenceRunner.sections;
    for (final section in sections) {
      if (section is TestimonialSection) {
        section.pageComponent.updateData(data);
        break;
      }
    }
  }

  void _configureGlobal() {
    _godRayController = GodRayController(
      component: _componentFactory.godRay,
      screenSize: size,
    );
    scrollSystem.register(_godRayController!);
  }

  late PhilosophySection _philosophySection;

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
    // 2. Philosophy (stored as field for later goto-philosophy)
    _philosophySection = PhilosophySection(
      titleComponent: _componentFactory.philosophyText,
      cloudBackground: _componentFactory.beachBackground,
      trailComponent: _componentFactory.philosophyTrail,
      nextButton: _componentFactory.nextButton,
      backButton: _componentFactory.backButton,
      rainTransition: _componentFactory.rainTransition,
      whiteOverlay: _componentFactory.whiteOverlay,
      screenSize: size,
      playEntrySound: audio.playPhilosophyEntry,
      playCompletionSound: audio.playPhilosophyComplete,
      audioSystem: _audioSystem,
      transitionCoordinator: transitionCoordinator,
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
    ]);

    // Bold section complete → hand off to React
    _primarySequenceRunner.onSequenceComplete = () async {
      await _primarySequenceRunner.stop();
      if (kIsWeb && !_handoffSent) {
        _handoffSent = true;
        _sendHandoff();
      }
    };
  }

  /// Called when React sends "goto-philosophy" — re-init runner with philosophy section
  Future<void> _startPhilosophySection() async {
    _primarySequenceRunner.init([_philosophySection]);
    queuer.queue(event: const SceneEvent.onScroll());
    await _primarySequenceRunner.start();
  }

  void _sendHandoff() {
    try {
      final msg = <String, String>{'type': 'flutter-handoff'}.jsify();
      web.window.parent?.postMessage(msg, '*'.toJS);
      debugPrint('postMessage sent: flutter-handoff');
    } catch (e) {
      debugPrint('postMessage error: $e');
    }
  }

  @override
  void onRemove() {
    _stateSubscription?.cancel();
    super.onRemove();
  }
}
