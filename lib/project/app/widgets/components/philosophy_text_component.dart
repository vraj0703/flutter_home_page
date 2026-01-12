import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' as material;

class PhilosophyTextComponent extends TextComponent implements OpacityProvider {
  double _opacity = 0.0;
  final material.TextStyle _baseStyle;

  PhilosophyTextComponent({
    required String text,
    required material.TextStyle style,
    super.position,
    super.anchor,
  }) : _baseStyle = style,
       super(
         text: text,
         textRenderer: TextPaint(style: style),
       );

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    // Update the TextRenderer to reflect new opacity
    // We recreate the TextPaint with the alpha-adjusted color
    final newColor =
        _baseStyle.color?.withValues(alpha: _opacity) ??
        material.Colors.white.withValues(alpha: _opacity);

    // Efficiently update renderer only if changed?
    // For now, simple reassignment is robust.
    textRenderer = TextPaint(style: _baseStyle.copyWith(color: newColor));
  }
}
