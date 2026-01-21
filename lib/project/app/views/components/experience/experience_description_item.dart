import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/views/components/wrapped_text_component.dart';

class ExperienceDescriptionItem extends PositionComponent with HasPaint {
  final List<String> description;
  final List<WrappedTextComponent> _lines = [];
  double _opacity = 0.0;

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
    double currentY = 0;
    const double maxWidth = GameLayout.expDescMaxWidth;

    for (final text in description) {
      final textSpan = TextSpan(
        text: "${GameStrings.bullet}  $text",
        style: GameStyles.experienceDescStyle,
      );

      final painter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      final lineComp = WrappedTextComponent(painter, maxWidth);
      lineComp.opacity = _opacity;
      lineComp.position = Vector2(0, currentY);
      add(lineComp);
      _lines.add(lineComp);

      currentY += painter.height + 12;
    }

    final offset = -currentY / 2;
    for (final child in children) {
      if (child is PositionComponent) {
        child.position.y += offset;
      }
    }
  }
}
