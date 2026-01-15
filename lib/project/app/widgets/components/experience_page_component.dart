import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

import 'orbital_arcs_component.dart';
import 'satellite_component.dart';

class ExperiencePageComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  late OrbitalArcsComponent arcs;
  final List<SatelliteComponent> satellites = [];

  // Text Components
  late TextComponent companyText;
  late TextComponent roleText;
  late TextComponent durationText;
  late RectangleComponent connectorLine;

  int _currentIndex = 0;
  double _opacity = 0.0;

  // Stored for parallax
  late Vector2 initialPosition;

  ExperiencePageComponent({super.size});

  @override
  double get opacity => _opacity;

  @override
  @override
  set opacity(double val) {
    _opacity = val;
    if (isLoaded) {
      arcs.opacity = val;
      _updateSatellites(arcs.rotation); // Update opacity of satellites
      _updateTextOpacity(val);
    }
  }

  // Smoothing
  double _targetRotation = 0.0;
  double _currentRotation = 0.0;

  // Warp
  double _warpScale = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    // Inertia / Smoothing (Lerp current to target)
    final double smoothing = 5.0 * dt;
    _currentRotation += (_targetRotation - _currentRotation) * smoothing;

    if ((_targetRotation - _currentRotation).abs() < 0.001) {
      _currentRotation = _targetRotation;
    }

    arcs.rotation = _currentRotation;
    _updateSatellites(_currentRotation);

    // Apply Warp Scale
    if (_warpScale != 1.0) {
      scale = Vector2.all(_warpScale);
      position = (size / 2) - ((size / 2) * _warpScale);
    }
  }

  // Called by Controller
  void updateInteraction(double localScroll) {
    if (!isLoaded) return;

    // Range: 0 to 5000 (5 items)
    final index = (localScroll / 1000).floor().clamp(0, data.length - 1);

    // Rotation Calculation (Spin wheel) - Set Target - REVERSED
    // We want alignment: (i * spacing) + (rot * 1.2) = 0 when scroll = i * 1000
    // rot = -(i * spacing) / 1.2
    // rot = -(scroll/1000 * spacing) / 1.2 = -(scroll * spacing) / 1200
    final spacing = pi / 4;
    _targetRotation = -(localScroll * spacing) / 1200;

    if (index != _currentIndex) {
      _currentIndex = index;
      _updateContent(forceUpdate: true, op: _opacity);
      _pulseNeedle();
    }
  }

  void setWarp(double progress) {
    // progress 0.0 -> 1.0 (Exit Phase)
    // Exponential Scale: 1.0 -> 8.0
    _warpScale = 1.0 + (pow(progress, 3) * 7.0);
  }

  void _updateSatellites(double systemRotation) {
    final center = Vector2(0, size.y / 2);
    final orbitRadius = (size.y * 0.8) * 0.65;

    // Angle spacing: spread 5 items over e.g. 180 degrees or full circle?
    final spacing = pi / 4;

    for (int i = 0; i < satellites.length; i++) {
      final s = satellites[i];

      // Positive i * spacing places subsequent items "Below" (Positive Angle = Clockwise/Down)
      final baseAngle = i * spacing;

      // systemRotation is negative (Top-Bottom scroll moves angle Counter-Clockwise/Up)
      final currentAngle = baseAngle + (systemRotation * 1.2);

      // Position
      final x = center.x + orbitRadius * cos(currentAngle);
      final y = center.y + orbitRadius * sin(currentAngle);
      s.position = Vector2(x, y);
      s.angle = currentAngle + (pi / 2); // Tangential Tilt

      // Spatial Fade & Scale
      double diff = (currentAngle % (2 * pi));
      if (diff > pi) diff -= 2 * pi;
      if (diff < -pi) diff += 2 * pi;

      final dist = diff.abs();

      final activeThreshold = 0.35; // ~20 deg
      final globalFade = _opacity;

      if (dist < activeThreshold) {
        final t = 1.0 - (dist / activeThreshold);
        s.scale = Vector2.all(0.8 + (0.4 * t));
        s.opacity = (0.2 + (0.8 * t)) * globalFade;
      } else {
        s.scale = Vector2.all(0.8);
        s.opacity = 0.2 * globalFade;
      }
    }
  }

  void _pulseNeedle() {
    // Trigger needle elastic pulse
    connectorLine.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2(1.0, 3.0),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2(1.0, 1.0),
          EffectController(duration: 0.4, curve: Curves.elasticOut),
        ),
      ]),
    );
  }

  @override
  Future<void> onLoad() async {
    initialPosition = position.clone();

    // 1. Setup Visuals
    final halfHeight = size.y / 2;

    // Left Arcs
    arcs = OrbitalArcsComponent(
      accentColor: const Color(0xFFC78E53),
      size: Vector2(size.x * 0.4, size.y), // Left 40%
    );
    arcs.position = Vector2(0, 0); // Left aligned
    add(arcs);

    // Create Satellites
    for (var node in data) {
      final s = SatelliteComponent(
        year: node.year,
        color: const Color(0xFFC78E53),
      );
      s.anchor = Anchor.center;
      satellites.add(s);
      add(s);
    }

    // Connector Line (Center-Left to Content)
    connectorLine = RectangleComponent(
      size: Vector2(60, 2),
      paint: Paint()..color = const Color(0xFFC78E53),
      position: Vector2(size.x * 0.35, halfHeight), // Connect arc to text
      anchor: Anchor.centerLeft,
    );
    add(connectorLine);

    // Right Content Area
    final textX = size.x * 0.45;

    // Company (Small Label)
    companyText = TextComponent(
      text: data[0].company.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          letterSpacing: 1.5,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      position: Vector2(textX, halfHeight - 40),
    );
    add(companyText);

    // Role (Large Title)
    roleText = TextComponent(
      text: data[0].title,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.1,
        ),
      ),
      position: Vector2(textX, halfHeight - 10),
    );
    add(roleText);

    // Duration/Location (Subtext)
    durationText = TextComponent(
      text: "${data[0].duration} | ${data[0].location}",
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      position: Vector2(textX, halfHeight + 60),
    );
    add(durationText);

    // REMOVED yearText (replaced by Satellites)

    // Initial State Check - Force everything hidden regardless of isLoaded flag
    _opacity = 0.0;
    arcs.opacity = 0.0;

    // Force update satellites to invisible
    for (final s in satellites) {
      s.opacity = 0.0;
    }

    // Force update text to invisible
    connectorLine.paint.color = const Color(0xFFC78E53).withValues(alpha: 0.0);
    _updateContent(forceUpdate: false, op: 0.0);
  }

  void _updateTextOpacity(double parentOpacity) {
    if (!isLoaded) return;
    connectorLine.paint.color = const Color(
      0xFFC78E53,
    ).withValues(alpha: parentOpacity);
    _updateContent(forceUpdate: false, op: parentOpacity);
  }

  void _updateContent({bool forceUpdate = false, double? op}) {
    double alpha = op ?? _opacity;
    final item = data[_currentIndex];

    // Colors
    final white = Colors.white.withValues(alpha: alpha);
    final dim = Colors.white.withValues(alpha: 0.6 * alpha);

    if (forceUpdate) {
      // Slide Up Logic
      final startOffset = 30.0;
      final halfHeight = size.y / 2;
      final textX = size.x * 0.45;

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

    // Replay text renderer with new alpha
    companyText.text = item.company.toUpperCase();
    companyText.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        letterSpacing: 1.5,
        color: dim,
      ),
    );

    roleText.text = item.title;
    roleText.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: white,
        height: 1.1,
      ),
    );

    durationText.text = "${item.duration} | ${item.location}";
    durationText.textRenderer = TextPaint(
      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: dim),
    );
  }
}
