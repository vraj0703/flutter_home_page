import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

import 'keycap_component.dart';

class SkillsKeyboardComponent extends PositionComponent with HasPaint {
  SkillsKeyboardComponent({super.size});

  late RectangleComponent _chassis;
  final List<String> tools = GameStrings.skillKeys;

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
        child.opacity = val;
      }
    }
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

    // Chassis (Base)
    _chassis = RectangleComponent(
      position: chassisPos,
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = GameStyles.keyboardChassis.withValues(alpha: opacity),
    );
    _chassis.paint.style = PaintingStyle.fill;
    add(_chassis);

    // Chassis Border/Side
    _chassisSide = RectangleComponent(
      position: Vector2(
        chassisPos.x,
        chassisPos.y + GameLayout.keyboardChassisShadowOffset,
      ), // Shifted down
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = GameStyles.keyboardChassisSide.withValues(alpha: opacity),
      priority: -1, // Behind
    );
    add(_chassisSide);

    final keySize = GameLayout.keyboardKeySize;
    final spacing = GameLayout.keyboardKeySpacing;
    final rowSpacing = GameLayout.keyboardRowSpacing;

    int currentToolIndex = 0;
    final rows = [6, 7, 7, 5];
    final rowOffsets = GameLayout.keyboardRowOffsets; // Stagger
    double startY = chassisPos.y + GameLayout.keyboardStartYOffset;

    for (int r = 0; r < rows.length; r++) {
      final count = rows[r];
      final rowWidth = (count * keySize) + ((count - 1) * spacing);
      double startX =
          chassisPos.x + (chassisWidth - rowWidth) / 2 + rowOffsets[r];

      for (int k = 0; k < count; k++) {
        if (currentToolIndex >= tools.length) {
          break;
        }

        final toolName = tools[currentToolIndex];
        final key = KeycapComponent(
          label: toolName,
          size: Vector2(keySize, keySize),
        );
        key.opacity = opacity;
        key.position = Vector2(
          startX + k * (keySize + spacing),
          startY + r * rowSpacing,
        );
        add(key);
        currentToolIndex++;
      }
    }
  }
}
