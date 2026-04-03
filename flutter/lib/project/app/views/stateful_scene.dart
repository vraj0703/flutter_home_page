import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/widgets/curtain_clipper.dart';
import 'package:flutter_home_page/project/app/views/widgets/home_overlay.dart';

class StatefulScene extends StatefulWidget {
  final VoidCallback onClick;

  const StatefulScene({super.key, required this.onClick});

  @override
  State<StatefulScene> createState() => _StatefulSceneState();
}

class _StatefulSceneState extends State<StatefulScene>
    with TickerProviderStateMixin {
  late final AnimationController _blinkingController;
  late final AnimationController _revealController;
  late final AnimationController _downArrowBounceController;
  late final Animation<double> _downArrowBounceAnimation;
  late SceneBloc _bloc;
  late final MyGame _game;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<SceneBloc>(context);
    _blinkingController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: ScrollSequenceConfig.sceneFadeDurationMs,
      ),
    )..repeat(reverse: true);

    // This controller drives the curtain opening and the in-game animations.
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: ScrollSequenceConfig.sceneRevealDuration,
      ),
    );

    // Link the controller to our global notifier.
    _revealController.addListener(_updateSceneProgress);

    _revealController.addStatusListener((status) {
      // When the curtain has fully closed (animation is 'dismissed')
      if (status == AnimationStatus.dismissed) {
        widget.onClick(); // Call the final callback
      }
    });

    // 1. Setup the Bounce Animation
    _downArrowBounceController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: ScrollSequenceConfig.arrowBounceDuration,
      ),
    )..repeat(reverse: true); // Continuous loop

    // 2. Define the vertical offset (bounces 15 pixels down)
    _downArrowBounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _downArrowBounceController,
        curve: GameCurves.arrowBounce, // Smooth "floating" motion
      ),
    );

    _game = MyGame(
      bloc: _bloc,
      onStartExitAnimation: () => _bloc.add(const SceneEvent.closeCurtain()),
    );
  }

  void _updateSceneProgress() {
    _bloc.updateRevealProgress(_revealController.value);
  }

  @override
  void dispose() {
    _revealController.removeListener(_updateSceneProgress);
    _blinkingController.dispose();
    _revealController.dispose();
    _downArrowBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SceneBloc, SceneState>(
      listenWhen: (previous, current) {
        return previous.runtimeType != current.runtimeType;
      },
      listener: (context, state) {
        state.when(
          loading: (isSvgReady, isGameReady) {
            _revealController.reverse();
          },
          logo: () {
            _game.introFlow.loadBouncingLines();
            if (mounted) {
              _blinkingController.stop();
              _revealController.forward();
            }
          },
          logoOverlayRemoving: () {
            _game.introFlow.startLogoRemoval();
            _game.audio.playEnterSound();
            _game.introFlow.loadTitleBackground();
          },
          titleLoading: () {
            _game.introFlow.enterTitle();
          },
          title: () {
            _game.audio.playBouncyArrow();
            _game.introFlow.activateTitleCursorSystem(_game.size);
          },
          active: (_, _) {
            // Game is now fully active and scrolling
            _game.unblockInput();
            _game.primarySequenceRunner.start();
          },
        );
      },
      builder: (context, state) {
        return Listener(
          onPointerHover: (event) {
            _game.setCursorPosition(
              Vector2(event.localPosition.dx, event.localPosition.dy),
            );
          },
          child: MouseRegion(
            onEnter: (event) {
              _game.setCursorPosition(
                Vector2(event.localPosition.dx, event.localPosition.dy),
              );
            },
            onHover: (event) {
              _game.setCursorPosition(
                Vector2(event.localPosition.dx, event.localPosition.dy),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                GameWidget(game: _game),
                // Layer 1: The Flame Game wrapped in HomeOverlay
                HomeOverlay(
                  key: const ValueKey("home_overlay"),
                  bounceAnimation: _downArrowBounceAnimation,
                ),

                // Layer 2: The Black Curtain.
                // This is the core of the curtain effect. It's a black container that
                // is "clipped" away by an animated path.
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return ClipPath(
                      // The custom clipper uses the controller's value to animate the path.
                      clipper: CurtainClipper(
                        revealProgress: _revealController.value,
                      ),
                      child: Container(color: Colors.black),
                    );
                  },
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}
