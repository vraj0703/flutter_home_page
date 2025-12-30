import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Curves, Shadow;
import 'package:flutter_home_page/project/app/widgets/scene.dart';

class FadeTextComponent extends TextComponent with HasPaint, HasGameReference {
  final FragmentShader shader;
  final Color baseColor;
  double _time = 0;

  FadeTextComponent({
    required super.text,
    required TextStyle textStyle,
    required this.shader,
    this.baseColor = const Color(0xFFF0F0F2),
    super.position,
    super.anchor,
  }) : super(
         textRenderer: TextPaint(
           style: textStyle.copyWith(
             foreground: Paint()..shader = shader,
             shadows: [
               const Shadow(
                 color: Colors.black45,
                 blurRadius: 10,
                 offset: Offset(2, 2),
               ),
             ],
           ),
         ),
       );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    // 1. Get the Device Pixel Ratio (DPR)
    final dpr = game.canvasSize.x / game.size.x;

    // 2. Translate everything to PHYSICAL coordinate space
    // This is the only way to ensure 1:1 cursor tracking on all devices
    final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
    final physicalSize = size * dpr;
    final physicalLightPos = (game as MyGame).godRay.position * dpr;

    shader
      ..setFloat(0, physicalSize.x)
      ..setFloat(1, physicalSize.y)
      ..setFloat(2, physicalTopLeft.x)
      ..setFloat(3, physicalTopLeft.y)
      ..setFloat(4, _time)
      ..setFloat(5, baseColor.red / 255)
      ..setFloat(6, baseColor.green / 255)
      ..setFloat(7, baseColor.blue / 255)
      ..setFloat(8, opacity)
      ..setFloat(9, physicalLightPos.x)
      ..setFloat(10, physicalLightPos.y);

    super.render(canvas);
  }
}

class CinematicTitleComponent extends PositionComponent with HasGameRef {
  final String primaryText;
  final String secondaryText;

  late FadeTextComponent _primaryTitle;
  late FadeTextComponent _secondaryTitle;

  CinematicTitleComponent({
    required this.primaryText,
    required this.secondaryText,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // --- Load the Metallic Shader (shared by both) ---
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/metallic_text.frag',
    );
    final shader = program.fragmentShader();

    // --- 1. Initialize Primary Title ("VISHAL RAJ") ---
    const primaryStyle = TextStyle(
      fontSize: 54,
      letterSpacing: 28,
      fontWeight: FontWeight.w500,
      fontFamily: 'ModrntUrban',
    );

    _primaryTitle = FadeTextComponent(
      text: primaryText.toUpperCase(),
      textStyle: primaryStyle,
      shader: shader,
      baseColor: const Color(0xFFE3E4E5),
      // Gold/Copper
      anchor: Anchor.center,
    )..opacity = 0;

    // --- 2. Initialize Secondary Title ("PORTFOLIO MMXXV") ---
    const secondaryStyle = TextStyle(
      fontSize: 14, // Smaller scale
      fontWeight: FontWeight.w400,
      letterSpacing: 4, // High spacing, but smaller than primary
      color: Colors.white, // Base color (shader overrides this)
    );

    _secondaryTitle = FadeTextComponent(
      text: secondaryText.toUpperCase(),
      textStyle: secondaryStyle,
      shader: shader,
      // Reuse the metallic shader logic
      baseColor: const Color(0xFFAAB0B5),
      // Muted Silver/Grey
      anchor: Anchor.center,
      position: Vector2(0, 70), // Positioned below primary title
    )..opacity = 0;

    // Add both to the component tree
    addAll([_primaryTitle, _secondaryTitle]);
  }

  void show() {
    // Primary reveal
    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(1.2),
        OpacityEffect.to(
          1.0,
          EffectController(duration: 5, curve: Curves.linear),
        ),
      ]),
    );

    _primaryTitle.add(
      SequenceEffect([
        WaitEffect(1.2),
        MoveByEffect(
          Vector2(0, -10), // Subtle upward "heat" drift
          EffectController(duration: 5.0, curve: Curves.easeInOut),
        ),
      ]),
    );

    // Secondary reveal (Staggered)
    _secondaryTitle.add(
      SequenceEffect([
        WaitEffect(1.2), // Custom effect created earlier (1.2s delay)
        OpacityEffect.to(
          1.0,
          EffectController(duration: 3.0, curve: Curves.linear),
        ),
      ]),
    );

    // Secondary drift (Starts exactly when the fade starts)
    _secondaryTitle.add(
      SequenceEffect([
        WaitEffect(1.2),
        MoveByEffect(
          Vector2(0, -10), // Subtle upward "heat" drift
          EffectController(duration: 2.0, curve: Curves.easeOut),
        ),
      ]),
    );
  }
}

/// A custom effect that does nothing for a specific duration.
/// Useful for staggered animations in a [SequenceEffect].
class WaitEffect extends Effect {
  WaitEffect(double duration)
    : super(PauseEffectController(duration, progress: 0.0));

  @override
  void apply(double progress) {
    // This is a no-op. It simply consumes time in the effect lifecycle.
  }
}
