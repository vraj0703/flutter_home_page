import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class LightningController extends Component with HasGameReference<MyGame> {
  double intensity = 0.0;
  final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);
    intensity = (intensity - dt * 1.2).clamp(0.0, 1.0);
  }

  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveStrikes = 0;

  void triggerFlash(double currentRainIntensity) {
    final now = DateTime.now();
    if (now.difference(_lastTriggerTime).inMilliseconds < 2000) {
      _consecutiveStrikes++;
    } else {
      _consecutiveStrikes = 0;
    }
    _lastTriggerTime = now;

    double intensityBoost = 1.0 + (_consecutiveStrikes * 0.2);

    LoggerUtil.log(
      'LightningController',
      'Trigger Flash. Intensity: $currentRainIntensity (Consecutive: $_consecutiveStrikes, Boost: $intensityBoost)',
    );
    // The "Double Strike" logic
    intensity = 1.0;

    double soundDelaySeconds = lerpDouble(3.0, 0.1, currentRainIntensity)!;
    // Trigger spatial audio with distance-based delay
    Future.delayed(
      Duration(milliseconds: (soundDelaySeconds * 1000).toInt()),
      () {
        if (isMounted) {
          game.audio.playSpatialThunder(
            currentRainIntensity * intensityBoost,
          ); // Pass intensity, NOT delay
        }
      },
    );

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
