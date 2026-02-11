import 'dart:math';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Canvas, Curves;

import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/game_data.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

import 'package:flutter_home_page/project/app/views/components/experience/experience_details_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/gear_next_button.dart';

class ChronosGearComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  // Text components
  late TextComponent companyText;
  late TextComponent roleText;
  late TextComponent durationText;

  late DetailCanvas detailsComponent;
  late NavigationTrigger nextBtn;

  final List<ExperienceNode> data = GameData.experienceNodes;

  int _currentIndex = 0;

  double _visualRotation = 0.0;
  double _opacity = 0.0;

  ChronosGearComponent({super.size});

  @override
  double get opacity => _opacity;

  @override
  set opacity(double val) {
    _opacity = val;
    if (isLoaded) {
      _updateTextOpacity(val);
      nextBtn.opacity = val;
    }
  }

  // Light Mode Styles
  // Company: Dark Grey, Spaced
  final companyStyle = TextStyle(
    fontFamily: GameStyles.fontInter,
    fontSize: GameStyles.companyFontSize,
    letterSpacing: 2.0,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF424242), // Grey 800
  );

  // Role: Black, Bold, Modern
  final roleStyle = TextStyle(
    fontFamily: GameStyles.fontModernUrban,
    fontSize: GameStyles.philosophyFontSize,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // Duration: Light Grey, Thin
  final durationStyle = TextStyle(
    fontFamily: GameStyles.fontInter,
    fontSize: GameStyles.durationFontSize,
    fontWeight: FontWeight.w300,
    color: const Color(0xFF757575), // Grey 600
  );

  void nextExperience() {
    _currentIndex = (_currentIndex + 1) % data.length;

    // Animate Rotation: "Mechanical Inertia" (Overshoot)
    final double step = (2 * pi / data.length);
    final double target = _visualRotation + step;

    add(
      GearRotationEffect(
        from: _visualRotation,
        to: target,
        controller: EffectController(duration: 0.8, curve: Curves.easeOutBack),
        onUpdate: (val) => _visualRotation = val,
      ),
    );

    // Audio
    game.audio.playGearTick(); // To be replaced with "zip" sound later

    // Text Reveal
    _updateContent(forceUpdate: true, op: _opacity);
    detailsComponent.show(_currentIndex);
  }

  @override
  void render(Canvas canvas) {
    // Drive the shader uniforms from here
    final shader = game.experienceSection.circlesBackground.shader;

    // Index 7: uRotation
    shader.setFloat(7, _visualRotation);
    // Index 8: uActiveNode (passing index as float)
    shader.setFloat(8, _currentIndex.toDouble());

    // Debug visualization of gear anchor (optional)
    // canvas.drawCircle(Offset(0, size.y/2), 10, Paint()..color = Colors.red);
  }

  @override
  Future<void> onLoad() async {
    // Gear Logic: Anchor at (0, size.y / 2) -> Left Centered
    // The shader handles the gear rendering based on UVs.

    final halfHeight = size.y / 2;
    // Shift text to the right side of the screen
    final textX = size.x * 0.55;

    // Create Text Components
    companyText = TextComponent(
      text: data[0].company.toUpperCase(),
      textRenderer: TextPaint(style: companyStyle),
      position: Vector2(textX, halfHeight - 40),
    );
    add(companyText);

    roleText = TextComponent(
      text: data[0].title,
      textRenderer: TextPaint(style: roleStyle),
      position: Vector2(textX, halfHeight - 10),
    );
    add(roleText);

    durationText = TextComponent(
      text: "${data[0].duration} | ${data[0].location}",
      textRenderer: TextPaint(style: durationStyle),
      position: Vector2(textX, halfHeight + 60),
    );
    add(durationText);

    // Title: EXPERIENCE
    // Centered in the "half circle" on the left
    final titleStyle = TextStyle(
      fontFamily: GameStyles.fontModernUrban,
      fontSize: 24,
      letterSpacing: 8.0,
      fontWeight: FontWeight.bold,
      color: GameStyles.accentGold,
    );

    final titleText = TextComponent(
      text: "EXPERIENCE",
      textRenderer: TextPaint(style: titleStyle),
      position: Vector2(60, halfHeight), // Left aligned, centered vertically
      anchor: Anchor.centerLeft,
      angle:
          -pi /
          2, // Rotated vertically? Or horizontal? User said "center of half circle".
      // If it's a gear, text running along the radius or vertical looks cool.
      // Let's try vertical (-90 deg) to fit inside the left edge nicely.
    );
    add(titleText);

    detailsComponent = DetailCanvas(data: data)..size = size;
    // Details component needs to be positioned/styled?
    // It currently assumes full screen overlay?
    add(detailsComponent);

    // Init state
    _opacity = 0.0;
    _updateContent(forceUpdate: false, op: 0.0);
    detailsComponent.opacity = 0.0;

    // Add Next Button (NavigationTrigger)
    nextBtn = NavigationTrigger(
      gear: this,
      position: Vector2(size.x - 80, size.y - 80),
      anchor: Anchor.bottomRight,
    );
    add(nextBtn);

    _updateTextPositions();
  }

  void _updateTextPositions() {
    final halfHeight = size.y / 2;
    final textX = size.x * 0.55;
    companyText.position = Vector2(textX, halfHeight - 40);
    roleText.position = Vector2(textX, halfHeight - 10);
    durationText.position = Vector2(textX, halfHeight + 60);
  }

  void _updateTextOpacity(double parentOpacity) {
    if (!isLoaded) return;
    detailsComponent.opacity = parentOpacity;
    _updateContent(forceUpdate: false, op: parentOpacity);
  }

  void _updateContent({bool forceUpdate = false, double? op}) {
    double alpha = op ?? _opacity;
    if (_currentIndex >= data.length) _currentIndex = 0;
    final item = data[_currentIndex];

    // Light Mode Opacity Logic
    final textColor = Colors.black.withValues(alpha: alpha);
    final dimColor = const Color(0xFF757575).withValues(alpha: alpha);
    final accentColor = const Color(0xFF424242).withValues(alpha: alpha);

    if (forceUpdate) {
      // Re-trigger reveal animation for text (Slide Up & In)
      final textX = size.x * 0.55;
      final halfHeight = size.y / 2;

      // Staggered Slide Up
      companyText.position = Vector2(textX, halfHeight - 20); // Start lower
      companyText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 40), // Move up to target
          EffectController(duration: 0.4, curve: Curves.easeOutCubic),
        ),
      );

      roleText.position = Vector2(textX, halfHeight + 10);
      roleText.add(
        MoveToEffect(
          Vector2(textX, halfHeight - 10),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOutCubic,
            startDelay: 0.1,
          ),
        ),
      );

      durationText.position = Vector2(textX, halfHeight + 80);
      durationText.add(
        MoveToEffect(
          Vector2(textX, halfHeight + 60),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOutCubic,
            startDelay: 0.2,
          ),
        ),
      );

      game.audio.playSlideIn();
    }

    companyText.text = item.company.toUpperCase();
    companyText.textRenderer = TextPaint(
      style: companyStyle.copyWith(color: accentColor),
    );

    roleText.text = item.title;
    roleText.textRenderer = TextPaint(
      style: roleStyle.copyWith(color: textColor, height: 1.1),
    );

    durationText.text = "${item.duration} | ${item.location}";
    durationText.textRenderer = TextPaint(
      style: durationStyle.copyWith(color: dimColor),
    );
  }
}

// Custom Effect for Gear Rotation
class GearRotationEffect extends Effect {
  final double from;
  final double to;
  final Function(double) onUpdate;

  GearRotationEffect({
    required this.from,
    required this.to,
    required this.onUpdate,
    required EffectController controller,
  }) : super(controller);

  @override
  void apply(double progress) {
    final val = from + (to - from) * progress;
    onUpdate(val);
  }
}
