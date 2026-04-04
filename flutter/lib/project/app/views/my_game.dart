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
import 'package:flutter_home_page/project/app/sections/contact_section.dart';
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

  /// Loading progress (0.0–1.0) exposed for the overlay widget.
  final ValueNotifier<double> loadingProgress = ValueNotifier(0.0);

  MyGame({this.onStartExitAnimation, required SceneBloc bloc})
    : _bloc = bloc,
      queuer = bloc,
      stateProvider = bloc;

  final ScrollSystem _contactScrollSystem = ScrollSystem();

  ScrollSystem get scrollSystem => _contactScrollSystem;

  late final SequenceRunner _primarySequenceRunner = SequenceRunner(
    scrollSystem: _contactScrollSystem,
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

  ContactSection get contactSection => _contactSection;

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

  // White overlay fade state machine for smooth Flutter→Flutter transitions
  String _fadePhase = 'idle'; // idle | fadeIn | hold | fadeOut
  double _fadeProgress = 0.0;
  static const double _fadeDuration = 0.4; // seconds per fade direction
  VoidCallback? _onFadeMidpoint; // called when overlay is fully opaque

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
      scrollSystem: _contactScrollSystem,
      audioSystem: _audioSystem,
      cursorSystem: _cursorSystem,
      stateProvider: stateProvider,
    );

    add(_inputController);

    _primarySequenceRunner
        .warmUpAll(
          onProgress: (progress) {
            loadingProgress.value = progress;
            if (kIsWeb) {
              final msg = {'type': 'flutter-loading', 'progress': progress}.jsify();
              web.window.parent?.postMessage(msg, '*'.toJS);
            }
          },
        )
        .whenComplete(() {
          _warmupComplete = true;
        });

    // Listen for React messages (goto-contact)
    if (kIsWeb) {
      web.window.addEventListener(
        'message',
        (web.Event event) {
          final msgEvent = event as web.MessageEvent;
          final data = msgEvent.data;
          if (data == null) return;
          final dartData = data.dartify();
          if (dartData is Map) {
            final type = dartData['type'];
            if (type == 'flutter-pause') {
              paused = true;
            } else if (type == 'flutter-resume') {
              paused = false;
            } else if (type == 'goto-contact') {
              debugPrint('[Flutter] Received goto-contact');
              _handoffSent = false; // Allow future handoffs
              _startContactSection();
            } else if (type == 'goto-home') {
              debugPrint('[Flutter] Received goto-home');
              _handoffSent = false; // Allow future handoffs
              _startHomeSection();
            }
          }
        }.toJS,
      );
    }

    // Register controllers to contact scroll system
    _contactScrollSystem.register(_primarySequenceRunner);
  }

  late final FragmentShader flashShader;

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

    // Route taps to contact cards (Flame's TapCallbacks can't hit
    // perspective-transformed cards — their visual position differs
    // from their logical position in the component tree)
    if (_primarySequenceRunner.currentSection is ContactSection) {
      final tapPos = Vector2(event.localPosition.x, event.localPosition.y);
      for (final card in _componentFactory.contactTrail.cards) {
        if (card.isFlipped && card.containsPoint(tapPos)) {
          card.openUrl();
          break;
        }
      }
    }

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

    // White overlay fade state machine (for smooth Flutter→Flutter transitions)
    if (_fadePhase == 'fadeIn') {
      _fadeProgress = (_fadeProgress + dt / _fadeDuration).clamp(0.0, 1.0);
      _componentFactory.whiteOverlay.opacity = _fadeProgress;
      if (_fadeProgress >= 1.0) {
        _fadePhase = 'hold';
        _onFadeMidpoint?.call();
        _onFadeMidpoint = null;
        _fadePhase = 'fadeOut';
      }
    } else if (_fadePhase == 'fadeOut') {
      _fadeProgress = (_fadeProgress - dt / _fadeDuration).clamp(0.0, 1.0);
      _componentFactory.whiteOverlay.opacity = _fadeProgress;
      if (_fadeProgress <= 0.0) {
        _fadePhase = 'idle';
      }
    }

    // Check State
    final state = stateProvider.sceneState();

    _godRayController?.updatePulse(dt);

    // Update Runner
    state.maybeWhen(
      active: (_, __) {
        _contactScrollSystem.update(dt);
        _primarySequenceRunner.update(dt);
      },
      orElse: () {},
    );

    // Handoff is now triggered by contact button hold complete
    // (see contact_section.dart onHoldComplete callback)

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
          _sendFlutterReady();
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

  void _configureGlobal() {
    _godRayController = GodRayController(
      component: _componentFactory.godRay,
      screenSize: size,
    );
    scrollSystem.register(_godRayController!);
  }

  late ContactSection _contactSection;
  late BoldTextSection _boldTextSection;

  void _initSequence() {
    // 1. Bold Text
    _boldTextSection = BoldTextSection(
      boldTextComponent: _componentFactory.boldTextReveal,
      backgroundRun: _componentFactory.backgroundRun,
      cinematicTitle: _componentFactory.cinematicTitle,
      cinematicSecondaryTitle: _componentFactory.cinematicSecondaryTitle,
      logoOverlay: _componentFactory.logoOverlay,
      centerPosition: size / 2,
    );
    // 2. contact (stored as field for later goto-contact)
    // Wire Home button to navigate to title screen
    _componentFactory.homeButton.onTap = () => _startHomeSection();

    // Wire Audio toggle to mute/unmute
    _componentFactory.audioToggle.onTap = () => _audioSystem.toggleMute();
    _componentFactory.audioToggle.isMuted = () => _audioSystem.isMuted;

    _contactSection = ContactSection(
      titleComponent: _componentFactory.contactText,
      cloudBackground: _componentFactory.beachBackground,
      trailComponent: _componentFactory.contactTrail,
      backButton: _componentFactory.backButton,
      whiteOverlay: _componentFactory.whiteOverlay,
      logoComponent: _componentFactory.logoComponent,
      homeButton: _componentFactory.homeButton,
      audioToggle: _componentFactory.audioToggle,
      screenSize: size,
      playEntrySound: audio.playContactEntry,
      playCompletionSound: audio.playContactComplete,
      audioSystem: _audioSystem,
      transitionCoordinator: transitionCoordinator,
    );

    // Configure components via binding-like logic (formerly addBoldTextBindings)
    _componentFactory.boldTextReveal.opacity = 0.0;
    // contact text setup
    _componentFactory.contactText.priority = 20;
    _componentFactory.contactText.anchor = Anchor.center;
    _componentFactory.contactText.position = Vector2(
      size.x / 2,
      size.y * GameLayout.contactTextYRatio,
    );
    _componentFactory.contactText.scale = Vector2.all(
      GameLayout.contactTextScale,
    );
    _componentFactory.contactText.opacity = 0.0;

    _primarySequenceRunner.init([_boldTextSection]);

    // Bold section complete → hand off to React
    _primarySequenceRunner.onSequenceComplete = () async {
      await _primarySequenceRunner.stop();
      if (kIsWeb && !_handoffSent) {
        _handoffSent = true;
        _sendHandoff();
      }
    };
  }

  /// Called when Home button tapped or React sends "goto-home"
  /// Animated white overlay: fade in → swap section → fade out (~0.8s total)
  void _startHomeSection() {
    if (_fadePhase != 'idle') return; // Prevent double-tap
    _audioSystem.stopAll();

    _fadePhase = 'fadeIn';
    _fadeProgress = 0.0;
    _onFadeMidpoint = () async {
      // This runs when the overlay is fully opaque — user sees white
      await _primarySequenceRunner.restoreToSection(0, [_boldTextSection]);

      // Re-wire handoff
      _primarySequenceRunner.onSequenceComplete = () async {
        await _primarySequenceRunner.stop();
        if (kIsWeb && !_handoffSent) {
          _handoffSent = true;
          _sendHandoff();
        }
      };

      queuer.queue(event: const SceneEvent.titleLoaded());
      queuer.queue(event: const SceneEvent.onScroll());
      queuer.queue(event: const SceneEvent.toggleArrow(true));
      unblockInput();
    };
  }

  /// Called when React sends "goto-contact" — re-init runner with contact section
  /// React's SectionTransition wipe covers the visual swap — no extra overlay needed.
  Future<void> _startContactSection() async {
    _primarySequenceRunner.init([_contactSection]);
    queuer.queue(event: const SceneEvent.onScroll());
    queuer.queue(event: const SceneEvent.toggleArrow(false));
    await _primarySequenceRunner.start();
  }

  /// Notify parent React frame that Flutter engine is loaded and ready.
  void _sendFlutterReady() {
    if (!kIsWeb) return;
    try {
      final msg = <String, String>{'type': 'flutter-ready'}.jsify();
      web.window.parent?.postMessage(msg, '*'.toJS);
      debugPrint('postMessage sent: flutter-ready');
    } catch (e) {
      debugPrint('postMessage error: $e');
    }
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
