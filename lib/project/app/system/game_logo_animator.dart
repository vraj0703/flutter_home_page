import 'dart:ui';
import 'package:flame/components.dart';
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
  double _targetLogoScale = 3.0;
  double _currentLogoScale = 3.0;
  Vector2 _baseLogoSize = Vector2.zero();

  double _logoPositionProgress = 0.0;
  double _logoScaleProgress = 0.0;

  final SpringCurve _logoSpringCurve = const SpringCurve(
    mass: 0.8,
    stiffness: 200.0,
    damping: 15.0,
  );

  static const double headerY = 60.0;

  void initialize(Vector2 baseLogoSize, Vector2 initialPosition) {
    _baseLogoSize = baseLogoSize;
    _targetLogoPosition = initialPosition;
  }

  void updateMenuLayoutTargets(Vector2 screenSize) {
    const double logoScale = 0.25;
    final double logoW = _baseLogoSize.x * logoScale;
    const double startX = 60.0;
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

    // If we want to snap scale too, we can, but usually snap is for reset
    // For now we just reset targets to center/defaults if needed, or update components directly
  }

  void update(double dt, LogoAnimationComponents components) {
    final positionDistance =
        (components.logoComponent.position - _targetLogoPosition).length;
    final scaleDistance = (_currentLogoScale - _targetLogoScale).abs();

    if (positionDistance > 2.0) {
      _logoPositionProgress = (_logoPositionProgress + dt * 6.0).clamp(
        0.0,
        1.0,
      );
      final curvedProgress = _logoSpringCurve.transform(_logoPositionProgress);
      components.logoComponent.position.lerp(
        _targetLogoPosition,
        curvedProgress * dt * 10.0,
      );
      components.shadowScene.logoPosition.lerp(
        _targetLogoPosition,
        curvedProgress * dt * 10.0,
      );
    } else {
      components.logoComponent.position = _targetLogoPosition.clone();
      components.shadowScene.logoPosition = _targetLogoPosition.clone();
      _logoPositionProgress = 0.0;
    }

    if (scaleDistance > 0.01) {
      _logoScaleProgress = (_logoScaleProgress + dt * 6.0).clamp(0.0, 1.0);
      final curvedProgress = _logoSpringCurve.transform(_logoScaleProgress);
      _currentLogoScale =
          lerpDouble(
            _currentLogoScale,
            _targetLogoScale,
            curvedProgress * dt * 10.0,
          ) ??
          3.0;
    } else {
      _currentLogoScale = _targetLogoScale;
      _logoScaleProgress = 0.0;
    }

    if (_baseLogoSize != Vector2.zero()) {
      final newSize = _baseLogoSize * _currentLogoScale;
      components.logoComponent.size = newSize;
      components.shadowScene.logoSize = newSize;
    }
  }
}
