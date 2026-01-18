import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
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

  static const double smoothingFactor = 5.0;
  static const double orbitRadiusRatio = 0.65;
  static const double activeThreshold = 0.35;
  static const double activeScale = 1.2;
  static const double inactiveScale = 0.8;
  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.2;
  static const double warpMaxScale = 8.0;

  final companyStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    letterSpacing: 1.5,
  );

  final roleStyle = TextStyle(
    fontFamily: 'ModrntUrban',
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  final durationStyle = TextStyle(fontFamily: 'Inter', fontSize: 14);

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    final double smoothing = smoothingFactor * dt;
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

    final index = (localScroll / 500).floor().clamp(0, data.length - 1);

    final spacing = pi / 4;
    final double rawProgress = localScroll / 500.0;
    final int baseIndex = rawProgress.floor();
    final double t = rawProgress - baseIndex;

    final double curvedT = Curves.easeOutQuart.transform(t);
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
    _warpScale = 1.0 + (pow(t, 3) * (warpMaxScale - 1.0));
  }

  void _updateSatellites(double systemRotation) {
    final center = Vector2(0, size.y / 2);
    final orbitRadius = (size.y * 1) * orbitRadiusRatio;

    final spacing = pi / 4;

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

      if (dist < activeThreshold) {
        final t = 1.0 - (dist / activeThreshold);
        s.scale = Vector2.all(
          inactiveScale + ((activeScale - inactiveScale) * t),
        );
        s.opacity =
            (inactiveOpacity + ((activeOpacity - inactiveOpacity) * t)) *
            globalFade;
      } else {
        s.scale = Vector2.all(inactiveScale);
        s.opacity = inactiveOpacity * globalFade;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    initialPosition = position.clone();

    final halfHeight = size.y / 2;

    arcs = OrbitalArcsComponent(
      accentColor: const Color(0xFFC78E53),
      size: Vector2(size.x * 0.4, size.y), // Left 40%
    );
    arcs.position = Vector2(0, 0); // Left aligned
    add(arcs);

    for (var node in data) {
      final s = SatelliteComponent(
        year: node.year,
        color: const Color(0xFFC78E53),
      );
      s.anchor = Anchor.center;
      satellites.add(s);
      add(s);
    }

    final textX = size.x * 0.05;
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
      final startOffset = 30.0 * (isReverse ? -1.0 : 1.0);
      final halfHeight = size.y / 2;
      final textX = size.x * 0.05;

      companyText.position = Vector2(textX, halfHeight - 40 + startOffset);
      roleText.position = Vector2(textX, halfHeight - 10 + startOffset);
      durationText.position = Vector2(textX, halfHeight + 60 + startOffset);

      companyText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 40),
          EffectController(duration: 0.4, curve: Curves.easeOut),
        ),
      );

      roleText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 10),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOut,
            startDelay: 0.1,
          ),
        ),
      );

      durationText.add(
        MoveToEffect(
          Vector2(textX, halfHeight + 60),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOut,
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
