import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, TextStyle, FontWeight;
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_data.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

import 'orbital_arcs_component.dart';
import 'satellite_component.dart';
import 'experience_details_component.dart';

class ExperiencePageComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  late OrbitalArcsComponent arcs;
  final List<SatelliteComponent> satellites = [];

  late TextComponent companyText;
  late TextComponent roleText;
  late TextComponent durationText;
  late ExperienceDetailsComponent detailsComponent;

  final List<ExperienceNode> data = GameData.experienceNodes;

  int _currentIndex = 0;
  double _opacity = 0.0;

  late Vector2 initialPosition;

  ExperiencePageComponent({super.size});

  @override
  double get opacity => _opacity;

  @override
  set opacity(double val) {
    _opacity = val;
    if (isLoaded) {
      arcs.opacity = val;
      _updateSatellites(arcs.rotation);
      _updateTextOpacity(val);
    }
  }

  double _targetRotation = 0.0;
  double _currentRotation = 0.0;
  double _warpScale = 1.0;

  final companyStyle = TextStyle(
    fontFamily: GameStyles.fontInter,
    fontSize: GameStyles.companyFontSize,
    letterSpacing: 1.5,
  );

  final roleStyle = TextStyle(
    fontFamily: GameStyles.fontModernUrban,
    fontSize: GameStyles.philosophyFontSize,
    fontWeight: FontWeight.bold,
  );

  final durationStyle = TextStyle(
    fontFamily: GameStyles.fontInter,
    fontSize: GameStyles.durationFontSize,
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    final double smoothing = GamePhysics.expSmoothing * dt;
    _currentRotation += (_targetRotation - _currentRotation) * smoothing;

    if ((_targetRotation - _currentRotation).abs() < 0.001) {
      _currentRotation = _targetRotation;
    }

    arcs.rotation = _currentRotation;
    arcs.rotation = _currentRotation;
    _updateSatellites(_currentRotation);
    detailsComponent.updateRotation(_currentRotation);

    if (_warpScale != 1.0) {
      scale = Vector2.all(_warpScale);
      position = (size / 2) - ((size / 2) * _warpScale);
    } else {
      scale = Vector2.all(1.0);
    }
  }

  void updateInteraction(double localScroll) {
    if (!isLoaded) return;

    final index = (localScroll / ScrollSequenceConfig.experienceScrollDivisor)
        .floor()
        .clamp(0, data.length - 1);

    final spacing = GameLayout.expSatelliteSpacing;
    final double rawProgress =
        localScroll / ScrollSequenceConfig.experienceScrollDivisor;
    final int baseIndex = rawProgress.floor();
    double applySmoothing(double t) {
      if (t <= 0 || t >= 1) return t;
      final double curvedT = GameCurves.smoothDecel.transform(t);
      return curvedT;
    }

    final double curvedT = applySmoothing(rawProgress - baseIndex);
    final double curvedProgress = baseIndex + curvedT;

    _targetRotation = -(curvedProgress * spacing);

    if (index != _currentIndex) {
      final bool isReverse = index < _currentIndex;
      _currentIndex = index;
      _updateContent(forceUpdate: true, op: _opacity, isReverse: isReverse);
    }
  }

  void setWarp(double progress) {
    final t = progress.clamp(0.0, 1.0);
    _warpScale = 1.0 + (pow(t, 3) * (GameLayout.expWarpMaxScale - 1.0));
  }

  void _updateSatellites(double systemRotation) {
    final center = Vector2(0, size.y / 2);
    final orbitRadius = (size.y * 1) * GameLayout.expOrbitRadiusRatio;

    final spacing = GameLayout.expSatelliteSpacing;

    for (int i = 0; i < satellites.length; i++) {
      final s = satellites[i];
      final baseAngle = i * spacing;
      final currentAngle = baseAngle + systemRotation;
      final x = center.x + orbitRadius * cos(currentAngle);
      final y = center.y + orbitRadius * sin(currentAngle);
      s.position = Vector2(x, y);
      s.angle = currentAngle + (pi / 2);

      double diff = (currentAngle % (2 * pi));
      if (diff > pi) diff -= 2 * pi;
      if (diff < -pi) diff += 2 * pi;

      final dist = diff.abs();
      final globalFade = _opacity;

      if (dist < GameLayout.expActiveThreshold) {
        final t = 1.0 - (dist / GameLayout.expActiveThreshold);
        s.scale = Vector2.all(
          GameLayout.expInactiveScale +
              ((GameLayout.expActiveScale - GameLayout.expInactiveScale) * t),
        );
        s.opacity =
            (GameStyles.expInactiveOpacity +
                ((GameStyles.expActiveOpacity - GameStyles.expInactiveOpacity) *
                    t)) *
            globalFade;
      } else {
        s.scale = Vector2.all(GameLayout.expInactiveScale);
        s.opacity = GameStyles.expInactiveOpacity * globalFade;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    initialPosition = position.clone();

    final halfHeight = size.y / 2;

    arcs = OrbitalArcsComponent(
      accentColor: GameStyles.accentGold,
      size: Vector2(
        size.x * GameLayout.experienceOrbitRelW,
        size.y,
      ), // Left 40%
    );
    arcs.position = Vector2(0, 0); // Left aligned
    add(arcs);

    for (var node in data) {
      final s = SatelliteComponent(
        year: node.year,
        color: GameStyles.accentGold,
      );
      s.anchor = Anchor.center;
      satellites.add(s);
      add(s);
    }

    final textX = size.x * GameLayout.experienceTextRelX;
    companyText = TextComponent(
      text: data[0].company.toUpperCase(),
      textRenderer: TextPaint(
        style: companyStyle.copyWith(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      position: Vector2(textX, halfHeight - 40),
    );
    add(companyText);

    roleText = TextComponent(
      text: data[0].title,
      textRenderer: TextPaint(style: roleStyle),
      position: Vector2(textX, halfHeight - 10),
    );
    add(roleText);

    durationText = TextComponent(
      text: "${data[0].duration} | ${data[0].location}",
      textRenderer: TextPaint(
        style: durationStyle.copyWith(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      position: Vector2(textX, halfHeight + 60),
    );
    add(durationText);

    detailsComponent = ExperienceDetailsComponent(data: data)..size = size;
    add(detailsComponent);
    _opacity = 0.0;
    arcs.opacity = 0.0;

    for (final s in satellites) {
      s.opacity = 0.0;
    }
    _updateContent(forceUpdate: false, op: 0.0);
    detailsComponent.opacity = 0.0;
    detailsComponent.updateRotation(_currentRotation);
  }

  void _updateTextOpacity(double parentOpacity) {
    if (!isLoaded) return;
    detailsComponent.opacity = parentOpacity;
    _updateContent(forceUpdate: false, op: parentOpacity);
  }

  void _updateContent({
    bool forceUpdate = false,
    double? op,
    bool isReverse = false,
  }) {
    double alpha = op ?? _opacity;
    final item = data[_currentIndex];

    // Colors
    final white = Colors.white.withValues(alpha: alpha);
    final dim = Colors.white.withValues(alpha: 0.6 * alpha);

    if (forceUpdate) {
      final startOffset =
          GameLayout.expTextAnimOffset * (isReverse ? -1.0 : 1.0);
      final halfHeight = size.y / 2;
      final textX = size.x * 0.05;

      companyText.position = Vector2(textX, halfHeight - 40 + startOffset);
      roleText.position = Vector2(textX, halfHeight - 10 + startOffset);
      durationText.position = Vector2(textX, halfHeight + 60 + startOffset);

      companyText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 40),
          EffectController(duration: 0.4, curve: GameCurves.standardReveal),
        ),
      );

      roleText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 10),
          EffectController(
            duration: 0.4,
            curve: GameCurves.standardReveal,
            startDelay: 0.1,
          ),
        ),
      );

      durationText.add(
        MoveToEffect(
          Vector2(textX, halfHeight + 60),
          EffectController(
            duration: 0.4,
            curve: GameCurves.standardReveal,
            startDelay: 0.2,
          ),
        ),
      );
    }

    companyText.text = item.company.toUpperCase();
    companyText.textRenderer = TextPaint(
      style: companyStyle.copyWith(color: dim),
    );

    roleText.text = item.title;
    roleText.textRenderer = TextPaint(
      style: roleStyle.copyWith(color: white, height: 1.1),
    );

    durationText.text = "${item.duration} | ${item.location}";
    durationText.textRenderer = TextPaint(
      style: durationStyle.copyWith(color: dim),
    );
  }
}
