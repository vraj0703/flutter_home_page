import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector2, Colors;

class PhilosophyCard extends PositionComponent
    with HasPaint, HasGameReference<MyGame>, HoverCallbacks
    implements OpacityProvider {
  final PhilosophyCardData? data;
  final int index;
  final int totalCards;

  double _scrollOpacity = 0.0;
  double _parentOpacity = 0.0;

  // Flip Logic
  bool _isHovered = false; // Tracks actual mouse presence for edge detection
  bool _isFlipped = false; // Tracks visual state (Toggle)
  double flipProgress = 0.0; // 0.0 (Front) -> 1.0 (Back)

  // 3D Transform Matrix (Overrides standard 2D transform if set)
  Matrix4? transformMat;

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

  // late TextComponent indexComp; // Removed as per feedback
  late SpriteComponent iconComp;
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
    if (data != null) {
      final padding = GameLayout.cardPadding;
      final iconPaths = [
        'ic_crystal.png',
        'ic_chalice.png',
        'ic_sword.png',
        'ic_book.png',
      ];
      final iconPath = iconPaths[index % iconPaths.length];

      iconComp = SpriteComponent(
        sprite: await game.loadSprite(iconPath),
        size: Vector2.all(120.0),
        anchor: Anchor.topRight,
      );
      add(iconComp);

      titleComp = TextComponent(
        text: data!.title,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        anchor: Anchor.bottomLeft,
      );
      add(titleComp);

      dividerComp = RectangleComponent(
        paint: Paint()..color = GameStyles.cardDivider,
      );
      add(dividerComp);

      descComp = TextBoxComponent(
        text: '',
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: GameStyles.cardDescVisibleSize,
            color: GameStyles.cardDesc,
            height: 1.4,
          ),
        ),
        boxConfig: TextBoxConfig(
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
      _updateLayout();
    }
  }

  // Interaction Guard
  bool canFlip = false;

  bool get isFlipped => _isFlipped;

  void forceResetFlip() {
    _isFlipped = false;
  }

  @override
  void onHoverEnter() {
    if (!canFlip) return;
    _isHovered = true;
    _isFlipped = !_isFlipped;
    game.playTrailCardSound(index);
    game.playHover();
  }

  @override
  void onHoverExit() {
    _isHovered = false;
  }

  void manualHoverCheck(Vector2 point) {
    if (!canFlip) return;
    bool isOver = containsPoint(point);
    if (isOver && !_isHovered) {
      onHoverEnter();
    } else if (!isOver && _isHovered) {
      onHoverExit();
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    if (transformMat != null) {
      try {
        final inverted = Matrix4.copy(transformMat!)..invert();
        final localPoint = inverted.perspectiveTransform(
          Vector3(point.x, point.y, 0),
        );
        final result = size.toRect().contains(
          Offset(localPoint.x, localPoint.y),
        );
        return result;
      } catch (e) {
        return _isHovered;
      }
    }
    return super.containsPoint(point);
  }

  @override
  void update(double dt) {
    super.update(dt);

    const duration = 0.7;

    if (_isFlipped) {
      flipProgress = (flipProgress + dt / duration).clamp(0.0, 1.0);
    } else {
      flipProgress = (flipProgress - dt / duration).clamp(0.0, 1.0);
    }

    final isBack = flipProgress > 0.5;
    if (isBack) {
      iconComp.scale = Vector2.zero();
      titleComp.scale = Vector2.zero();
      // Use Scale -1 to flip text back to normal (un-mirror)
      descComp.scale = Vector2(-1.0, 1.0);
      descComp.text = data!.description;
    } else {
      iconComp.scale = Vector2.all(1.0);
      titleComp.scale = Vector2.all(1.0);
      descComp.scale = Vector2.zero();
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (transformMat != null) {
      canvas.save();
      canvas.transform(transformMat!.storage);

      // Render Card Body
      render(canvas);

      // Calculate Physics Curve
      final curvedProgress = Curves.easeInOut.transform(flipProgress);

      // Pivot for alignment
      final pivot = Vector2(size.x / 2, size.y / 2);

      // React Physics: Flattened Z-Lift (Scale 0.93)
      final popMatrix = Matrix4.identity()
        ..translateByVector3(Vector3(pivot.x, pivot.y, 0))
        ..scaleByVector3(Vector3(0.93, 0.93, 1.0))
        ..translateByVector3(Vector3(-pivot.x, -pivot.y, 0));

      canvas.transform(popMatrix.storage);

      if (curvedProgress <= 0.5) {
        // Front Content
        iconComp.renderTree(canvas);
        titleComp.renderTree(canvas);
        dividerComp.renderTree(canvas);
      } else {
        // Back Content
        // descComp has scale(-1, 1) set in update(), so it un-mirrors itself.
        descComp.renderTree(canvas);
      }

      canvas.restore();
    } else {
      super.renderTree(canvas);
    }
  }

  void _updateLayout() {
    final padding = 32.0;
    final bool isLeftSide = index < 2;

    if (isLeftSide) {
      iconComp.position = Vector2(size.x - padding + 20, padding - 10);
      iconComp.anchor = Anchor.topRight;

      titleComp.position = Vector2(padding, size.y - padding);
      titleComp.anchor = Anchor.bottomLeft;
    } else {
      iconComp.position = Vector2(padding - 20, padding - 10);
      iconComp.anchor = Anchor.topLeft;
      titleComp.position = Vector2(size.x - padding, size.y - padding);
      titleComp.anchor = Anchor.bottomRight;
    }

    dividerComp.size = Vector2.zero(); // Hidden
    final style = TextStyle(
      fontFamily: GameStyles.fontModernUrban,
      fontSize: GameStyles.cardDescVisibleSize,
      color: GameStyles.cardDesc,
      height: 1.4,
    );
    final textAlign = isLeftSide ? TextAlign.left : TextAlign.right;

    final textPainter = TextPainter(
      text: TextSpan(text: data?.description ?? '', style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    // Safe content width for description to avoid overflow
    final descWidth =
        size.x - (padding * 2.5); // Reduced safety padding (Decrease margin)

    textPainter.layout(maxWidth: descWidth);
    final textHeight = textPainter.height;

    descComp.anchor = Anchor.center;
    descComp.position = size / 2;
    descComp.align = isLeftSide ? Anchor.centerLeft : Anchor.centerRight;
    descComp.size = Vector2(descWidth, textHeight + 10.0); // +10 buffer

    descComp.boxConfig = TextBoxConfig(
      maxWidth: descWidth,
      timePerChar: 0.0,
      growingBox: false,
      margins: EdgeInsets.zero,
    );
  }

  void _updateVisuals() {
    final alpha = _finalOpacity;

    if (data != null) {
      iconComp.paint.color = Colors.white.withValues(alpha: 0.15 * alpha);
      titleComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: alpha),
          height: 1.1,
        ),
      );

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
    canvas.drawRRect(
      rrect.shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(
          alpha: GameStyles.testiFillAlpha * alpha,
        )
        ..style = PaintingStyle.fill,
    );

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
