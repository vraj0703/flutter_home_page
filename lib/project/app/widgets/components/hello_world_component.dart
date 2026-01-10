import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

class HelloWorldComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint
    implements OpacityProvider {
  late TextComponent title;
  late TextComponent subtitle;
  late GlobeGraphic globe;

  double _opacity = 1.0;
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    _opacity = value;
    _updateOpacity(value);
  }

  @override
  Future<void> onLoad() async {
    // Globe Graphic
    globe = GlobeGraphic(position: size / 2, radius: 200);
    add(globe);

    // Text Overlay
    title = TextComponent(
      text: "Hello from",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC78E53),
          fontSize: 24,
          letterSpacing: 1.5,
          fontFamily: 'ModrntUrban',
        ),
      ),
      anchor: Anchor.center,
      position: size / 2 - Vector2(0, 50),
    );
    add(title);

    subtitle = TextComponent(
      text: "Lucknow, India",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFamily: 'Broadway',
          letterSpacing: 2.0,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, 20),
    );
    add(subtitle);

    priority = 10;
    _opacity = 0;
  }

  void _updateOpacity(double alpha) {
    if (!isLoaded) return;

    // Update Globe
    globe.opacity = alpha;

    // Update Text
    final titleColor = const Color(0xFFC78E53);
    title.textRenderer =  TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color:titleColor.withOpacity(alpha),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    subtitle.textRenderer =  TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: Colors.white.withOpacity(alpha),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Recenter instructions if needed, but since we use size/2 in onLoad,
    // we might want to update positions here if size changes significantly.
    if (isLoaded) {
      globe.position = size / 2;
      title.position = size / 2 - Vector2(0, 50);
      subtitle.position = size / 2 + Vector2(0, 20);
    }
  }
}

class GlobeGraphic extends PositionComponent {
  final double radius;
  double _rotation = 0;
  double _opacity = 1.0;

  set opacity(double value) => _opacity = value;

  GlobeGraphic({required Vector2 position, required this.radius})
    : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _rotation += dt * 0.5;
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 * _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw Latitudes
    for (int i = 0; i < 5; i++) {
      // Circle Outline
      canvas.drawCircle(Offset.zero, radius, paint);

      // Inner Ellipse
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2,
        height: radius * 0.6,
      );
      canvas.drawOval(rect, paint);

      // Rotated Ellipses
      canvas.save();
      canvas.rotate(pi / 4);
      canvas.drawOval(rect, paint);
      canvas.restore();

      canvas.save();
      canvas.rotate(-pi / 4);
      canvas.drawOval(rect, paint);
      canvas.restore();
    }

    // Rotating Dot
    final dotX = radius * cos(_rotation);
    final dotY = (radius * 0.6) * sin(_rotation);

    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()..color = const Color(0xFFC78E53).withOpacity(_opacity),
    );
  }
}
