import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/widgets.dart';

import 'flame.dart';

final sceneProgressNotifier = ValueNotifier<double>(0.0);

class RevealScene extends StatefulWidget {
  const RevealScene({super.key});

  @override
  State<RevealScene> createState() => _RevealSceneState();
}

class _RevealSceneState extends State<RevealScene>
    with TickerProviderStateMixin {
  late final AnimationController _blinkingController;
  late final AnimationController _revealController;
  late final MyGame _game;

  bool _isGameLoaded = false;

  @override
  void initState() {
    super.initState();
    _game = MyGame();

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
    _revealController.addListener(() {
      sceneProgressNotifier.value = _revealController.value;
    });

    _initializeAndStartAnimation();
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
    _blinkingController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Layer 1: The Flame Game. It's always here, but initially hidden.
        GameWidget(game: _game),

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
