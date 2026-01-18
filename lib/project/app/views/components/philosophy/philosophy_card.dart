import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

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
    // 1. Background
    if (data != null) {
      final padding = GameLayout.cardPadding;

      // 2. Icon (Emoji)
      iconComp = TextComponent(
        text: data!.icon,
        textRenderer: TextPaint(style: GameStyles.philosophyIconStyle),
        position: GameLayout.cardPaddingVector,
      );
      add(iconComp);

      // 3. Title
      titleComp = TextComponent(
        text: data!.title,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: GameStyles.cardTitleVisibleSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        position: GameLayout.cardTitlePosVector,
      );
      add(titleComp);

      // 4. Divider
      dividerComp = RectangleComponent(
        position: GameLayout.cardDividerPosVector,
        size: Vector2(size.x - (padding * 2), 1),
        paint: Paint()..color = GameStyles.cardDivider,
      );
      add(dividerComp);

      // 5. Description
      final wrappedDesc = _wordWrap(
        data!.description,
        GameLayout.cardDescWrapLimit,
      );

      descComp = TextComponent(
        text: wrappedDesc,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: GameStyles.cardDescVisibleSize,
            color: GameStyles.cardDesc,
            height: 1.4,
          ),
        ),
        position: GameLayout.cardDescPosVector,
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
    final alpha = _finalOpacity;

    if (data != null) {
      if (alpha <= 0.01) {
        iconComp.scale = Vector2.zero();
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
          fontSize: GameStyles.cardIconVisibleSize,
          fontFamily: GameStyles.fontModernUrban,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

      titleComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: GameStyles.cardTitleVisibleSize,
          fontWeight: FontWeight.bold,
          color: data!.accentColor.withValues(alpha: alpha),
        ),
      );

      dividerComp.paint.color = GameStyles.cardDivider.withValues(alpha: alpha);

      descComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: GameStyles.cardDescVisibleSize,
          color: GameStyles.cardDesc.withValues(alpha: alpha),
          height: 1.4,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = _finalOpacity;
    if (alpha <= 0.01) return;

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(20),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = GameStyles.cardFill.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = GameStyles.cardStroke.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawShadow(
      Path()..addRRect(rrect),
      GameStyles.cardShadow,
      15.0,
      true,
    );
  }
}
