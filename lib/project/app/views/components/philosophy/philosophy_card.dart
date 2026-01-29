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
        anchor: Anchor.center,
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
        anchor: Anchor.center,
      );
      add(titleComp);

      // 4. Divider (Unused)
      dividerComp = RectangleComponent(
        paint: Paint()..color = GameStyles.cardDivider,
      );
      add(dividerComp);

      // 5. Description
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
      // Update layout completely on resize
      _updateLayout();
    }
  }

  @override
  void onHoverEnter() {
    print('PhilosophyCard $index: onHoverEnter (Toggle Flip)');
    _isHovered = true;
    _isFlipped = !_isFlipped; // Toggle State
    game.playTrailCardSound(index); // Play sound on every flip
    game.setCursorPosition(absolutePosition + size / 2);
    game.playHover();
  }

  @override
  void onHoverExit() {
    // print('PhilosophyCard $index: onHoverExit');
    _isHovered = false;
  }

  // Manual Fallback for Hover (Bypasses Event System)
  void manualHoverCheck(Vector2 point) {
    bool isOver = containsPoint(point);
    if (isOver && !_isHovered) {
      onHoverEnter();
    } else if (!isOver && _isHovered) {
      onHoverExit();
    }
  }

  // Robust Hit Test for 3D Transformed Card
  @override
  bool containsPoint(Vector2 point) {
    if (transformMat != null) {
      // Invert the 3D matrix to map the screen point back to local space
      try {
        final inverted = Matrix4.copy(transformMat!)..invert();
        final localPoint = inverted.perspectiveTransform(
          Vector3(point.x, point.y, 0),
        );
        // Check if the local point is within the card's bounds (0,0 -> w,h)
        final result = size.toRect().contains(
          Offset(localPoint.x, localPoint.y),
        );
        // print('Card $index hit test: $result (Loc: $localPoint)'); // Uncomment for spam
        return result;
      } catch (e) {
        // Matrix is singular (e.g. 90 degree turn).
        // If we were already hovering, assume we are still hovering to prevent flickering state.
        return _isHovered;
      }
    }
    return super.containsPoint(point);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Flip Animation Lerp
    final target = _isFlipped ? 1.0 : 0.0;
    if ((target - flipProgress).abs() > 0.01) {
      flipProgress += (target - flipProgress) * dt * 5.0;
    } else {
      flipProgress = target;
    }

    // Toggle Content Visibilty based on flip side
    final isBack = flipProgress > 0.5;
    if (isBack) {
      iconComp.scale = Vector2.zero();
      titleComp.scale = Vector2.zero();

      // Mirror description so it reads correctly when rotated 180
      descComp.scale = Vector2(-1.0, 1.0);
      // Ensure text is full immediately (No Animation)
      descComp.text = data!.description;
    } else {
      // Front Face
      iconComp.scale = Vector2.all(1.0);
      titleComp.scale = Vector2.all(1.0);
      descComp.scale = Vector2.zero();
    }
  }

  void _updateLayout() {
    final padding = 24.0;
    final contentWidth = (size.x - (padding * 2)).clamp(1.0, 10000.0);

    // Center Alignment for Front Face
    // Calculate total height of Icon + Gap + Title
    final iconH = GameStyles.cardIconVisibleSize; // Approx height
    final titleH = GameStyles.cardTitleVisibleSize;
    final gap = 20.0;

    final centerY = size.y / 2;
    // Heuristic centering
    final startY = centerY - (iconH / 2) - (gap / 2) - (titleH / 2);

    // 1. Icon
    iconComp.anchor = Anchor.center;
    iconComp.position = Vector2(size.x / 2, startY);

    // 2. Title
    titleComp.anchor = Anchor.center;
    titleComp.position = Vector2(size.x / 2, startY + iconH + gap);

    dividerComp.size = Vector2.zero(); // Hidden

    // 4. Description (Centered Box)
    descComp.anchor = Anchor.center;
    descComp.position = size / 2;

    final maxDescHeight = (size.y - (padding * 2)).clamp(1.0, 5000.0);
    descComp.size = Vector2(contentWidth, maxDescHeight);

    descComp.boxConfig = TextBoxConfig(
      maxWidth: contentWidth,
      timePerChar: 0.0,
      growingBox: false,
    );
  }

  void _updateVisuals() {
    final alpha = _finalOpacity;

    if (data != null) {
      // Note: Visibility is now largely controlled by update() loop for flip
      // But we still apply Alpha here

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
  void renderTree(Canvas canvas) {
    if (transformMat != null) {
      canvas.save();
      canvas.transform(transformMat!.storage);

      // Render Card Body
      render(canvas);

      // Render Children with Z-Axis Offsets
      // Front Content (Lifted up)
      if (flipProgress <= 0.5) {
        canvas.save();
        canvas.transform(Matrix4.translationValues(0, 0, 10.0).storage); // Z+10
        iconComp.renderTree(canvas);
        titleComp.renderTree(canvas);
        dividerComp.renderTree(canvas);
        canvas.restore();
      }

      // Back Content (Pushed down/back)
      if (flipProgress > 0.5) {
        canvas.save();
        // Z = -10.0 so when flipped 180, it becomes Z = +10.0 (Towards camera)
        canvas.transform(Matrix4.translationValues(0, 0, -10.0).storage);
        descComp.renderTree(canvas);
        canvas.restore();
      }

      canvas.restore();
    } else {
      super.renderTree(canvas);
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
