import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart' show Colors, Curves;
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';

import 'package:flutter_home_page/project/app/views/my_game.dart';

class NextButtonComponent extends PositionComponent
    with HasGameReference<MyGame>, HoverCallbacks, HasPaint {
  bool _isHovering = false;
  double _holdProgress = 0.0;
  late SvgComponent _arrowIcon;
  bool _hasPlayedEntrySound = false;

  @override
  set opacity(double value) {
    super.opacity = value;
    if (!isLoaded) return; // Prevent late initialization error

    // Propagate opacity to SVG
    if (_arrowIcon.isMounted) {
      _arrowIcon.paint.colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: value),
        BlendMode.srcIn,
      );
    }
    // LoggerUtil.log('NextButton', 'Opacity: $value');
  }

  double get holdDuration =>
      ScrollSequenceConfig.philosophyTransition.buttonHoldDuration;

  // Pill Dimensions
  static const double buttonWidth = 200.0;
  static const double buttonHeight = 80.0;
  static const double borderRadius = 40.0;

  static const Color accentColor = Color(0xFF00FFFF); // Neon Cyan

  bool get isHovering => _isHovering;

  VoidCallback? onHoldComplete;
  VoidCallback? onReleased;
  Function(double)? onProgressChange;

  NextButtonComponent({super.position, super.anchor = Anchor.center}) {
    size = Vector2(buttonWidth, buttonHeight);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final svg = await Svg.load('vectors/down_arrow.svg');
    _arrowIcon = SvgComponent(
      svg: svg,
      anchor: Anchor.center,
      position: size / 2,
      size: Vector2.all(32), // Adjust size as needed
      paint: Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );

    // Rotate -90 degrees (pointing right)
    _arrowIcon.angle = -pi / 2;

    add(_arrowIcon);

    // Sync opacity in case it was set before load
    if (opacity < 1.0) {
      _arrowIcon.paint.colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: opacity),
        BlendMode.srcIn,
      );
    }

    // Initial Pulse
    add(
      ScaleEffect.to(
        Vector2.all(1.05),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (opacity <= 0.0) {
      _holdProgress = 0.0;
      _isHovering = false;
      _hasPlayedEntrySound = false; // Reset when invisible
      return;
    }

    // Play entry sound (Sol)
    if (opacity > 0.1 && !_hasPlayedEntrySound) {
      game.audio.playPhilosophyButtonHover();
      _hasPlayedEntrySound = true;
    } else if (opacity < 0.05 && _hasPlayedEntrySound) {
      game.audio.playPhilosophyButtonHover(); // Play on exit
      _hasPlayedEntrySound = false;
    }

    final previousProgress = _holdProgress;

    if (isHovered) {
      _holdProgress = (_holdProgress + dt / holdDuration).clamp(0.0, 1.0);

      // Trigger completion callback when reaching 100%
      if (previousProgress < 1.0 && _holdProgress >= 1.0) {
        LoggerUtil.log('NextButton', 'Hold Complete -> Triggering Action');
        onHoldComplete?.call();
      }
    } else {
      _holdProgress = (_holdProgress - dt).clamp(0.0, 1.0); // Fast decay
    }
    onProgressChange?.call(_holdProgress);
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;

    // Glassmorphic Background
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(borderRadius),
    );

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 * opacity)
      ..style = PaintingStyle.fill;

    // Use isHovering to determine border - brighter when hovered
    final borderAlpha = _isHovering ? 0.8 : 0.2;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: borderAlpha * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Progress Stroke (if holding)
    if (_holdProgress > 0) {
      // Simulate progress by clipping the stroke
      canvas.save();

      // Calculate clip rect based on progress (left to right fill)
      // Since it's a stroke, we want to "light up" the border.
      // Progress 0 -> 1.0
      // We can use a ClipRect that grows width-wise.
      final clipWidth = size.x * _holdProgress;
      canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, size.y));

      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0; // Slightly thicker than border

      canvas.drawRRect(rrect, progressPaint);

      canvas.restore();
    }
  }

  @override
  void onHoverEnter() {
    _isHovering = true;
    game.audio.playPhilosophyButtonHover();
    // Trigger lightning/panic
    game.philosophySection.triggerLightningEffect();

    // On Hover: Remove pulse, scale up slightly and hold
    children.whereType<ScaleEffect>().forEach((e) => e.removeFromParent());
    add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.1)));
  }

  @override
  void onHoverExit() {
    _isHovering = false;
    onReleased?.call();

    // On Exit: Return to pulse
    children.whereType<ScaleEffect>().forEach((e) => e.removeFromParent());
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.2)));
    // Re-add pulse after a short delay or immediately
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_isHovering) {
        add(
          ScaleEffect.to(
            Vector2.all(1.15),
            EffectController(
              duration: 1.2,
              reverseDuration: 1.2,
              infinite: true,
              curve: Curves.easeInOut,
            ),
          ),
        );
      }
    });
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(borderRadius),
    );
    return rrect.contains(point.toOffset());
  }
}
