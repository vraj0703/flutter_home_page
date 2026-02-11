import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_rotator_component.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class NavigationTrigger extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameReference<MyGame> {
  final ChronosGearComponent gear;

  // Visuals
  late TextComponent _label;
  late RectangleComponent _underline;

  bool _isHovering = false;

  set opacity(double val) {
    _label.textRenderer = TextPaint(
      style: (_label.textRenderer as TextPaint).style.copyWith(
        color: const Color(0xFF212121).withValues(alpha: val),
      ),
    );
    _underline.paint.color = GameStyles.accentGold.withValues(alpha: val);
  }

  NavigationTrigger({
    required this.gear,
    super.position,
    super.anchor = Anchor.center,
  }) : super(size: Vector2(200, 50));

  @override
  Future<void> onLoad() async {
    // 1. Label "Next Experience ->"
    // Style: Modern, clean, black/dark grey
    final style = TextStyle(
      fontFamily: GameStyles.fontInter,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: const Color(0xFF212121),
    );

    _label = TextComponent(
      text: "NEXT EXPERIENCE",
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_label);

    // 2. Underline (Hidden by default, reveals on hover)
    _underline = RectangleComponent(
      size: Vector2(0, 2),
      position: Vector2(size.x / 2, size.y / 2 + 15),
      anchor: Anchor.center,
      paint: Paint()..color = GameStyles.accentGold, // Gold
    );
    add(_underline);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Hover Animation: Expand underline
    final targetWidth = _isHovering ? _label.size.x : 0.0;
    // Simple lerp
    final currentWidth = _underline.size.x;
    final newWidth = currentWidth + (targetWidth - currentWidth) * dt * 10;
    _underline.size = Vector2(newWidth, 2);

    // Pulse opacity?
    if (_isHovering) {
      // _label.scale = Vector2.all(1.0 + sin(_hoverTime * 5) * 0.02);
    } else {
      // _label.scale = Vector2.all(1.0);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(0.95);
    game.audio.playClick();
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    gear.nextExperience();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0);
  }

  @override
  void onHoverEnter() {
    _isHovering = true;
    game.audio.playHover();
  }

  @override
  void onHoverExit() {
    _isHovering = false;
  }
}
