import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'package:flutter_home_page/project/app/views/components/wrapped_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class ContactPageComponent extends PositionComponent
    with HasPaint, HasGameReference {
  ContactPageComponent({super.size, required this.shader});

  final FragmentShader shader;
  late FadeTextComponent _titleText;
  late WrappedTextComponent _descriptionText;

  late RectangleComponent _sendButton;
  late TextComponent _sendButtonText;

  @override
  Future<void> onLoad() async {
    final leftColX = size.x * 0.12;
    final rightColX = size.x * 0.58;
    final contentWidth = size.x * 0.32;

    _titleText = FadeTextComponent(
      text: "CONTACT",
      textStyle: TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 110,
        fontWeight: FontWeight.bold,
      ),
      shader: shader,
      baseColor: const Color(0xFFCCCCCC), // Silver
    );
    _titleText.position = Vector2(leftColX, size.y * 0.22);
    _titleText.anchor = Anchor.centerLeft;
    _titleText.position = Vector2(leftColX, size.y * 0.18 + 55);
    add(_titleText);

    // Description - More spacing from title
    _descriptionText = WrappedTextComponent(
      TextPainter(
        text: const TextSpan(
          text:
              "If you're curious to know more about what you saw, I invite you to contact me or follow me on social media.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: Colors.white70,
            height: 1.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      contentWidth,
    );
    _descriptionText.position = Vector2(leftColX, size.y * 0.48);
    add(_descriptionText);

    final iconY = size.y * 0.72;
    _addSocialIcon(Icons.email, Vector2(leftColX, iconY));
    _addSocialIcon(Icons.camera_alt, Vector2(leftColX + 70, iconY));
    _addSocialIcon(Icons.link, Vector2(leftColX + 140, iconY));
    double formY = size.y * 0.30;
    final formSpacing = 120.0;

    _addFormField("Name", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    _addFormField("Email", Vector2(rightColX, formY), contentWidth);
    formY += formSpacing;

    _addFormField(
      "How can I help you?",
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += 180;

    _sendButton = RectangleComponent(
      size: Vector2(180, 55),
      paint: Paint()..color = Colors.white,
      position: Vector2(rightColX + contentWidth - 180, formY),
    );
    add(_sendButton);

    _sendButtonText = TextComponent(
      text: "SEND",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,

          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 2.0,
        ),
      ),
    );
    _sendButtonText.anchor = Anchor.center;
    _sendButtonText.position = _sendButton.size / 2;
    _sendButton.add(_sendButtonText);
  }

  void _addSocialIcon(IconData icon, Vector2 pos) {
    final box =
        RectangleComponent(
            position: pos,
            size: Vector2(45, 45),
            paint: Paint()..color = Colors.white,
          )
          ..paint.style = PaintingStyle.stroke
          ..paint.strokeWidth = 2;
    add(box);
  }

  void _addFormField(String label, Vector2 pos, double width) {
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      position: pos,
    );
    add(text);

    final line = RectangleComponent(
      position: Vector2(pos.x, pos.y + 40),
      size: Vector2(width, 1),
      paint: Paint()..color = Colors.white54,
    );
    add(line);
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
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
