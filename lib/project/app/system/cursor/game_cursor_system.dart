import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/models/cursor_dependent_components.dart';

class GameCursorSystem {
  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();
  Vector2? _lastKnownPointerPosition;

  CursorDependentComponents? _components;

  final double glowVerticalOffset = GameLayout.cursorGlowOffset;

  void initialize(Vector2 center) {
    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();
  }

  void bindComponents(CursorDependentComponents components) {
    _components = components;
  }

  // Called when menu is revealed to kickstart movement from center to cursor
  void activate(Vector2 center) {
    // Reset virtual position to center so we see it travel to the cursor
    _virtualLightPosition = center.clone();
    // We do NOT reset _lastKnownPointerPosition so it remembers where mouse is
  }

  void setCursorPosition(Vector2 position) {
    _lastKnownPointerPosition = position;
  }

  void update(double dt, Vector2 size, {bool enableParallax = false}) {
    // todo ai: make it state based
    if (_components == null) return;
    final components = _components!;

    final cursorPosition = _lastKnownPointerPosition ?? size / 2;

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
    final easedT = GameCurves.standardEase.transform(rawT.clamp(0.0, 1.0));

    // Apply Lerp
    _virtualLightPosition.lerp(_targetLightPosition, easedT);
    _lightDirection.lerp(_targetLightDirection, easedT);

    // Update Components
    components.godRay.position =
        _virtualLightPosition; // ADDED: Smoothed position
    components.shadowScene.lightPosition = _virtualLightPosition;
    components.shadowScene.lightDirection = _lightDirection;
    components.shadowScene.logoSize = components.logoComponent.size;

    // Title Parallax
    if (enableParallax) {
      final parallaxOffset = (cursorPosition - size / 2);

      components.cinematicTitle.setParallaxOffset(
        parallaxOffset * GamePhysics.titleParallaxFactor,
      );

      components.cinematicSecondaryTitle.setParallaxOffset(
        parallaxOffset * GamePhysics.secondaryTitleParallaxFactor,
      );
    } else {
      components.cinematicTitle.setParallaxOffset(Vector2.zero());
      components.cinematicSecondaryTitle.setParallaxOffset(Vector2.zero());
    }
  }
}
