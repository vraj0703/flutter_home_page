import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterComponent extends PositionComponent
    with HasGameReference<MyGame>
    implements OpacityProvider {
  // OpacityProvider
  double _opacity = 1.0;
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    _opacity = value;
    _updateOpacity(value);
  }

  late RectangleComponent background;
  late TextComponent tagline;
  late TextComponent copyright;
  final List<LinkComponent> linkComponents = [];

  @override
  Future<void> onLoad() async {
    // Background
    background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.8),
    );
    add(background);

    final margin = 60.0;

    // Tagline
    tagline = TextComponent(
      text: "Your Mobile Partner",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Broadway',
          letterSpacing: 1.5,
        ),
      ),
      position: Vector2(margin, 60),
    );
    add(tagline);

    // Links
    double currentY = 140;
    final links = [
      LinkData("Email", "mailto:vraj0703@gmail.com"),
      LinkData("LinkedIn", "https://linkedin.com/in/vraj0703"),
      LinkData("GitHub", "https://github.com/vraj0703"),
    ];

    for (final link in links) {
      final comp = LinkComponent(
        text: link.label,
        url: link.url,
        position: Vector2(margin, currentY),
      );
      add(comp);
      linkComponents.add(comp);
      currentY += 40;
    }

    // Copyright
    copyright = TextComponent(
      text: "© 2026 Vishal Raj. All rights reserved.",
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      position: Vector2(margin, size.y - 40),
    );
    add(copyright);

    _opacity = 0;
  }

  void _updateOpacity(double alpha) {
    if (!isLoaded) return;

    // Background
    background.paint.color = Colors.black.withValues(alpha: 0.8 * alpha);

    // Tagline
    tagline.textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Broadway',
        letterSpacing: 1.5,
      ).copyWith(color: Colors.white.withOpacity(alpha)),
    );

    // Copyright
    copyright.textRenderer = TextPaint(
      style: const TextStyle(color: Colors.white38, fontSize: 12).copyWith(
        color: Colors.white38.withOpacity(0.38 * alpha),
      ), // Fix logic if base is already transparent
    );
    // Wait, white38 is white with 0.38 opacity. .withOpacity(alpha) overrides it?
    // No, we want colors.white.withOpacity(0.38 * alpha).

    // Links
    for (final link in linkComponents) {
      link.opacity = alpha;
    }
  }
}

class LinkData {
  final String label;
  final String url;
  LinkData(this.label, this.url);
}

class LinkComponent extends PositionComponent with TapCallbacks, HasPaint {
  final String text;
  final String url;

  double _opacity = 1.0;

  set opacity(double value) {
    _opacity = value;
    _updateTextOpacity();
  }

  late TextComponent textComp;

  LinkComponent({
    required this.text,
    required this.url,
    required Vector2 position,
  }) : super(position: position, size: Vector2(200, 30));

  @override
  Future<void> onLoad() async {
    textComp = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC78E53),
          fontSize: 18,
          decoration: TextDecoration.underline,
        ),
      ),
    );
    add(textComp);
  }

  void _updateTextOpacity() {
    if (!isLoaded) return;
    final color = const Color(0xFFC78E53);
    textComp.textRenderer = TextPaint(
      style: TextStyle(
        color: color.withOpacity(_opacity),
        fontSize: 18,
        decoration: TextDecoration.underline,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    launchUrl(Uri.parse(url));
  }
}
