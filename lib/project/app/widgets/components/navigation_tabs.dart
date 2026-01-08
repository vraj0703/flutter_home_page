import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

import 'fade_text.dart';

class NavigationTabsComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final List<String> items = ["Vishal Raj", "Testimonials", "Resume"];
  final List<FadeTextComponent> _textComponents = [];
  final FragmentShader shader;
  bool _isShown = false;
  bool get isShown => _isShown;

  NavigationTabsComponent({required this.shader}) {
    priority = 100; // Ensure it's above background and logo
  }

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < items.length; i++) {
      final text = FadeTextComponent(
        text: items[i],
        textStyle: const TextStyle(
          fontSize: 20,
          letterSpacing: 2,
          fontFamily: "ModrntUrban",
        ),
        shader: shader,
        // Initial position will be set by updateLayout
        position: Vector2.zero(),
        anchor: Anchor.center,
      )..opacity = 0;

      _textComponents.add(text);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
  }

  void show() {
    if (_isShown) return;
    _isShown = true;

    for (int i = 0; i < _textComponents.length; i++) {
      if (_textComponents[i].parent == null) {
        add(_textComponents[i]);
      }

      _textComponents[i].removeAll(_textComponents[i].children.query<Effect>());

      // Reset
      final isFirst = i == 0;
      final startY = isFirst ? 60.0 : 70.0;
      final targetY = 60.0;

      _textComponents[i].opacity = 0;
      _textComponents[i].position.y = startY;

      // 2. Add Effects
      // First tab appears immediately to replace Title. Others stagger.
      double delay = i * 0.1;

      // Fade In
      // If first tab, appear instantly to match the end of Title animation
      final fadeDuration = isFirst ? 0.0 : 0.6;
      _textComponents[i].add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: fadeDuration, startDelay: delay),
        ),
      );

      // Move Up (Only for non-first tabs, or redundant for first if start=target)
      if (!isFirst) {
        _textComponents[i].add(
          MoveToEffect(
            Vector2(_textComponents[i].position.x, targetY),
            EffectController(duration: 0.4, startDelay: delay),
          ),
        );
      } else {
        // Ensure it's exactly at target
        _textComponents[i].position.y = targetY;
      }
    }
  }

  void updateLayout(Vector2 screenSize, {double minX = 0}) {
    if (items.isEmpty) return;

    final tabWidth = 100.0; // Est width per tab
    final gap = 30.0;
    final totalWidth = (items.length * tabWidth) + ((items.length - 1) * gap);

    // Calculate centered startX
    double startX = (screenSize.x - totalWidth) / 2 + (tabWidth / 2);

    // Clamp to minX (ensure we don't overlap with left elements)
    // Add a safety buffer to minX
    final safeMinX = minX + (tabWidth / 2) + 20; // 20px buffer
    if (startX < safeMinX) {
      startX = safeMinX;
    }

    for (int i = 0; i < _textComponents.length; i++) {
      final x = startX + (i * (tabWidth + gap));
      // Standard Header Y = 60
      _textComponents[i].position = Vector2(x, 60);
    }
  }

  /// Calculates the position of the first tab without applying it or showing tabs.
  Vector2 getFirstTabPosition(Vector2 screenSize, {double minX = 0}) {
    if (items.isEmpty) return Vector2.zero();
    final tabWidth = 100.0;
    final gap = 30.0;
    final totalWidth = (items.length * tabWidth) + ((items.length - 1) * gap);
    double startX = (screenSize.x - totalWidth) / 2 + (tabWidth / 2);
    final safeMinX = minX + (tabWidth / 2) + 20;
    if (startX < safeMinX) {
      startX = safeMinX;
    }
    return Vector2(startX, 60);
  }

  void hide() {
    if (!_isShown) return;
    _isShown = false;
    for (var tab in _textComponents) {
      tab.removeAll(tab.children.query<Effect>());
      tab.add(OpacityEffect.to(0.0, EffectController(duration: 0.4)));
    }
  }

  void setActive(int index) {
    for (int i = 0; i < _textComponents.length; i++) {
      // Subtle scale effect for active tab
      double targetScale = (i == index) ? 1.2 : 1.0;
      _textComponents[i].add(
        ScaleEffect.to(
          Vector2.all(targetScale),
          EffectController(duration: 0.3),
        ),
      );
    }
  }
}
