import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';

class ExperienceDetailsComponent extends PositionComponent with HasPaint {
  final List<ExperienceNode> data;
  final List<ExperienceDescriptionItem> _items = [];

  // Configuration
  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.0;
  static const double activeScale = 1.15; // Slightly larger for focus
  static const double inactiveScale = 0.65; // Smaller for depth
  static const double spacing = pi / 4; // Matches Satellite spacing

  double _parentOpacity = 1.0;

  ExperienceDetailsComponent({required this.data, super.position});

  @override
  set opacity(double val) {
    if (super.opacity == val) return;
    super.opacity = val;
    _parentOpacity = val;
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < data.length; i++) {
      final item = ExperienceDescriptionItem(description: data[i].description);
      _items.add(item);
      add(item);
    }
  }

  void updateRotation(double systemRotation) {
    // Shared center with Satellites: (0, height/2)
    final center = Vector2(0, size.y / 2);

    // Radius matches the "Middle Arc" (~80% of screen height)
    final orbitRadius = size.y * 1;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      // Match Satellite spacing logic
      // Satellites use: baseAngle = i * spacing
      // We want index 0 to be at Angle 0 (Right) when rot=0.
      final baseAngle = i * spacing;

      final currentAngle = baseAngle + systemRotation;

      // Position
      final x = center.x + orbitRadius * cos(currentAngle);
      final y = center.y + orbitRadius * sin(currentAngle);

      item.position = Vector2(x, y);
      item.angle = currentAngle; // Align text tangentially to the arc

      // Opacity / Visibility Logic
      // Active zone is around 0 (Right)
      double diff = currentAngle;
      // Normalize to -pi..pi
      while (diff > pi) {
        diff -= 2 * pi;
      }
      while (diff < -pi) {
        diff += 2 * pi;
      }

      final dist = diff.abs();

      // Tighter threshold for text overlap avoidance (Spotlight effect)
      const threshold = 0.4;

      if (dist < threshold) {
        final t = 1.0 - (dist / threshold);
        // Smooth fade combined with parent opacity
        item.opacity = t * _parentOpacity;
        item.scale = Vector2.all(
          inactiveScale + (activeScale - inactiveScale) * t,
        );
      } else {
        item.opacity = 0.0;
      }
    }
  }
}

class ExperienceDescriptionItem extends PositionComponent with HasPaint {
  final List<String> description;
  final List<WrappedTextComponent> _lines = [];
  double _opacity = 0.0; // Start hidden

  ExperienceDescriptionItem({required this.description});

  @override
  set opacity(double val) {
    if (_opacity == val) return;
    _opacity = val;
    for (final line in _lines) {
      line.opacity = val;
    }
  }

  @override
  double get opacity => _opacity;

  @override
  Future<void> onLoad() async {
    // Create static layout of text
    // No animations, just the content
    double currentY = 0;
    const double maxWidth = 450;

    for (final text in description) {
      final textSpan = TextSpan(
        text: "•  $text",
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14, // Increased size
          color: Colors.white,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      );

      final painter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      final lineComp = WrappedTextComponent(painter, maxWidth);
      lineComp.position = Vector2(0, currentY); // Temp Y
      add(lineComp);
      _lines.add(lineComp);

      currentY += painter.height + 12;
    }

    // Center the content vertically around the pivot point
    final offset = -currentY / 2;
    for (final child in children) {
      if (child is PositionComponent) {
        child.position.y += offset;
      }
    }
  }
}

class WrappedTextComponent extends PositionComponent with HasPaint {
  final TextPainter painter;
  final double maxWidth;

  WrappedTextComponent(this.painter, this.maxWidth);

  @override
  void render(Canvas canvas) {
    // Parent opacity is applied via global opacity (render tree?)
    // Flame applies opacity to paint if we mix HasPaint?
    // Actually PositionComponent checks opacity, but we need to apply it to the painter.

    // We need to apply the opacity to the text style color
    // But rebuilding painter is expensive?
    // We can use saveLayer with alpha?
    // Or just re-paint.

    if (opacity <= 0.01) return;

    // Quick hack for opacity:
    // If we use saveLayer, we can apply alpha composite.
    // Or we assume standard paint opacity works if we don't override render?
    // TextPainter.paint takes offset. It draws strictly with the Span's color.
    // We must modify color or use layer.

    // Let's use layer for simplicity of generic opacity support

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, maxWidth, painter.height),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
