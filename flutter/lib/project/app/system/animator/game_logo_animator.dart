import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';

class LogoAnimationComponents {
  final LogoComponent logoComponent;
  final RayMarchingShadowComponent shadowScene;

  LogoAnimationComponents({
    required this.logoComponent,
    required this.shadowScene,
  });
}

class GameLogoAnimator {
  Vector2 _targetLogoPosition = Vector2.zero();
  double _targetLogoScale = GameLayout.logoInitialScale;
  double _currentLogoScale = GameLayout.logoInitialScale;
  Vector2 _baseLogoSize = Vector2.zero();

  double _logoPositionProgress = 0.0;
  double _logoScaleProgress = 0.0;

  final SpringCurve _logoSpringCurve = GameCurves.logoSpring;

  static const double headerY = GameLayout.logoHeaderY;

  void initialize(Vector2 baseLogoSize, Vector2 initialPosition) {
    _baseLogoSize = baseLogoSize;
    _targetLogoPosition = initialPosition;
  }

  void updateMenuLayoutTargets(Vector2 screenSize) {
    const double logoScale = GameLayout.logoMinScale;
    final double logoW = _baseLogoSize.x * logoScale;
    const double startX = GameLayout.logoStartX;
    final double logoCX = startX + (logoW / 2);

    _targetLogoPosition = Vector2(logoCX, headerY);
    _targetLogoScale = logoScale;
  }

  void setTarget({required Vector2 position, double? scale}) {
    _targetLogoPosition = position;
    if (scale != null) {
      _targetLogoScale = scale;
    }
  }

  void snapToTarget(LogoAnimationComponents components, Vector2 center) {
    components.logoComponent.position = center;
    components.shadowScene.logoPosition = center;
  }

  bool update(double dt, LogoAnimationComponents components) {
    bool positionDone = false;
    bool scaleDone = false;

    final positionDistance =
        (components.logoComponent.position - _targetLogoPosition).length;
    final scaleDistance = (_currentLogoScale - _targetLogoScale).abs();

    if (positionDistance > 2.0) {
      _logoPositionProgress =
          (_logoPositionProgress + dt * GamePhysics.logoProgressSpeed).clamp(
            0.0,
            1.0,
          );
      final curvedProgress = _logoSpringCurve.transform(_logoPositionProgress);
      components.logoComponent.position.lerp(
        _targetLogoPosition,
        curvedProgress * dt * GamePhysics.logoLerpSpeed,
      );
      components.shadowScene.logoPosition.lerp(
        _targetLogoPosition,
        curvedProgress * dt * GamePhysics.logoLerpSpeed,
      );
    } else {
      components.logoComponent.position = _targetLogoPosition.clone();
      components.shadowScene.logoPosition = _targetLogoPosition.clone();
      _logoPositionProgress = 0.0;
      positionDone = true;
    }

    if (scaleDistance > 0.01) {
      _logoScaleProgress =
          (_logoScaleProgress + dt * GamePhysics.logoProgressSpeed).clamp(
            0.0,
            1.0,
          );
      final curvedProgress = _logoSpringCurve.transform(_logoScaleProgress);
      _currentLogoScale =
          lerpDouble(
            _currentLogoScale,
            _targetLogoScale,
            curvedProgress * dt * GamePhysics.logoLerpSpeed,
          ) ??
          GameLayout.logoInitialScale;
    } else {
      _currentLogoScale = _targetLogoScale;
      _logoScaleProgress = 0.0;
      scaleDone = true;
    }

    if (_baseLogoSize != Vector2.zero()) {
      final newSize = _baseLogoSize * _currentLogoScale;
      components.logoComponent.size = newSize;
      components.shadowScene.logoSize = newSize;
    }

    return positionDone && scaleDone;
  }
}
