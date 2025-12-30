import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/widgets.dart';
import 'package:flutter_home_page/project/app/widgets/home_overlay.dart'; // Import overlay
import 'package:flutter/gestures.dart';
import 'scene.dart';

final sceneProgressNotifier = ValueNotifier<double>(0.0);

class RevealScene extends StatefulWidget {
  final VoidCallback onClick;

  const RevealScene({super.key, required this.onClick});

  @override
  State<RevealScene> createState() => _RevealSceneState();
}

class _RevealSceneState extends State<RevealScene>
    with TickerProviderStateMixin {
  late final AnimationController _blinkingController;
  late final AnimationController _revealController;
  late final MyGame _game;

  // Notifier to trigger the overlay reveal
  final ValueNotifier<bool> _showOverlayNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _showArrowNotifier = ValueNotifier(true);

  bool _isGameLoaded = false;

  @override
  void initState() {
    super.initState();
    _game = MyGame(onStartExitAnimation: _closeCurtain);

    // Wire up the new callback
    _game.onHeaderAnimationComplete = () {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          _showOverlayNotifier.value = true;
        }
      });
    };

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

    _initializeAndStartAnimation();
  }

  void _handleScroll() {
    // Only trigger if the overlay is visible and arrow is still showing
    if (_showOverlayNotifier.value && _showArrowNotifier.value) {
      _showArrowNotifier.value = false;
      _game.onScroll();
    }
  }

  void _updateSceneProgress() {
    sceneProgressNotifier.value = _revealController.value;
  }

  void _closeCurtain() {
    _revealController.reverse();
  }

  void _initializeAndStartAnimation() async {
    // Wait for the game's assets to be fully loaded in the background.
    await _game.loaded;
    await Future.delayed(Duration(milliseconds: 600));
    if (mounted) {
      // Once loaded, stop the blinking and trigger the reveal sequence.
      _blinkingController.stop();
      setState(() => _isGameLoaded = true);
      _revealController.forward();
    }
  }

  @override
  void dispose() {
    _revealController.removeListener(_updateSceneProgress);
    _blinkingController.dispose();
    _revealController.dispose();
    _showOverlayNotifier.dispose();
    _showArrowNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Layer 1: The Flame Game wrapped in HomeOverlay
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -5) {
              _handleScroll();
            }
          },
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent && event.scrollDelta.dy > 0) {
                _handleScroll();
              }
            },
            child: HomeOverlay(
              showOverlayNotifier: _showOverlayNotifier,
              showArrowNotifier: _showArrowNotifier,
              child: GameWidget(game: _game),
            ),
          ),
        ),

        // Layer 2: The Black Curtain.
        // This is the core of the curtain effect. It's a black container that
        // is "clipped" away by an animated path.
        AnimatedBuilder(
          animation: _revealController,
          builder: (context, child) {
            return ClipPath(
              // The custom clipper uses the controller's value to animate the path.
              clipper: CurtainClipper(revealProgress: _revealController.value),
              child: Container(color: Colors.black),
            );
          },
        ),

        // Layer 3: The Loading Text.
        // It fades out as soon as the game is loaded.
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _isGameLoaded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: FadeTransition(
              opacity: _blinkingController,
              child: const Text(
                'L O A D I N G',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
