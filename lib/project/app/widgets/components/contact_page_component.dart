import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'package:flutter_home_page/project/app/widgets/components/wrapped_text_component.dart';

class ContactPageComponent extends PositionComponent
    with HasPaint, HasGameReference {
  ContactPageComponent({super.size});

  // Left Side
  late TextComponent _titleText;
  late WrappedTextComponent _descriptionText;

  // Right Side (Form)
  late TextComponent _nameLabel;
  late RectangleComponent _nameLine;

  late TextComponent _emailLabel;
  late RectangleComponent _emailLine;

  late TextComponent _messageLabel;
  late RectangleComponent _messageLine;

  late RectangleComponent _sendButton;
  late TextComponent _sendButtonText;

  @override
  Future<void> onLoad() async {
    // Background - Yellow #FFC107
    // _background = RectangleComponent(
    //   size: size,
    //   paint: Paint()..color = const Color(0xFFFFC107),
    // );
    // add(_background);

    // --- Columns Setup - Improved spacing for minimal/futuristic theme ---
    final leftColX = size.x * 0.12; // More left margin (was 0.1)
    final rightColX = size.x * 0.58; // More gap between columns (was 0.55)
    final contentWidth = size.x * 0.32; // Slightly narrower for better readability (was 0.35)

    // --- LEFT COLUMN ---

    // Title "Contact" - More vertical breathing room
    _titleText = TextComponent(
      text: "Contact",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 110, // Slightly smaller for better proportion (was 120)
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      position: Vector2(leftColX, size.y * 0.18), // Lower starting position (was 0.15)
    );
    add(_titleText);

    // Description - More spacing from title
    _descriptionText = WrappedTextComponent(
      TextPainter(
        text: const TextSpan(
          text:
              "If you're curious to know more about what you saw, I invite you to contact me or follow me on social media.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18, // Slightly smaller for elegance (was 20)
            color: Colors.white70,
            height: 1.8, // More line height for readability (was 1.5)
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      contentWidth,
    );
    _descriptionText.position = Vector2(leftColX, size.y * 0.48); // More gap from title (was 0.45)
    add(_descriptionText);

    // Social Icons - More spacing between icons and from description
    final iconY = size.y * 0.72; // Lower position (was 0.65)
    _addSocialIcon(Icons.email, Vector2(leftColX, iconY));
    _addSocialIcon(Icons.camera_alt, Vector2(leftColX + 70, iconY)); // More spacing (was 60)
    _addSocialIcon(Icons.link, Vector2(leftColX + 140, iconY)); // More spacing (was 120)

    // --- RIGHT COLUMN ---
    double formY = size.y * 0.30; // Start higher for better balance (was 0.45)
    final formSpacing = 120.0; // More spacing between fields (was 100)

    // Name
    _addFormField("Name", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    // Email
    _addFormField("Email", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    // Message - More spacing
    _addFormField(
      "How can I help you?",
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += 180; // More space for message field (was 150)

    // Send Button - More refined styling
    _sendButton = RectangleComponent(
      size: Vector2(180, 55), // Slightly smaller for elegance (was 200x60)
      paint: Paint()..color = Colors.white,
      position: Vector2(rightColX + contentWidth - 180, formY),
    );
    add(_sendButton);

    _sendButtonText = TextComponent(
      text: "SEND",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16, // Slightly smaller (was 18)
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 2.0, // More letter spacing for minimal feel (was 1.2)
        ),
      ),
    );
    _sendButtonText.anchor = Anchor.center;
    _sendButtonText.position = _sendButton.size / 2;
    _sendButton.add(_sendButtonText);

    // Initial hidden state handled by Controller (setting position/opacity)
  }

  void _addSocialIcon(IconData icon, Vector2 pos) {
    // Icon placeholders with refined sizing for minimal aesthetic
    final box =
        RectangleComponent(
            position: pos,
            size: Vector2(45, 45), // Slightly larger for better proportion (was 40)
            paint: Paint()..color = Colors.white,
          )
          ..paint.style = PaintingStyle.stroke
          ..paint.strokeWidth = 2; // Thinner stroke for elegance (was 3)
    add(box);
  }

  void _addFormField(String label, Vector2 pos, double width) {
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15, // Slightly smaller for elegance (was 16)
          color: Colors.white,
          letterSpacing: 0.5, // Add subtle letter spacing
        ),
      ),
      position: pos,
    );
    add(text);

    final line = RectangleComponent(
      position: Vector2(pos.x, pos.y + 40), // More gap from label (was 35)
      size: Vector2(width, 1),
      paint: Paint()..color = Colors.white54,
    );
    add(line);
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    // Propagate if needed, but PositionComponent usually handles opacity via children
    // IF we implement paint logic.
    // However, default PositionComponent doesn't auto-apply opacity to children's paint unless they check parent.
    // Easiest is to traverse children or rely on a wrapper.
    // For now, let's assume we might need custom opacity if it doesn't work out of box.

    for (final child in children) {
      if (child is TextComponent) {
        child.textRenderer = TextPaint(
          style: (child.textRenderer as TextPaint).style.copyWith(
            color: (child.textRenderer as TextPaint).style.color!.withValues(
              alpha: val,
            ),
          ),
        );
      } else if (child is RectangleComponent) {
        child.paint.color = child.paint.color.withValues(alpha: val);
        // Recursive for button text
        for (final c in child.children) {
          if (c is TextComponent) {
            c.textRenderer = TextPaint(
              style: (c.textRenderer as TextPaint).style.copyWith(
                color: (c.textRenderer as TextPaint).style.color!.withValues(
                  alpha: val,
                ),
              ),
            );
          }
        }
      } else if (child is WrappedTextComponent) {
        child.opacity = val;
      }
    }
  }
}
