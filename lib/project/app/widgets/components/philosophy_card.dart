import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

class PhilosophyCard extends PositionComponent
    with HasPaint, HasGameReference<MyGame>
    implements OpacityProvider {
  final PhilosophyCardData? data;
  final int index;
  final int totalCards;

  double _scrollOpacity = 0.0;
  double _parentOpacity = 0.0;

  @override
  double get opacity => _scrollOpacity;

  @override
  set opacity(double value) {
    _scrollOpacity = value;
    if (isLoaded) _updateVisuals();
  }

  set parentOpacity(double value) {
    _parentOpacity = value;
    if (isLoaded) _updateVisuals();
  }

  double get _finalOpacity => _scrollOpacity * _parentOpacity;

  late RectangleComponent bgComp;
  late TextComponent iconComp;
  late TextComponent titleComp;
  late RectangleComponent dividerComp;
  late TextComponent descComp;

  PhilosophyCard({
    required this.data,
    required this.index,
    required this.totalCards,
  });

  @override
  Future<void> onLoad() async {
    // 1. Background (Glassmorphism handled in render, but we can add a simple dark overlay)
    // Actually render() does the heavy lifting for the glass look.

    if (data != null) {
      final padding = 32.0;

      // 2. Icon (Emoji)
      iconComp = TextComponent(
        text: data!.icon,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 48, // Large Emoji
            fontFamily: 'ModrntUrban', // Fallback
          ),
        ),
        position: Vector2(padding, padding),
      );
      add(iconComp);

      // 3. Title
      titleComp = TextComponent(
        text: data!.title,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: 'ModrntUrban',
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        position: Vector2(padding, padding + 60),
      );
      add(titleComp);

      // 4. Divider
      dividerComp = RectangleComponent(
        position: Vector2(padding, padding + 60 + 32),
        size: Vector2(size.x - (padding * 2), 1),
        paint: Paint()..color = Colors.white.withValues(alpha: 0.2),
      );
      add(dividerComp);

      // 5. Description (Using TextComponent with manual wrap to avoid TextBoxComponent issues)
      final wrappedDesc = _wordWrap(
        data!.description,
        80,
      ); // Approx 45 chars per line for 500px width

      descComp = TextComponent(
        text: wrappedDesc,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: 'ModrntUrban',
            fontSize: 32,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        position: Vector2(padding, padding + 60 + 32 + 20),
      );
      add(descComp);
    }

    _updateVisuals();
  }

  String _wordWrap(String text, int lineCharLimit) {
    final words = text.split(' ');
    final buffer = StringBuffer();
    int currentLineLength = 0;

    for (var word in words) {
      if (currentLineLength + word.length > lineCharLimit) {
        buffer.write('\n$word');
        currentLineLength = word.length;
      } else {
        if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
          buffer.write(' ');
          currentLineLength++;
        }
        buffer.write(word);
        currentLineLength += word.length;
      }
    }
    return buffer.toString();
  }

  void _updateVisuals() {
    // Check removed to allow onLoad usage
    final alpha = _finalOpacity;

    if (data != null) {
      // Toggle visibility to avoid unnecessary rendering calls if invisible
      if (alpha <= 0.01) {
        iconComp.scale = Vector2.zero(); // effectively hide
        titleComp.scale = Vector2.zero();
        dividerComp.scale = Vector2.zero();
        descComp.scale = Vector2.zero();
      } else {
        iconComp.scale = Vector2.all(1.0);
        titleComp.scale = Vector2.all(1.0);
        dividerComp.scale = Vector2.all(1.0);
        descComp.scale = Vector2.all(1.0);
      }

      iconComp.textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 42,
          fontFamily: 'ModrntUrban',
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

      titleComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: data!.accentColor.withValues(alpha: alpha),
        ),
      );

      dividerComp.paint.color = Colors.white.withValues(alpha: 0.2 * alpha);

      descComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.8 * alpha),
          height: 1.4,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = _finalOpacity;
    if (alpha <= 0.01) return;

    // --- GLASSMORPHISM CARD STYLE ---
    // Matches Project Card: Radius 20, White 5% Fill, White 20% Stroke

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(20),
    );

    // Fill: White 5%
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05 * alpha)
        ..style = PaintingStyle.fill,
    );
    // Stroke: White 20%
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Slight Shadow for depth
    canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 15.0, true);
  }
}
