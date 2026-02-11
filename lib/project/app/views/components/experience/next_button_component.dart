import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class NextButtonComponent extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks, HasPaint {
  final VoidCallback onNext;
  late TextComponent _text;
  late TextComponent _glow;

  NextButtonComponent({required this.onNext});

  @override
  Future<void> onLoad() async {
    const text = 'NEXT EXPERIENCE  →';
    const style = TextStyle(
      fontFamily: GameStyles.fontInter,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      color: GameStyles.accentGold,
    );

    // Glow Effect Layer (Behind)
    _glow = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: style.copyWith(
          foreground: Paint()
            ..color = GameStyles.accentGold.withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
        ),
      ),
      anchor: Anchor.center,
    );

    // Main Text Layer
    _text = TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
    );

    add(_glow);
    add(_text);
    size = _text.size;
    anchor = Anchor.center;

    // Initialize children at center of hitbox
    _text.position = size / 2;
    _glow.position = size / 2;
  }

  // Magnetic Effect State
  final Vector2 _basePosition = Vector2.zero();
  bool _isHovered = false;

  @override
  void onMount() {
    super.onMount();
    _basePosition.setFrom(position);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _applyOpacity(_text, 1.0);
    _applyOpacity(_glow, 0.6);
    _updateMagnetic(dt);
  }

  void _updateMagnetic(double dt) {
    final cursor = game.cursorSystem.lastKnownPosition;
    final center = absolutePosition; // Anchor center
    final dist = cursor.distanceTo(center);

    Vector2 targetOffset = Vector2.zero();

    if (dist < 150) {
      if (!_isHovered) {
        _isHovered = true;
      }

      final pull = (cursor - center);
      if (pull.length > 0) {
        final strength = ((150 - dist) / 150).clamp(0.0, 1.0);
        targetOffset = pull.normalized() * (15.0 * strength);
      }
    } else {
      _isHovered = false;
    }

    final current1 = _text.position;
    final target1 = (size / 2) + targetOffset;

    // Lerp
    _text.position = current1 + (target1 - current1) * (dt * 5.0);
    _glow.position = _text.position;
  }

  void _applyOpacity(TextComponent comp, double baseAlpha) {
    final combined = opacity * baseAlpha;

    final style = (comp.textRenderer as TextPaint).style;

    // Note: The Glow uses 'foreground' Paint. The Main uses 'color'.
    if (comp == _glow) {
      // Handle foreground paint
      final p = Paint()
        ..color = GameStyles.accentGold.withOpacity(combined)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

      comp.textRenderer = TextPaint(style: style.copyWith(foreground: p));
    } else {
      comp.textRenderer = TextPaint(
        style: style.copyWith(
          color: GameStyles.accentGold.withOpacity(combined),
        ),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _text.scale = Vector2.all(0.95);
    _glow.scale = Vector2.all(0.95);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _text.scale = Vector2.all(1.0);
    _glow.scale = Vector2.all(1.0);
    onNext();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _text.scale = Vector2.all(1.0);
    _glow.scale = Vector2.all(1.0);
  }
}
