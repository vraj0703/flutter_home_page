import 'dart:math' as math;
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class LightningController extends Component with HasGameReference<MyGame> {
  double intensity = 0.0;
  double _timer = 0.0;
  final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);
    _timer -= dt;

    if (_timer <= 0) {
      _timer = 3.0 + _rng.nextDouble() * 7.0;
      _triggerFlash();
    }

    intensity = (intensity - dt * 1.2).clamp(0.0, 1.0);
  }

  void _triggerFlash() {
    // The "Double Strike" logic
    intensity = 1.0;

    // Trigger spatial audio with distance-based delay
    game.audio.playSpatialThunder(intensity);

    // Screen shake effect for strong lightning
    if (intensity > 0.9) {
      game.camera.viewfinder.add(
        MoveEffect.by(
          Vector2.zero(),
          EffectController(duration: 0.5, curve: Curves.easeOut),
        )..onComplete = () {},
      );

      // Add subtle shake
      final shakeIntensity = 5.0;
      final shakeFreq = 30.0;
      for (int i = 0; i < 15; i++) {
        final delay = i / shakeFreq;
        final offset = Vector2(
          _rng.nextDouble() * shakeIntensity * 2 - shakeIntensity,
          _rng.nextDouble() * shakeIntensity * 2 - shakeIntensity,
        );
        Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
          if (isMounted) {
            game.camera.viewfinder.position += offset;
          }
        });
      }
    }

    // Brief delay then a second smaller peak
    Future.delayed(const Duration(milliseconds: 150), () {
      if (isMounted) {
        intensity = 0.8;
      }
    });
  }
}
