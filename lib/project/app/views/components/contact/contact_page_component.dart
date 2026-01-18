import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
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
    final leftColX = size.x * GameLayout.contactLeftColRelX;
    final rightColX = size.x * GameLayout.contactRightColRelX;
    final contentWidth = size.x * GameLayout.contactContentRelW;

    _titleText = FadeTextComponent(
      text: GameStrings.contactTitle,
      textStyle: TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.contactTitleFontSize,
        fontWeight: FontWeight.bold,
      ),
      shader: shader,
      baseColor: GameStyles.silverText,
    );
    _titleText.anchor = Anchor.centerLeft;
    _titleText.position = Vector2(
      leftColX,
      size.y * GameLayout.contactTitleRelY,
    );
    add(_titleText);

    // Description
    _descriptionText = WrappedTextComponent(
      TextPainter(
        text: const TextSpan(
          text: GameStrings.contactDescription,
          style: TextStyle(
            fontFamily: GameStyles.fontInter,
            fontSize: GameStyles.contactDescriptionFontSize,
            color: GameStyles.white70,
            height: 1.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
      contentWidth,
    );
    _descriptionText.position = Vector2(
      leftColX,
      size.y * GameLayout.contactDescRelY,
    );
    add(_descriptionText);

    final iconY = size.y * GameLayout.contactIconRelY;
    final iconGap = 70.0;
    _addSocialIcon(Icons.email, Vector2(leftColX, iconY));
    _addSocialIcon(Icons.camera_alt, Vector2(leftColX + iconGap, iconY));
    _addSocialIcon(Icons.link, Vector2(leftColX + (iconGap * 2), iconY));

    double formY = size.y * GameLayout.contactFormRelY;
    final formSpacing = GameLayout.contactFormSpacing;

    _addFormField(
      GameStrings.contactNameLabel,
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += formSpacing;

    _addFormField(
      GameStrings.contactEmailLabel,
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += formSpacing;

    _addFormField(
      GameStrings.contactMessageLabel,
      Vector2(rightColX, formY),
      contentWidth,
    );
    formY += 180;

    _sendButton = RectangleComponent(
      size: Vector2(GameLayout.contactButtonW, GameLayout.contactButtonH),
      paint: Paint()..color = Colors.white,
      position: Vector2(
        rightColX + contentWidth - GameLayout.contactButtonW,
        formY,
      ),
    );
    add(_sendButton);

    _sendButtonText = TextComponent(
      text: GameStrings.contactSendButton,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.buttonFontSize,
          fontWeight: FontWeight.bold,
          color: GameStyles.black,
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
            size: Vector2(GameLayout.iconSize, GameLayout.iconSize),
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
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.formLabelFontSize,
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
      paint: Paint()..color = GameStyles.white54,
    );
    add(line);
  }

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;
    for (final child in children) {
      if (child is TextComponent) {
        final style = (child.textRenderer as TextPaint).style;
        if (style.color != null) {
          child.textRenderer = TextPaint(
            style: style.copyWith(color: style.color!.withValues(alpha: val)),
          );
        }
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
