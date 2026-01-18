import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../wrapped_text_component.dart';

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
          fontSize: 14,
          // Increased size
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
      lineComp.opacity = _opacity; // Init correctly
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
