import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class SectionProgressIndicator extends PositionComponent with HasPaint, TapCallbacks {
  static const int totalSections = 6;
  static const double dotSize = 8.0;
  static const double dotSpacing = 20.0;
  static const double hitAreaRadius = 15.0; // Larger tap area
  static const double dropletSize = 12.0; // Water droplet size
  static const Color inactiveColor = Color(0x40FFFFFF); // White 25%
  static const Color activeColor = Color(0xFFFFC107); // Gold
  static const Color dropletColor = Color(0xFFFFD700); // Bright gold droplet

  // Spring physics parameters
  static const double snapThreshold = 0.3; // Distance to trigger snap to dot
  static const double springStiffness = 180.0; // Base spring strength
  static const double springDamping = 12.0; // Base damping
  static const double snapStiffness = 250.0; // Stronger for snapping
  static const double snapDamping = 15.0; // More damped for quick settle

  double _targetProgress = 0.0; // Target position from scroll
  double _currentProgress = 0.0; // Spring-animated actual position
  double _progressVelocity = 0.0; // Spring velocity
  double _velocityDecay = 0.0; // Smooth velocity decay for visuals

  final Paint _inactivePaint = Paint()..color = inactiveColor;
  final Paint _activePaint = Paint()..color = activeColor;
  final Paint _dropletPaint = Paint()
    ..color = dropletColor
    ..style = PaintingStyle.fill;

  // Callback when a section is tapped
  void Function(int section)? onSectionTap;

  SectionProgressIndicator({this.onSectionTap}) {
    anchor = Anchor.topRight;
  }

  // Update with continuous scroll progress instead of discrete section
  void updateScrollProgress(double progress) {
    _targetProgress = progress.clamp(0.0, totalSections - 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if we should snap to a dot (magnetic effect)
    double snapTarget = _targetProgress;
    bool isSnapping = false;

    for (int i = 0; i < totalSections; i++) {
      final distanceToDot = (_targetProgress - i).abs();
      if (distanceToDot < snapThreshold) {
        snapTarget = i.toDouble();
        isSnapping = true;
        break;
      }
    }

    // Use different spring parameters for snapping (stronger, more damped)
    final stiffness = isSnapping ? snapStiffness : springStiffness;
    final damping = isSnapping ? snapDamping : springDamping;

    // Spring physics simulation
    final displacement = snapTarget - _currentProgress;
    final springForce = stiffness * displacement;
    final dampingForce = damping * _progressVelocity;
    final acceleration = springForce - dampingForce;

    _progressVelocity += acceleration * dt;
    _currentProgress += _progressVelocity * dt;

    // Update squash/stretch velocity from spring velocity for visual deformation
    _velocityDecay = _velocityDecay * 0.85 + _progressVelocity * 0.15;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final totalHeight = (totalSections - 1) * dotSpacing;

    // Draw all dots
    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final center = Offset(0, y);

      // Calculate proximity to spring-animated position
      final distanceFromProgress = (_currentProgress - i).abs();

      // Dots closer to current position are more active
      if (distanceFromProgress < 0.5) {
        final proximity = 1.0 - (distanceFromProgress / 0.5);
        final color = Color.lerp(inactiveColor, activeColor, proximity)!;
        final paint = Paint()..color = color;
        canvas.drawCircle(center, dotSize / 2, paint);
      } else {
        // Inactive dots
        canvas.drawCircle(center, dotSize / 2, _inactivePaint);
      }
    }

    // Draw water droplet at spring-animated position
    final dropletY = (_currentProgress * dotSpacing) - (totalHeight / 2);
    final dropletCenter = Offset(0, dropletY);

    // Velocity-based squash/stretch (scroll-controlled deformation)
    final velocityMagnitude = _velocityDecay.abs().clamp(0.0, 0.5);
    final stretchFactor = 1.0 + (velocityMagnitude * 3.0); // Vertical stretch when moving
    final squeezeFactor = 1.0 - (velocityMagnitude * 0.5); // Horizontal compression when moving

    final dropletWidth = dropletSize * squeezeFactor;
    final dropletHeight = dropletSize * stretchFactor;

    // Draw droplet glow (outer) - oval shape when moving
    final glowPaint = Paint()
      ..color = dropletColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final glowRect = Rect.fromCenter(
      center: dropletCenter,
      width: dropletWidth + 6,
      height: dropletHeight + 6,
    );
    canvas.drawOval(glowRect, glowPaint);

    // Draw droplet core - oval shape when moving
    final coreRect = Rect.fromCenter(
      center: dropletCenter,
      width: dropletWidth,
      height: dropletHeight,
    );
    canvas.drawOval(coreRect, _dropletPaint);

    // Draw highlight on droplet (water effect)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6);
    final highlightOffset = Offset(-dropletWidth * 0.15, -dropletHeight * 0.15);
    final highlightRect = Rect.fromCenter(
      center: dropletCenter + highlightOffset,
      width: dropletWidth * 0.25,
      height: dropletHeight * 0.25,
    );
    canvas.drawOval(highlightRect, highlightPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Convert tap position to local coordinates
    final localPos = event.localPosition;

    // Calculate which dot was tapped
    final totalHeight = (totalSections - 1) * dotSpacing;

    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final dotCenter = Vector2(0, y);

      // Check if tap is within hit area of this dot
      final distance = (localPos - dotCenter).length;
      if (distance <= hitAreaRadius) {
        // Notify callback
        onSectionTap?.call(i);
        break;
      }
    }
  }
}
