import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' as material;

import 'package:flutter_home_page/project/app/views/my_game.dart';

/// A "Gallery" button for the Contact section.
/// On tap, triggers navigation to the React gallery.
class BackButtonComponent extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks, HoverCallbacks, HasPaint {
  ui.VoidCallback? onTap;
  bool _isHovering = false;
  double _hoverGlow = 0.0;

  static const double buttonWidth = 130.0;
  static const double buttonHeight = 44.0;
  static const double borderRadius = 22.0;

  BackButtonComponent({super.position, super.anchor = Anchor.center}) {
    size = Vector2(buttonWidth, buttonHeight);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      ScaleEffect.to(
        Vector2.all(1.03),
        EffectController(
          duration: 2.0,
          reverseDuration: 2.0,
          infinite: true,
          curve: material.Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _isHovering ? 1.0 : 0.0;
    _hoverGlow += (target - _hoverGlow) * dt * 6.0;
  }

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0.0) return;

    final rrect = ui.RRect.fromRectAndRadius(
      size.toRect(),
      const ui.Radius.circular(borderRadius),
    );

    // Background
    final bgAlpha = (0.08 + _hoverGlow * 0.12) * opacity;
    final bgPaint = ui.Paint()
      ..color = ui.Color.fromRGBO(255, 255, 255, bgAlpha)
      ..style = ui.PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderAlpha = (0.15 + _hoverGlow * 0.5) * opacity;
    final borderPaint = ui.Paint()
      ..color = ui.Color.fromRGBO(255, 255, 255, borderAlpha)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Arrow (left-pointing chevron)
    final arrowPaint = ui.Paint()
      ..color = ui.Color.fromRGBO(255, 255, 255, 0.8 * opacity)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;

    const cx = 28.0;
    final cy = size.y / 2;
    const arrowSize = 8.0;

    final path = ui.Path()
      ..moveTo(cx, cy - arrowSize)
      ..lineTo(cx - arrowSize, cy)
      ..lineTo(cx, cy + arrowSize);
    canvas.drawPath(path, arrowPaint);

    // "Gallery" text — after arrow
    final textPainter = material.TextPainter(
      text: material.TextSpan(
        text: 'Gallery',
        style: material.TextStyle(
          fontSize: 14.0,
          fontWeight: material.FontWeight.w500,
          color: ui.Color.fromRGBO(255, 255, 255, 0.8 * opacity),
          letterSpacing: 1.0,
        ),
      ),
      textDirection: material.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      ui.Offset(44.0, (size.y - textPainter.height) / 2),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.audio.playClick();
    onTap?.call();
  }

  @override
  void onHoverEnter() {
    _isHovering = true;
  }

  @override
  void onHoverExit() {
    _isHovering = false;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final rrect = ui.RRect.fromRectAndRadius(
      size.toRect(),
      const ui.Radius.circular(borderRadius),
    );
    return rrect.contains(point.toOffset());
  }
}
