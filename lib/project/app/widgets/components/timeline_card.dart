import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/components/experience_data.dart';

class TimelineCard extends PositionComponent with HasPaint {
  final ExperienceData data;
  late TextComponent _roleText;
  late TextComponent _companyText;
  late TextBoxComponent _descText;

  TimelineCard({required this.data, super.position, super.size});

  @override
  Future<void> onLoad() async {
    // 1. Role (Title)
    _roleText = TextComponent(
      text: data.role.toUpperCase(),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'ModrntUrban',
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Color(0xFFE3E4E5),
        ),
      ),
      position: Vector2(20, 20),
    );
    add(_roleText);

    // 2. Company & Year
    _companyText = TextComponent(
      text: "${data.company} | ${data.year}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'ModrntUrban',
          fontWeight: FontWeight.w400,
          color: Color(0xFFC78E53), // Gold accent
        ),
      ),
      position: Vector2(20, 55),
    );
    add(_companyText);

    // 3. Description (Wrapped)
    _descText = TextBoxComponent(
      text: data.description,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'ModrntUrban',
          color: Color(0xCCFFFFFF),
        ),
      ),
      boxConfig: TextBoxConfig(maxWidth: size.x - 40, growingBox: true),
      position: Vector2(20, 90),
      size: Vector2(size.x - 40, size.y - 100),
    );
    add(_descText);
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    final rRect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(16),
    );

    // Glass background
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.03 * opacity)
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.1 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  set opacity(double value) {
    super.opacity = value;
    if (!isLoaded) return;
    _updateTextAlpha(_roleText, const Color(0xFFE3E4E5), value);
    _updateTextAlpha(_companyText, const Color(0xFFC78E53), value);
    _updateTextAlpha(_descText, const Color(0xCCFFFFFF), value);
  }

  void _updateTextAlpha(
    TextComponent component,
    Color base,
    double funcOpacity,
  ) {
    final style = (component.textRenderer as TextPaint).style;
    component.textRenderer = TextPaint(
      style: style.copyWith(
        color: base.withValues(alpha: base.a * funcOpacity),
      ),
    );
  }
}
