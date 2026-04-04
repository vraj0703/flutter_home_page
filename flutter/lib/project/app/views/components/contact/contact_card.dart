import 'dart:math';
import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/contact_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector2, Colors;
import 'package:web/web.dart' as web;

class ContactCard extends PositionComponent
    with HasPaint, HasGameReference<MyGame>, TapCallbacks
    implements OpacityProvider {
  final ContactCardData? data;
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

  // Tilt Logic
  final Vector2 _currentTilt = Vector2.zero();
  Vector2 _targetTilt = Vector2.zero();

  Vector2 get currentTilt => _currentTilt;

  @override
  double get opacity => _scrollOpacity;

  bool _hasPlayedEntrySound = false;

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

late SpriteComponent iconComp;
  late TextComponent titleComp;
  late RectangleComponent dividerComp;
  late TextComponent descComp;
  late TextComponent ctaComp;

  ContactCard({
    required this.data,
    required this.index,
    required this.totalCards,
  });

  @override
  Future<void> onLoad() async {
    if (data != null) {
      final iconPaths = [
        'bill.png',
        'linkedin.png',
        'github.png',
        'gmail.png',
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

      descComp = TextComponent(
        text: '',
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: GameStyles.cardDescVisibleSize,
            color: GameStyles.cardDesc,
            height: 1.4,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2,
      );
      add(descComp);

      // CTA button text on the back
      ctaComp = TextComponent(
        text: data!.ctaText,
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameStyles.fontModernUrban,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: data!.accentColor,
            letterSpacing: 1.5,
          ),
        ),
        anchor: Anchor.center,
      );
      add(ctaComp);
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

  double _lastAlpha = -1.0;
  bool canFlip = false;

  @override
  void render(Canvas canvas) {
    if (_scrollOpacity <= 0) return;

    final RRect rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(15.0),
    );

    // 1. Background Fill
    final bgPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.06 * _finalOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // 2. Border Stroke
    final borderPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.1 * _finalOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    super.render(canvas);
  }

  bool get isFlipped => _isFlipped;

  void forceResetFlip() {
    _isFlipped = false;
  }

  void onHoverEnter() {
    if (!canFlip) return;
    _isHovered = true;
    _isFlipped = true;
    game.audio.playContactCardHover(index);
    game.contactSection.triggerLightningEffect();
  }

  /// Open the card's URL in a new tab
  void openUrl() {
    final url = data?.url;
    if (url != null && url.isNotEmpty && kIsWeb) {
      web.window.open(url, '_blank');
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Flame's default tap routing can't hit perspective-transformed cards.
    // Taps are routed via MyGame.onTapDown → card.openUrl() instead.
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

    // Update visuals if opacity changes (Text rendering needs explicit alpha update)
    final currentAlpha = _finalOpacity;
    if ((currentAlpha - _lastAlpha).abs() > 0.01) {
      _lastAlpha = currentAlpha;
      _updateVisuals();
    }

    // Play entry sound (Re/Mi/Fa/Si) when becoming visible
    if (currentAlpha > 0.1 && !_hasPlayedEntrySound) {
      LoggerUtil.log(
        'contactCard',
        'Card $index Entry -> Alpha: $currentAlpha',
      );
      _hasPlayedEntrySound = true;
    } else if (currentAlpha < 0.05 && _hasPlayedEntrySound) {
      LoggerUtil.log(
        'contactCard',
        'Card $index Exit -> Alpha: $currentAlpha',
      );
      _hasPlayedEntrySound = false;
    }

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
      // Sound removed as per user request
      LoggerUtil.log(
        'contactCard',
        'Card $index Flip -> ${flipProgress >= 0.5 ? "Back" : "Front"}',
      );
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

   if (_isHovered && canFlip && !_isFlipped) {
      final cursor = game.cursorPosition;
     final matrix = hitboxMatrix ?? transformMat;
      if (matrix != null) {
        try {
          final inverted = Matrix4.copy(matrix)..invert();
          final localPoint = inverted.perspectiveTransform(
            Vector3(cursor.x, cursor.y, 0),
          );
          final centerX = size.x / 2;
          final centerY = size.y / 2;
          final normX = (localPoint.x - centerX) / centerX;
          final normY = (localPoint.y - centerY) / centerY;
          _targetTilt = Vector2(normX.clamp(-1.0, 1.0), normY.clamp(-1.0, 1.0));
        } catch (e) {
          _targetTilt = Vector2.zero();
        }
      }
    } else {
      _targetTilt = Vector2.zero();
    }

    // Smooth Tilt
    const tiltSpeed = 5.0;
    _currentTilt.x += (_targetTilt.x - _currentTilt.x) * dt * tiltSpeed;
    _currentTilt.y += (_targetTilt.y - _currentTilt.y) * dt * tiltSpeed;

    final isBack = flipProgress > 0.5;
    if (isBack) {
      iconComp.scale = Vector2.zero();
      titleComp.scale = Vector2.zero();
      descComp.scale = Vector2.all(1.0);
      ctaComp.scale = Vector2.all(1.0);

      if (index == 3 && _idleTime % 60 < 1) {
        // Throttle logs
        // LoggerUtil.log('contactCard', 'Card $index Back Update: Scale ${descComp.scale.x}, Alpha $_finalOpacity');
      }
    } else {
      iconComp.scale = Vector2.all(1.0);
      titleComp.scale = Vector2.all(1.0);
      descComp.scale = Vector2.zero();
      ctaComp.scale = Vector2.zero();
    }

    // Debug log for opacity/scale in update
    if (_isFlipped && index == 2 && _idleTime % 1.0 < 0.05) {
      // LoggerUtil.log('contactCard', 'Update: Card $index Back. Opacity: $_finalOpacity, Scale: ${descComp.scale}');
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (transformMat != null) {
      canvas.save();
      canvas.transform(transformMat!.storage);

      // Always render the card background (border and glass effect)
      render(canvas);

      if (flipProgress < 0.5) {
        // Front side: Show icon and title
        // Icon: Same plane as card background (Z=0)
        iconComp.renderTree(canvas);

        // Title: Higher Priority (Lifted off card) -> Z = +30
        canvas.save();
        canvas.transform(Matrix4.translationValues(0, 0, 30.0).storage);
        titleComp.renderTree(canvas);
        canvas.restore();

        // Divider: Standard Plane (Z=0)
        // dividerComp.renderTree(canvas); // Hidden in layout anyway, but safe to skip
      } else {
        // Back side: Un-mirror by flipping canvas horizontally
        canvas.save();
        canvas.scale(-1.0, 1.0);
        canvas.translate(-size.x, 0);
        descComp.renderTree(canvas);

        // CTA button — rendered below description
        // Draw button background
        final ctaBounds = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.x / 2, size.y - 50),
            width: 160,
            height: 36,
          ),
          const Radius.circular(18),
        );
        canvas.drawRRect(
          ctaBounds,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.12 * _finalOpacity),
        );
        canvas.drawRRect(
          ctaBounds,
          Paint()
            ..color = (data?.accentColor ?? const Color(0xFFFFFFFF)).withValues(alpha: 0.5 * _finalOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        ctaComp.renderTree(canvas);
        canvas.restore();
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

    // Fill parent with 16.0 padding (16 left + 16 right = 32)
    final descWidth = size.x - 16.0;

    // Wrap text manually
    final wrappedText = _wrapText(data?.description ?? '', style, descWidth);
    descComp.text = wrappedText;

    // Position Description at CENTER
    descComp.position = size / 2;
    descComp.anchor = Anchor.center;

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

    // CTA position — bottom center of card
    ctaComp.position = Vector2(size.x / 2, size.y - 50);
    ctaComp.anchor = Anchor.center;
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

      ctaComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: (data!.accentColor).withValues(alpha: alpha),
          letterSpacing: 1.5,
        ),
      );
    }
  }

  String _wrapText(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);

   final words = text.split(' ');
    final sb = StringBuffer();
    String currentLine = '';

    for (final word in words) {
      final potentialLine = currentLine.isEmpty ? word : '$currentLine $word';
      textPainter.text = TextSpan(text: potentialLine, style: style);
      textPainter.layout(maxWidth: double.infinity);

      if (textPainter.width <= maxWidth) {
        currentLine = potentialLine;
      } else {
        if (sb.isNotEmpty) sb.write('\n');
        sb.write(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      if (sb.isNotEmpty) sb.write('\n');
      sb.write(currentLine);
    }

    return sb.toString();
  }
}
