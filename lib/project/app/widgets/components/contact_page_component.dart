import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'package:flutter_home_page/project/app/widgets/components/wrapped_text_component.dart';

class ContactPageComponent extends PositionComponent
    with HasPaint, HasGameReference {
  ContactPageComponent({super.size});

  late RectangleComponent _background;
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

    // --- Columns Setup ---
    final leftColX = size.x * 0.1;
    final rightColX = size.x * 0.55;
    final contentWidth = size.x * 0.35;

    // --- LEFT COLUMN ---

    // Title "Contact"
    _titleText = TextComponent(
      text: "Contact",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 120, // Huge
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      position: Vector2(leftColX, size.y * 0.15),
    );
    add(_titleText);

    // Description
    _descriptionText = WrappedTextComponent(
      TextPainter(
        text: const TextSpan(
          text:
              "If you're curious to know more about what you saw, I invite you to contact me or follow me on social media.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      contentWidth,
    );
    _descriptionText.position = Vector2(leftColX, size.y * 0.45);
    add(_descriptionText);

    // Social Icons (Placeholders for now: Just Text/Rects)
    final iconY = size.y * 0.65;
    _addSocialIcon(Icons.email, Vector2(leftColX, iconY));
    _addSocialIcon(Icons.camera_alt, Vector2(leftColX + 60, iconY)); // Insta
    _addSocialIcon(Icons.link, Vector2(leftColX + 120, iconY)); // LinkedIn

    // --- RIGHT COLUMN ---
    double formY = size.y * 0.45;
    final formSpacing = 100.0;

    // Name
    _addFormField("Name", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    // Email
    _addFormField("Email", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    // Message
    _addFormField(
      "How can I help you?",
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += 150; // More space for message

    // Send Button
    _sendButton = RectangleComponent(
      size: Vector2(200, 60),
      paint: Paint()..color = Colors.white,
      position: Vector2(rightColX + contentWidth - 200, formY),
    );
    add(_sendButton);

    _sendButtonText = TextComponent(
      text: "SEND",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 1.2,
        ),
      ),
    );
    _sendButtonText.anchor = Anchor.center;
    _sendButtonText.position = _sendButton.size / 2;
    _sendButton.add(_sendButtonText);

    // Initial hidden state handled by Controller (setting position/opacity)
  }

  void _addSocialIcon(IconData icon, Vector2 pos) {
    // Since we can't easily render IconData in pure Flame without Flutter overlay or font,
    // I'll simulate 'Icon' with a small black box for now or try to use Text if font supports it.
    // Using a simple square placeholder.
    final box =
        RectangleComponent(
            position: pos,
            size: Vector2(40, 40),
            paint: Paint()..color = Colors.white,
          )
          ..paint.style = PaintingStyle.stroke
          ..paint.strokeWidth = 3;
    add(box);
  }

  void _addFormField(String label, Vector2 pos, double width) {
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      position: pos,
    );
    add(text);

    final line = RectangleComponent(
      position: Vector2(pos.x, pos.y + 35),
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
