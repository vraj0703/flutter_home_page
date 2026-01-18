import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';

class CursorDependentComponents {
  final GodRayComponent godRay;
  final RayMarchingShadowComponent shadowScene;
  final LogoOverlayComponent interactiveUI;
  final LogoComponent logoComponent;

  CursorDependentComponents({
    required this.godRay,
    required this.shadowScene,
    required this.interactiveUI,
    required this.logoComponent,
  });
}

class GameCursorSystem {
  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();
  Vector2? _lastKnownPointerPosition;

  final double glowVerticalOffset = GameLayout.cursorGlowOffset;

  void initialize(Vector2 center) {
    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();
  }

  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }

  void update(double dt, Vector2 size, CursorDependentComponents components) {
    final cursorPosition = _lastKnownPointerPosition ?? size / 2;

    // Update target positions
    components.godRay.position = cursorPosition;
    _targetLightPosition = cursorPosition + Vector2(0, glowVerticalOffset);

    final vectorFromCenter = cursorPosition - size / 2;
    if (vectorFromCenter.length2 > 0) {
      _targetLightDirection = vectorFromCenter.normalized();
    }
    components.interactiveUI.cursorPosition =
        cursorPosition - components.interactiveUI.position;

    // Calculate smoothing
    final distance = (_targetLightPosition - _virtualLightPosition).length;
    final speed = distance > 100
        ? GamePhysics.cursorSmoothSpeedFar
        : GamePhysics.cursorSmoothSpeedNear;
    final rawT = speed * dt;
    final easedT = Curves.easeOutQuad.transform(rawT.clamp(0.0, 1.0));

    // Apply Lerp
    _virtualLightPosition.lerp(_targetLightPosition, easedT);
    _lightDirection.lerp(_targetLightDirection, easedT);

    // Update Components
    components.shadowScene.lightPosition = _virtualLightPosition;
    components.shadowScene.lightDirection = _lightDirection;
    components.shadowScene.logoSize = components.logoComponent.size;
  }
}
