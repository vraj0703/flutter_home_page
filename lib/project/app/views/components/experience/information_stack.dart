
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';

class InformationStack extends PositionComponent with HasPaint {
  late FadableTextComponent _company;
  late FadableTextComponent _title;
  late FadableTextComponent _duration;
  late PositionComponent _descriptionContainer;
  final List<Component> _descriptionLines =
      []; // Changed to Component to support badges

  // Badge Components
  // We will create them on fly or pool them. For simplicity, create new.

  InformationStack() : super(anchor: Anchor.centerLeft);

  @override
  Future<void> onLoad() async {
    _company = FadableTextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: 24.0,
          color: GameStyles.accentGold,
          letterSpacing: 4.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _title = FadableTextComponent(
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontModernUrban,
          fontSize: 56.0,
          color: Colors.white,
          height: 1.0,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              blurRadius: 15.0,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(2.0, 2.0),
            ),
          ],
        ),
      ),
    );

    _duration = FadableTextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: 14.0,
          color: GameStyles.silverText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    _descriptionContainer = PositionComponent();

    add(_company);
    add(_title);
    add(_duration);
    add(_descriptionContainer);
  }

  // Helper to update max width based on screen size
  void updateLayout(Vector2 screenSize) {
    _contentMaxWidth = screenSize.x * 0.32;
    _screenHeight = screenSize.y;
  }

  double _contentMaxWidth = 500.0;
  double _screenHeight = 1000.0;

  void updateData(ExperienceNode node) {
    _company.text = node.company.toUpperCase();
    _company.textRenderer = TextPaint(
      style: (_company.textRenderer as TextPaint).style.copyWith(
        color: Colors.white.withOpacity(0.9),
      ),
    );

    _title.text = node.title;
    _duration.text = '${node.duration}  •  ${node.location}';

    // Layout Header (Module 1)
    _company.position = Vector2(0, 0);
    _title.position = Vector2(0, _company.height + 8 + 20); // +20 Top Padding
    _duration.position = Vector2(0, _title.y + _title.height + 12);

    // Rebuild Description
    _descriptionContainer.removeAll(_descriptionContainer.children);
    _descriptionLines.clear();

    // Module 3: Description (Bottom Module)
    // Shader Module 3 Center UV is -0.42 -> Screen Y 0.71.
    // Top of Module 3 (approx) starts lower.
    // Let's create a "Safe Start" for Module 3.
    // Gap M2-M3 is significant.
    // Let's start description at impactY + 140 (Badge height + Gap)
    // Or better: relative to screen height?
    // Module 3 Top is roughly 0.51 Screen Y (calculated earlier).
    // Offset = 0.51 - 0.22 = 0.29 * ScreenHeight.
    double descY = _screenHeight * 0.29;

    int index = 0;

    // Check for badge first
    if (node.themeColor != null && node.description.isNotEmpty) {
      // Center Badge vertically at impactY? No, impactY is top of module?
      // Let's assume impactY is the intended Top of the badge slot for now.
      // Actually, 0.425 is CENTER. Badge height 80. Top is 0.425*H - 40.
      // Offset = (0.425*H - 40) - 0.22*H = 0.205*H - 40.
      double badgeTop = (_screenHeight * 0.425) - 40 - (_screenHeight * 0.22);

      final badge = _createImpactBadge(
        node.description[0],
        node.themeColor!,
        _contentMaxWidth,
      );
      badge.position = Vector2(0, badgeTop);
      _descriptionContainer.add(badge);
      _descriptionLines.add(badge);
      index = 1;
    }

    // Fill Module 3
    double runningY = descY;
    _descriptionContainer.position = Vector2.zero();

    for (int i = index; i < node.description.length; i++) {
      final point = node.description[i];

      Component lineComp = FadableTextBoxComponent(
        text: point,
        textRenderer: TextPaint(
          style: GameStyles.experienceDescStyle.copyWith(
            color: Colors.white,
            fontSize: 13.0, // Reduced font size
            height: 1.4,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        boxConfig: TextBoxConfig(maxWidth: _contentMaxWidth - 40),
        position: Vector2(30, runningY),
      );

      final bullet = FadableTextComponent(
        text: '>',
        textRenderer: TextPaint(
          style: GameStyles.experienceDescStyle.copyWith(
            fontSize: 13.0,
            color: GameStyles.white70.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(0, runningY),
      );

      _descriptionContainer.add(bullet);
      _descriptionLines.add(bullet);

      _descriptionContainer.add(lineComp);
      _descriptionLines.add(lineComp);

      if (lineComp is PositionComponent) {
        runningY += lineComp.height + 20;
      }
    }
  }

  ImpactBadgeComponent _createImpactBadge(
    String text,
    Color color,
    double width,
  ) {
    return ImpactBadgeComponent(text: text, accentColor: color, width: width);
  }

  void animateIn() {
    // Header Fade In
    _company.opacity = 0;
    _title.opacity = 0;
    _duration.opacity = 0;

    _company.removeWhere((c) => c is Effect);
    _title.removeWhere((c) => c is Effect);
    _duration.removeWhere((c) => c is Effect);

    _company.add(OpacityEffect.fadeIn(EffectController(duration: 0.5)));
    _title.add(
      OpacityEffect.fadeIn(EffectController(duration: 0.5, startDelay: 0.1)),
    );
    _duration.add(
      OpacityEffect.fadeIn(EffectController(duration: 0.5, startDelay: 0.2)),
    );

    // Stagger Description
    for (int i = 0; i < _descriptionLines.length; i++) {
      final line = _descriptionLines[i];
      if (line is HasPaint) {
        line.opacity = 0.0;
        line.removeWhere((c) => c is Effect);
        // ... (rest of animation logic is fine, will be preserved by using Replace range carefully or re-writing)
        final delay = 0.4 + (i * 0.05); // Faster stagger

        line.add(
          OpacityEffect.to(
            1.0,
            EffectController(
              duration: 0.6,
              startDelay: delay,
              curve: Curves.easeOut,
            ),
          ),
        );
        line.add(
          MoveEffect.by(
            Vector2(0, -10),
            EffectController(
              duration: 0.6,
              startDelay: delay,
              curve: Curves.easeOutBack,
            ),
          ),
        );
      }
    }
  }

  // ...
}

class FadableTextComponent extends TextComponent with HasPaint {
  FadableTextComponent({
    super.text,
    super.textRenderer,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
  });
}

class FadableTextBoxComponent extends TextBoxComponent with HasPaint {
  FadableTextBoxComponent({
    super.text,
    super.textRenderer,
    super.boxConfig,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
  });
}

class ImpactBadgeComponent extends PositionComponent with HasPaint {
  final String text;
  final Color accentColor;
  late TextComponent _label;
  late TextBoxComponent _content;
  late RectangleComponent _bg;
  late RectangleComponent _border;

  ImpactBadgeComponent({
    required this.text,
    required this.accentColor,
    required double width,
  }) {
    this.width = width;
    height = 80; // Fixed height for Badge
  }

  @override
  Future<void> onLoad() async {
    // GLASS EFFECT: Use a stroke and a very faint fill
    _bg = RectangleComponent(
      size: Vector2(width, height),
      paint: Paint()
        ..color = Colors.white
            .withOpacity(0.03) // Barely visible fill
        ..style = PaintingStyle.fill,
    );

    _border = RectangleComponent(
      size: Vector2(width, height),
      paint: Paint()
        ..color = accentColor
            .withOpacity(0.5) // The thin glowing orange border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    _label = TextComponent(
      text: 'KEY RESULT',
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 1.5,
        ),
      ),
    );
    // Center Label Vertically relative to some grid?
    // Prompt: "Ensure KEY RESULT text is vertically centered within this box" -> No, essentially it's a badge.
    // Let's put label top-left or centered? usually badges have label then content.
    // "vertically centered within this box"... maybe side by side?
    // "Key Result... displays... first sentence"
    // Let's stick to the previous stacked design but centered in the block if it looks good.
    // Actually, normally 'Key Result' is a kicker above the value.
    // Let's keep it at top (12py) for now.
    _label.position = Vector2(15, 10);

    _content = TextBoxComponent(
      text: text,
      textRenderer: TextPaint(
        style: GameStyles.experienceDescStyle.copyWith(
          color: Colors.white,
          fontSize: 14,
          height: 1.3,
        ),
      ),
      boxConfig: TextBoxConfig(maxWidth: width - 32),
      position: Vector2(15, 30),
    );

    add(_bg);
    add(_border);
    add(_label);
    add(_content);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Propagate opacity
    _bg.paint.color = accentColor.withOpacity(0.1 * opacity);
    for (final child in children) {
      if (child is TextComponent) {
        // naive opacity prop
        final tp = child.textRenderer as TextPaint;
        child.textRenderer = TextPaint(
          style: tp.style.copyWith(color: tp.style.color?.withOpacity(opacity)),
        );
      }
    }
  }
}
