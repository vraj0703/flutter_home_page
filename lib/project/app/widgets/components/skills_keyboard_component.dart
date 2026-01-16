import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SkillsKeyboardComponent extends PositionComponent with HasPaint {
  SkillsKeyboardComponent({super.size});

  late RectangleComponent _chassis;
  // Tools list - "Keys"
  final List<String> tools = [
    "Flutter",
    "Dart",
    "Flame",
    "Firebase",
    "Git",
    "Figma",
    "Block",
    "Provider",
    "Riverpod",
    "Clean Arch",
    "CI/CD",
    "Jira",
    "Agile",
    "SOLID",
    "REST API",
    "GraphQL",
    "Python",
    "C++",
    "GLSL",
  ];

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (!isLoaded) return; // Prevent access before onLoad

    // Propagate to chassis
    _chassis.paint.color = _chassis.paint.color.withValues(alpha: val);
    // Side doesn't have a direct reference variable unless we stored it.
    // Assuming it's the 2nd child. Or we find it.
    // Better: Iterate all children.
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
    // Chassis Dimensions
    final chassisWidth = size.x * 0.8;
    final chassisHeight = size.y * 0.5;
    final chassisPos = Vector2(
      (size.x - chassisWidth) / 2,
      (size.y - chassisHeight) / 2,
    );

    // Chassis (Base)
    _chassis = RectangleComponent(
      position: chassisPos,
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = const Color(
          0xFF111111,
        ).withValues(alpha: opacity), // Apply initial opacity
    );
    // Add 3D depth to chassis?
    // Maybe render a "side" manually or just a border.
    _chassis.paint.style = PaintingStyle.fill;
    add(_chassis);

    // Chassis Border/Side
    _chassisSide = RectangleComponent(
      position: Vector2(chassisPos.x, chassisPos.y + 10), // Shifted down
      size: Vector2(chassisWidth, chassisHeight),
      paint: Paint()
        ..color = const Color(
          0xFF000000,
        ).withValues(alpha: opacity), // Apply initial opacity
      priority: -1, // Behind
    );
    add(_chassisSide);

    // Keys Layout
    // 60% Keyboard approx: ~14 keys wide.
    // We have ~20 tools.
    // Row 1: 6 keys
    // Row 2: 7 keys
    // Row 3: 6 keys

    final keySize = 60.0;
    final spacing = 15.0;
    final rowSpacing = 70.0;

    // Calculate layout
    int currentToolIndex = 0;
    final rows = [6, 7, 7, 5]; // number of keys per row
    final rowOffsets = [0.0, 30.0, 45.0, 0.0]; // Stagger

    double startY = chassisPos.y + 60;

    for (int r = 0; r < rows.length; r++) {
      final count = rows[r];
      final rowWidth = (count * keySize) + ((count - 1) * spacing);
      double startX =
          chassisPos.x +
          (chassisWidth - rowWidth) / 2 +
          rowOffsets[r]; // Center row

      // Adjust for stagger if manual centering prefers looks over strict center
      // Let's just center lines.
      startX = chassisPos.x + (chassisWidth - rowWidth) / 2;

      for (int k = 0; k < count; k++) {
        if (currentToolIndex >= tools.length) {
          // Fill with "Enter" or decoration if run out
          // Or just break
          break;
        }

        final toolName = tools[currentToolIndex];
        final key = KeycapComponent(
          label: toolName,
          size: Vector2(keySize, keySize),
        );
        key.opacity = opacity; // Apply initial opacity
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

class KeycapComponent extends PositionComponent with HasPaint {
  final String label;

  KeycapComponent({required this.label, required Vector2 size})
    : super(size: size);

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    // Update text child
    for (final child in children) {
      if (child is TextComponent) {
        final style = (child.textRenderer as TextPaint).style;
        child.textRenderer = TextPaint(
          style: style.copyWith(color: style.color?.withValues(alpha: val)),
        );
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (opacity == 0.0) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0.0) return; // Optimization

    // 3D Effect
    final depth = 10.0;
    final radius = 8.0;

    // Side Face (Darker)
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, depth, size.x, size.y),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      sideRect,
      Paint()..color = const Color(0xFF1A1A1A).withValues(alpha: opacity),
    ); // Dark Side

    // Top Face
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(radius),
    );

    final isHighlighted = ["Flutter", "Dart", "Flame"].contains(label);

    // Dark Theme: Normal = Dark Grey (#262626), Highlight = White (#FFFFFF)
    final color = isHighlighted
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF262626);

    canvas.drawRRect(
      topRect,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  // onLoad remains same as before...
  @override
  Future<void> onLoad() async {
    final isHighlighted = ["Flutter", "Dart", "Flame"].contains(label);
    final queryText = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          // Highlight (White Key) -> Black Text
          // Normal (Dark Key) -> White Text
          color: isHighlighted ? Colors.black : Colors.white,
        ),
      ),
    );
    // Center
    // We need to measure text? Arrow works based on anchor.
    queryText.anchor = Anchor.center;
    queryText.position = Vector2(
      size.x / 2,
      size.y / 2,
    ); // Center of Top Face (0,0 to w,h)
    // Actually top face is at 0,0 locally.
    add(queryText);

    // Apply initial opacity if needed (if created with opacity 0)
    // But opacity setter might not trigger on creation if default is 1.0.
    // Parent loop handles it.
  }
}
