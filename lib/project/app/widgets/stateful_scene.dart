import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/widgets/widgets/curtain_clipper.dart';
import 'package:flutter_home_page/project/app/widgets/widgets/home_overlay.dart'; // Import overlay

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

  // Notifier to trigger the overlay reveal
  final ValueNotifier<bool> _showOverlayNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _showArrowNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    _bloc = BlocProvider.of<SceneBloc>(context);
    // Controller for the "LOADING" text's blinking effect.
    _blinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    // This controller drives the curtain opening and the in-game animations.
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // Continuous loop

    // 2. Define the vertical offset (bounces 15 pixels down)
    _downArrowBounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _downArrowBounceController,
        curve: Curves.easeInOutQuad, // Smooth "floating" motion
      ),
    );
  }

  void _updateSceneProgress() {
    revealProgressNotifier.value = _revealController.value;
  }

  @override
  void dispose() {
    _revealController.removeListener(_updateSceneProgress);
    _blinkingController.dispose();
    _revealController.dispose();
    _showOverlayNotifier.dispose();
    _showArrowNotifier.dispose();
    _downArrowBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SceneBloc, SceneState>(
      listener: (context, state) {
        state.when(
          loading: () {
            _revealController.reverse();
          },
          logo: () {
            if (mounted) {
              _blinkingController.stop();
              _revealController.forward();
            }
          },
          logoOverlayRemoving: () {},
          titleLoading: () {},
          title: () {},
        );
      },
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            GameWidget(game: _bloc.game),
            // Layer 1: The Flame Game wrapped in HomeOverlay
            HomeOverlay(
              showOverlayNotifier: _showOverlayNotifier,
              showArrowNotifier: _showArrowNotifier,
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

            TweenAnimationBuilder<double>(
              // Animates from current value to this 'end' whenever it changes
              tween: Tween<double>(
                begin: state is Loading ? 0.0 : _blinkingController.value,
                end: state is Loading ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.linearToEaseOut,
              // Decelerates for a smoother "exit" feel
              builder: (context, value, child) {
                return IgnorePointer(
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: FadeTransition(
                key: ValueKey('loading'),
                opacity: _blinkingController,
                child: const Text(
                  'L O A D I N G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Broadway",
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
