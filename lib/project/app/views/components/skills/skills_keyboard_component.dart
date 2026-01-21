import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

import 'package:flutter_home_page/project/app/views/components/skills/keycap_component.dart';

class SkillsKeyboardComponent extends PositionComponent with HasPaint {
  final FragmentShader? metallicShader;

  SkillsKeyboardComponent({super.size, this.metallicShader});

  late RectangleComponent _chassis;
  final List<String> tools = GameStrings.skillKeys;
  final List<double> _keyEntranceDelays = [];
  double _globalEntranceProgress = 0.0;

  void setEntranceProgress(double progress) {
    _globalEntranceProgress = progress;
    _updateKeyAnimations();
  }

  void _updateKeyAnimations() {
    int keyIndex = 0;
    for (final child in children) {
      if (child is KeycapComponent && keyIndex < _keyEntranceDelays.length) {
        final delay = _keyEntranceDelays[keyIndex];
        final t = (_globalEntranceProgress - delay).clamp(0.0, 1.0);

        // Elastic bounce
        final curvedT = _elasticEaseOut(t);

        child.scale = Vector2.all(0.5 + (0.5 * curvedT));
        child.opacity = curvedT * opacity; // Respect parent opacity

        keyIndex++;
      }
    }
  }

  double _elasticEaseOut(double t) {
    if (t == 0.0 || t == 1.0) return t;
    const amplitude = 0.4;
    const period = 0.3;
    return math.pow(2, -10 * t) *
            math.sin((t - amplitude / 4) * (2 * math.pi) / period) +
        1;
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (!isLoaded) return;
    _chassis.paint.color = _chassis.paint.color.withValues(alpha: val);
    for (final child in children) {
      if (child is RectangleComponent) {
        child.paint.color = child.paint.color.withValues(alpha: val);
      } else if (child is KeycapComponent) {
        // Opacity will be controlled by stagger animation
        if (_keyEntranceDelays.isEmpty) {
          child.opacity = val;
        }
      }
    }
    if (isLoaded) _updateKeyAnimations();
  }

  late RectangleComponent _chassisSide;

  @override
  void renderTree(Canvas canvas) {
    if (opacity == 0.0) return;
    super.renderTree(canvas);
  }

  @override
  Future<void> onLoad() async {
    final chassisWidth = size.x * GameLayout.keyboardChassisWidthRatio;
    final chassisHeight = size.y * GameLayout.keyboardChassisHeightRatio;
    final chassisPos = Vector2(
      (size.x - chassisWidth) / 2,
      (size.y - chassisHeight) / 2,
    );

    // Layer 1: Shadow (deepest)
    final shadow = RectangleComponent(
      position: chassisPos + Vector2(0, 15),
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = const Color(0xFF000000).withValues(alpha: opacity * 0.5),
      priority: -3,
    );
    add(shadow);

    // Layer 2: Side
    _chassisSide = RectangleComponent(
      position: chassisPos + Vector2(0, GameLayout.keyboardChassisShadowOffset),
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = GameStyles.keyboardChassisSide.withValues(alpha: opacity),
      priority: -2,
    );
    add(_chassisSide);

    // Layer 3: Main with bevel gradient
    final bevelRect = Rect.fromLTWH(
      chassisPos.x,
      chassisPos.y,
      chassisWidth,
      chassisHeight,
    );
    final bevelGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        GameStyles.keyboardChassis.withValues(alpha: opacity * 1.2),
        GameStyles.keyboardChassis.withValues(alpha: opacity),
        GameStyles.keyboardChassis.withValues(alpha: opacity * 0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    _chassis = RectangleComponent(
      position: chassisPos,
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()..shader = bevelGradient.createShader(bevelRect),
      priority: -1,
    );
    add(_chassis);

    final spacing = GameLayout.keyboardKeySpacing;
    final rowSpacing = GameLayout.keyboardRowSpacing;

    int currentToolIndex = 0;
    final rows = [6, 7, 7, 5];
    final rowOffsets = GameLayout.keyboardRowOffsets; // Stagger
    double startY = chassisPos.y + GameLayout.keyboardStartYOffset;

    for (int r = 0; r < rows.length; r++) {
      final count = rows[r];

      // Calculate row width accounting for hero keys (80×80) vs regular (60×60)
      double rowWidth = 0.0;
      for (int i = 0; i < count && (currentToolIndex + i) < tools.length; i++) {
        final toolName = tools[currentToolIndex + i];
        final isHeroKey = ["Flutter", "Dart", "Flame"].contains(toolName);
        rowWidth += isHeroKey ? 80.0 : GameLayout.keyboardKeySize;
        if (i < count - 1) rowWidth += spacing;
      }

      double startX =
          chassisPos.x + (chassisWidth - rowWidth) / 2 + rowOffsets[r];
      double currentX = startX;

      for (int k = 0; k < count; k++) {
        if (currentToolIndex >= tools.length) {
          break;
        }

        final toolName = tools[currentToolIndex];
        final isHeroKey = ["Flutter", "Dart", "Flame"].contains(toolName);
        final keySize = isHeroKey ? 80.0 : GameLayout.keyboardKeySize;

        // Stagger: row delay (100ms) + column delay (30ms)
        final delay = (r * 0.1) + (k * 0.03);
        _keyEntranceDelays.add(delay);

        final key = KeycapComponent(
          label: toolName,
          size: Vector2(keySize, keySize),
          shader: isHeroKey ? metallicShader : null,
        );
        key.opacity = opacity;
        key.position = Vector2(currentX, startY + r * rowSpacing);
        add(key);

        currentX += keySize + spacing;
        currentToolIndex++;
      }
    }
  }
}
