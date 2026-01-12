import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class VisionComponent extends PositionComponent
    with HasGameReference, HasPaint
    implements OpacityProvider {
  late TextComponent title;
  late TextComponent headline;
  late TextBoxComponent body;

  // OpacityProvider
  double _opacity = 1.0;
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    _opacity = value;
    // We could pass this down to children paints if needed,
    // but standard render implementation checks opacity now?
    // HasPaint provides 'paint', checking alpha?
    // Actually PositionComponent with HasPaint usually uses the paint for the component itself (e.g. rect).
    // Children need to be updated manualy or via a recursive effect if we want them to fade.
    // For now, let's update the text renderers like in GridCard for best results.

    _updateOpacity(value);
  }

  @override
  Future<void> onLoad() async {
    // Determine size based on content
    // Layout:
    // Left: "PHILOSOPHY"
    // Right: Headline + Body

    final margin = 60.0;
    final width = game.size.x;

    // 1. Label
    title = TextComponent(
      text: "PHILOSOPHY",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Broadway',
          color: Color(0xFFC78E53), // Gold color
          fontSize: 14,
          letterSpacing: 4.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(margin, 0),
    );
    add(title);

    // 2. Headline
    headline = TextComponent(
      text: "Code is Craft",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.bold,
          fontFamily: 'Broadway',
        ),
      ),
      position: Vector2(margin, 40),
    );
    add(headline);

    // 3. Body
    body = TextBoxComponent(
      text:
          "I view coding as both an intellectual and creative pursuit.\nI enjoy reading code deeply, recognizing patterns, and treating structure like a well-played game of Tetris.\n\nQuality over Haste. Eliminate, Simplify, Strengthen.",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          height: 1.5,
          fontFamily: 'ModrntUrban',
        ),
      ),
      boxConfig: TextBoxConfig(maxWidth: 600, timePerChar: 0.05),
      position: Vector2(margin, 140),
      size: Vector2(600, 300),
    );
    add(body);

    // Set size of this component
    size = Vector2(width, 500); // Approximate height needed
    _opacity = 0; // Start hidden
  }

  void _updateOpacity(double alpha) {
    if (!isLoaded) return;
    // Optimization: Only if needed.
    // Title
    final titleColor = const Color(0xFFC78E53);
    title.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: titleColor.withValues(alpha: alpha),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    // Headline
    headline.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: Colors.white.withValues(alpha: alpha),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    // Body
    final bodyColor = Colors.white70;
    body.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: bodyColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
