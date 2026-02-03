import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector2, Colors;

class PhilosophyCard extends PositionComponent
    with HasPaint, HasGameReference<MyGame>
    implements OpacityProvider {
  final PhilosophyCardData? data;
  final int index;
  final int totalCards;

  double _scrollOpacity = 0.0;
  double _parentOpacity = 0.0;

  // Flip Logic
  bool _isHovered = false;
  bool _isFlipped = false;
  double flipProgress = 0.0;

  // Idle animation tracker
  double _idleTime = 0.0;
  Vector2? _lockedPosition; // Store position when locked for idle animation

  Matrix4? transformMat;
  Matrix4? hitboxMatrix;

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
        priority: -10,
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
          maxWidth: (size.x - 32.0).clamp(
            1.0,
            10000.0,
          ), // 16px padding on each side
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

  bool canFlip = false;

  bool get isFlipped => _isFlipped;

  void forceResetFlip() {
    _isFlipped = false;
  }

  void onHoverEnter() {
    if (!canFlip) return;
    _isHovered = true;
    _isFlipped = true;
    //game.audio.playTrailCardSound(index);
    game.audio.playHover();
  }

  void onHoverExit() {
    _isHovered = false;
    _isFlipped = false;
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
    final matrix = hitboxMatrix ?? transformMat;
    if (matrix != null) {
      try {
        final inverted = Matrix4.copy(matrix)..invert();
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

    const duration = 0.8; // Extended from 0.7s to 0.8s
    final oldProgress = flipProgress;

    if (_isFlipped) {
      flipProgress = (flipProgress + dt / duration).clamp(0.0, 1.0);
    } else {
      flipProgress = (flipProgress - dt / duration).clamp(0.0, 1.0);
    }

    // Scale variation during flip for tactile feel
    double flipScale;
    if (flipProgress < 0.5) {
      // Phase 1: Scale DOWN to 0.95 as we rotate to 90°
      flipScale = 1.0 - (flipProgress * 2.0) * 0.05; // 1.0 → 0.95
    } else {
      // Phase 2: Scale UP to 1.05, then settle to 1.0
      final settleProgress = (flipProgress - 0.5) * 2.0;
      if (settleProgress < 0.5) {
        flipScale = 0.95 + (settleProgress * 2.0) * 0.1; // 0.95 → 1.05
      } else {
        final finalProgress = (settleProgress - 0.5) * 2.0;
        flipScale = 1.05 - (finalProgress * 0.05); // 1.05 → 1.0
      }
    }
    scale = Vector2.all(flipScale);

    // Trigger whoosh sound at flip peak (90°)
    if ((oldProgress < 0.5 && flipProgress >= 0.5) ||
        (oldProgress > 0.5 && flipProgress <= 0.5)) {
      game.audio.playTrailCardSound(index);
    }

    // Idle animations when locked (opacity = 1.0 and canFlip = true)
    if (opacity >= 0.99 && canFlip) {
      _idleTime += dt;

      // Store locked position on first frame
      _lockedPosition ??= position.clone();

      // Unique idle behavior per card index
      switch (index) {
        case 0: // Crystal - Gentle rotate
          angle = sin(_idleTime * 0.5) * 0.035; // ±2° over 4s
          break;
        case 1: // Chalice - Vertical bob
          if (_lockedPosition != null) {
            position.y =
                _lockedPosition!.y + sin(_idleTime * 0.7) * 5.0; // ±5px over 3s
          }
          break;
        case 2: // Sword - Sharp micro-tilt
          angle = sin(_idleTime * 2.0) * 0.01; // ±0.6° sharp edge
          break;
        case 3: // Book - Icon flutter (scale icon slightly)
          if (iconComp.isLoaded && iconComp.scale.x > 0) {
            final flutter = 1.0 + sin(_idleTime * 1.5) * 0.03; // ±3% over 2s
            iconComp.scale = Vector2.all(flutter);
          }
          break;
      }
    } else {
      // Reset idle state when scrolling away
      _idleTime = 0.0;
      _lockedPosition = null;
      angle = 0.0;
      if (index == 3 && iconComp.isLoaded && iconComp.scale.x != 1.0) {
        iconComp.scale = Vector2.all(1.0);
      }
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
    final isReflectionPass = canvas is ui.PictureRecorder;

    if (transformMat != null) {
      canvas.save();
      canvas.transform(transformMat!.storage);

      // Always render the card background (border and glass effect)
      render(canvas);

      // Skip the back of the card in the reflection to save GPU cycles
      if (flipProgress < 0.5) {
        // Front side: Show icon and title
        // Icon: Same plane as card background (Z=0)
        iconComp.renderTree(canvas);

        // Title: Higher Priority (Lifted off card) -> Z = +30
        if (!isReflectionPass) {
          canvas.save();
          canvas.transform(Matrix4.translationValues(0, 0, 30.0).storage);
          titleComp.renderTree(canvas);
          canvas.restore();
        }

        // Divider: Standard Plane (Z=0)
        // dividerComp.renderTree(canvas); // Hidden in layout anyway, but safe to skip
      } else if (!isReflectionPass) {
        // Back side: Show description
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
    final style = TextStyle(
      fontFamily: GameStyles.fontModernUrban,
      fontSize: GameStyles.cardDescVisibleSize,
      color: GameStyles.cardDesc,
      height: 1.4,
    );

    // Mirror logic
    final textAlign = isLeftSide ? TextAlign.left : TextAlign.right;
    // Fill parent with 16.0 padding (16 left + 16 right = 32)
    final descWidth = size.x - 16.0;

    final textPainter = TextPainter(
      text: TextSpan(text: data?.description ?? '', style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    textPainter.layout(maxWidth: descWidth);
    final descHeight = textPainter.height;

    // Position Description at CENTER
    descComp.size = Vector2(descWidth, descHeight + 10);
    descComp.position = size / 2; // Back to center
    descComp.anchor = Anchor.center;
    descComp.align = isLeftSide ? Anchor.centerLeft : Anchor.centerRight;

    // Critical: Update boxConfig so text wraps at the new width
    descComp.boxConfig = TextBoxConfig(
      maxWidth: descWidth,
      timePerChar: 0.0,
      growingBox: false,
      margins: EdgeInsets.zero,
    );

    if (isLeftSide) {
      // Icon: Top-Right
      iconComp.position = Vector2(size.x - padding, padding);
      iconComp.anchor = Anchor.topRight;

      // Title: Bottom-Left (Fixed at bottom)
      titleComp.position = Vector2(padding, size.y - padding);
      titleComp.anchor = Anchor.bottomLeft;
    } else {
      // Icon: Top-Left (Mirrored)
      iconComp.position = Vector2(padding, padding);
      iconComp.anchor = Anchor.topLeft;

      // Title: Bottom-Right (Fixed at bottom)
      titleComp.position = Vector2(size.x - padding, size.y - padding);
      titleComp.anchor = Anchor.bottomRight;
    }

    dividerComp.size = Vector2.zero();
  }

  void _updateVisuals() {
    final alpha = _finalOpacity;

    if (data != null) {
      iconComp.paint.color = Colors.white.withValues(alpha: 1 * alpha);
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

    // Technical "Crop Marks" (Corner Brackets)
    final borderAlpha = GameStyles.testiBorderAlphaBase * alpha;
    final cornerLength = 20.0;
    final strokeWidth = 2.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Top-Left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.x, 0), Offset(size.x - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.x, 0), Offset(size.x, cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(
      Offset(size.x, size.y),
      Offset(size.x - cornerLength, size.y),
      paint,
    );
    canvas.drawLine(
      Offset(size.x, size.y),
      Offset(size.x, size.y - cornerLength),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(Offset(0, size.y), Offset(cornerLength, size.y), paint);
    canvas.drawLine(Offset(0, size.y), Offset(0, size.y - cornerLength), paint);
  }
}
