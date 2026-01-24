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
  late TextBoxComponent descComp;

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

      // 5. Description (Using TextBoxComponent for auto-wrap)
      descComp = TextBoxComponent(
        text: data!.description,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: GameStyles.cardDescVisibleSize,
            color: GameStyles.cardDesc,
            height: 1.4,
          ),
        ),
        boxConfig: TextBoxConfig(
          // CRITICAL: Clamp width to >= 1.0 to prevent CanvasKit "unsigned long" error during init
          maxWidth: (size.x - (padding * 3)).clamp(1.0, 10000.0),
          growingBox: false,
          timePerChar: 0.0,
        ),
        position: GameLayout.cardDescPosVector,
      );
      add(descComp);
    }

    _updateLayout();
    _updateVisuals();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && data != null) {
      // Update layout completely on resize
      _updateLayout();
    }
  }

  void _updateLayout() {
    // Mockup-based Layout: Left Aligned, Stacked
    final padding = 24.0;
    // CRITICAL: Clamp width to >= 1.0 to prevent CanvasKit "unsigned long" error
    final contentWidth = (size.x - (padding * 2)).clamp(1.0, 10000.0);

    // 1. Icon (Top Left)
    iconComp.anchor = Anchor.topLeft;
    iconComp.position = Vector2(padding, padding);
    // Scale icon slightly up if needed for "Vibrant" look
    // iconComp.scale = Vector2.all(1.2);

    // 2. Title (Below Icon)
    titleComp.anchor = Anchor.topLeft;
    titleComp.position = Vector2(
      padding,
      padding + 60.0,
    ); // 60px gap from top approx

    // 3. Divider (Hidden - not in mockup)
    dividerComp.position = Vector2(-200, -200); // Move offscreen
    dividerComp.size = Vector2.zero();

    // 4. Description (Below Title)
    // Use fixed offset to ensure visibility even if title height is 0 during init
    // Icon (50px) + Gap (10px) + Title (30px) + Gap (10px) -> ~100px from top padding
    // Total Y ~= padding + 100.0

    final descTop = padding + 100.0;
    final bottomPadding = padding;
    // CRITICAL: Clamp height to >= 1.0 to prevent CanvasKit error
    final maxDescHeight = (size.y - descTop - bottomPadding).clamp(1.0, 5000.0);

    descComp.anchor = Anchor.topLeft;
    descComp.position = Vector2(padding, descTop);

    // Explicitly constrain size to prevent overflow
    descComp.size = Vector2(contentWidth, maxDescHeight);

    // Update Text Box BoxConfig
    descComp.boxConfig = TextBoxConfig(
      maxWidth: contentWidth,
      timePerChar: 0.0,
      growingBox: false, // Strict constraint
    );
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
      const Radius.circular(16),
    );
    canvas.clipRRect(rrect);

    // Match testimonial card fill alpha
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(
          alpha: GameStyles.testiFillAlpha * alpha,
        )
        ..style = PaintingStyle.fill,
    );

    // Match testimonial card border with subtle highlight effect
    final borderAlpha = GameStyles.testiBorderAlphaBase * alpha;
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameStyles.testiBorderWidth,
    );
  }
}
