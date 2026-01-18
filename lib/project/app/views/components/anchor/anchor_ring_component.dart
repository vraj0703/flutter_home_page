import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/anchor_config.dart';
import 'package:flutter_home_page/project/app/views/components/anchor/anchor_particle.dart';

/// The Orbital Anchor Ring - a glowing ring that guides user attention
/// throughout the scroll sequence with dynamic animations and color transitions.
class AnchorRingComponent extends PositionComponent with HasPaint {
  // Visual properties
  double _ringRadius = AnchorConfig.ringRadiusBase;
  double _rotation = 0.0;
  Color _currentColor = AnchorConfig.colorSoftWhite;
  double _glowIntensity = 1.0;

  // Particle trail
  final List<AnchorParticle> _particles = [];
  double _particleSpawnTimer = 0.0;
  bool _particlesEnabled = false;

  // Multi-orbit state (for experience section)
  final List<_OrbitRing> _multiOrbitRings = [];
  bool _multiOrbitMode = false;

  // Rainbow shimmer state (for zoom-out finale)
  double _rainbowPhase = 0.0;
  bool _rainbowMode = false;

  // Animation time
  double _time = 0.0;

  AnchorRingComponent({
    super.position,
    super.priority,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update rotation
    _rotation += dt * AnchorConfig.rotationSpeedMedium;

    // Update rainbow phase for finale
    if (_rainbowMode) {
      _rainbowPhase += dt * AnchorConfig.rainbowCycleSpeed;
      if (_rainbowPhase > 1.0) _rainbowPhase -= 1.0;
    }

    // Update particle spawning
    if (_particlesEnabled) {
      _particleSpawnTimer -= dt;
      if (_particleSpawnTimer <= 0) {
        _spawnParticle();
        _particleSpawnTimer = AnchorConfig.particleSpawnRate;
      }
    }

    // Update multi-orbit rings
    if (_multiOrbitMode) {
      for (final ring in _multiOrbitRings) {
        ring.update(dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) return;

    if (_multiOrbitMode) {
      // Render multiple rings
      for (final ring in _multiOrbitRings) {
        _renderSingleRing(
          canvas,
          ring.radius,
          ring.rotation,
          ring.color,
          ring.opacity * opacity,
        );
      }
    } else {
      // Render single ring
      _renderSingleRing(
        canvas,
        _ringRadius * scale.x,
        _rotation,
        _currentColor,
        opacity,
      );
    }
  }

  void _renderSingleRing(
    Canvas canvas,
    double radius,
    double rotation,
    Color color,
    double ringOpacity,
  ) {
    if (ringOpacity <= 0.01) return;

    final center = Offset.zero;

    if (_rainbowMode) {
      // Render rainbow segments
      _renderRainbowRing(canvas, center, radius, rotation, ringOpacity);
    } else {
      // Render solid color ring with glow
      _renderGlowRing(canvas, center, radius, color, ringOpacity);
      _renderSolidRing(canvas, center, radius, color, ringOpacity);
    }
  }

  void _renderGlowRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double ringOpacity,
  ) {
    final glowPaint = Paint()
      ..color = color.withOpacity(ringOpacity * 0.3 * _glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnchorConfig.ringThickness * 3
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        AnchorConfig.ringGlowRadius,
      );

    canvas.drawCircle(center, radius, glowPaint);
  }

  void _renderSolidRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double ringOpacity,
  ) {
    final ringPaint = Paint()
      ..color = color.withOpacity(ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnchorConfig.ringThickness;

    canvas.drawCircle(center, radius, ringPaint);
  }

  void _renderRainbowRing(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    double ringOpacity,
  ) {
    final segmentCount = AnchorConfig.rainbowSegmentCount;
    final segmentAngle = (math.pi * 2) / segmentCount;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = (i * segmentAngle) + rotation;
      final colorIndex =
          ((i + (_rainbowPhase * segmentCount).floor()) % segmentCount);
      final segmentColor = AnchorConfig.colorsRainbow[
          colorIndex % AnchorConfig.colorsRainbow.length];

      final paint = Paint()
        ..color = segmentColor.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AnchorConfig.ringThickness * 1.5
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          AnchorConfig.ringGlowRadius * 0.5,
        );

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle * 0.9, // Slight gap between segments
        );

      canvas.drawPath(path, paint);
    }
  }

  void _spawnParticle() {
    // Calculate particle position at ring edge
    final angle = _rotation;
    final particlePos = Vector2(
      position.x + math.cos(angle) * _ringRadius * scale.x,
      position.y + math.sin(angle) * _ringRadius * scale.x,
    );

    // Random particle size
    final particleSize = AnchorConfig.particleSizeMin +
        (math.Random().nextDouble() *
            (AnchorConfig.particleSizeMax - AnchorConfig.particleSizeMin));

    final particle = AnchorParticle(
      position: particlePos,
      color: _currentColor,
      maxLifetime: AnchorConfig.particleLifetime,
      size: particleSize,
    );

    parent?.add(particle);
    _particles.add(particle);
  }

  // --- Public control methods ---

  /// Sets the ring color
  void setColor(Color color) {
    _currentColor = color;
  }

  /// Sets the ring radius
  void setRadius(double radius) {
    _ringRadius = radius;
  }

  /// Sets rotation speed (radians per second)
  void setRotationSpeed(double speed) {
    // Rotation speed is now controlled by the controller
    // This method is kept for future flexibility
  }

  /// Enables/disables particle trail
  void setParticlesEnabled(bool enabled) {
    _particlesEnabled = enabled;
    if (!enabled) {
      _clearParticles();
    }
  }

  /// Sets glow intensity (0.0 to 1.0)
  void setGlowIntensity(double intensity) {
    _glowIntensity = intensity.clamp(0.0, 1.0);
  }

  /// Enables multi-orbit mode with specified ring configurations
  void setMultiOrbitMode(bool enabled, {int ringCount = 5}) {
    _multiOrbitMode = enabled;

    if (enabled) {
      _multiOrbitRings.clear();
      for (int i = 0; i < ringCount; i++) {
        final progress = i / (ringCount - 1);
        final radius = AnchorConfig.multiOrbitRadiusMin +
            (progress *
                (AnchorConfig.multiOrbitRadiusMax -
                    AnchorConfig.multiOrbitRadiusMin));

        _multiOrbitRings.add(_OrbitRing(
          radius: radius,
          rotationSpeed: AnchorConfig.rotationSpeedMedium + (i * 0.5),
          color: AnchorConfig.colorPurple,
          opacity: 0.6 + (progress * 0.4),
        ));
      }
    } else {
      _multiOrbitRings.clear();
    }
  }

  /// Enables rainbow shimmer mode for finale
  void setRainbowMode(bool enabled) {
    _rainbowMode = enabled;
    if (enabled) {
      _rainbowPhase = 0.0;
    }
  }

  void _clearParticles() {
    for (final particle in _particles) {
      particle.removeFromParent();
    }
    _particles.clear();
  }

  @override
  void onRemove() {
    _clearParticles();
    super.onRemove();
  }
}

/// Helper class for multi-orbit ring configuration
class _OrbitRing {
  final double radius;
  final double rotationSpeed;
  final Color color;
  final double opacity;
  double rotation = 0.0;

  _OrbitRing({
    required this.radius,
    required this.rotationSpeed,
    required this.color,
    required this.opacity,
  });

  void update(double dt) {
    rotation += dt * rotationSpeed;
  }
}
