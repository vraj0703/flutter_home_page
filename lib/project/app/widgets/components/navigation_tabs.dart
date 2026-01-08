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
    priority = 25; // Ensure it's above background and logo
  }

  @override
  Future<void> onLoad() async {
    // Calculate initial centered layout to ensure correct placement on load
    final gap = 40.0;
    double totalWidth = 0;
    for (int i = 0; i < items.length; i++) {
      totalWidth += _getTabWidth(i);
    }
    if (items.isNotEmpty) {
      totalWidth += (items.length - 1) * gap;
    }

    double currentX = (game.size.x - totalWidth) / 2;
    final safeMinX = 20.0;
    if (currentX < safeMinX) currentX = safeMinX;

    for (int i = 0; i < items.length; i++) {
      final tabW = _getTabWidth(i);
      final centerX = currentX + (tabW / 2);
      final initialPos = Vector2(centerX, _getTabY(i));

      final text = FadeTextComponent(
        text: items[i],
        textStyle: const TextStyle(
          fontSize: 20,
          letterSpacing: 10,
          fontWeight: FontWeight.w500,
          fontFamily: "ModrntUrban",
        ),
        shader: shader,
        // Initial position set to correct layout immediately
        position: initialPos,
        anchor: Anchor.center,
      )..opacity = 0;

      _textComponents.add(text);

      currentX += tabW + gap;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
  }

  void show({bool hideFirst = false}) {
    if (_isShown) return;
    _isShown = true;

    for (int i = 0; i < _textComponents.length; i++) {
      if (_textComponents[i].parent == null) {
        add(_textComponents[i]);
      }

      _textComponents[i].removeAll(_textComponents[i].children.query<Effect>());

      // Reset
      final isFirst = i == 0;

      _textComponents[i].opacity = 0;
      // Ensure X is correct (redundant if loop above set it, but good for safety)
      // _textComponents[i].position.x is already set above.

      if (isFirst && hideFirst) continue;

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
    }
  }

  double _getTabWidth(int index) {
    // First tab ("Vishal Raj") is significantly wider due to spacing/scale
    return items[index].length * 25;
  }

  double _getTabY(int index) {
    return MyGame.headerY;
  }

  void updateLayout(Vector2 screenSize, {double minX = 0}) {
    if (items.isEmpty) return;

    final gap = 40.0;
    double totalWidth = 0;
    for (int i = 0; i < items.length; i++) {
      totalWidth += _getTabWidth(i);
    }
    totalWidth += (items.length - 1) * gap;

    // Calculate left edge of the entire block
    double currentX = (screenSize.x - totalWidth) / 2;

    // Clamp to minX
    final safeMinX = minX + 20; // 20px buffer
    if (currentX < safeMinX) {
      currentX = safeMinX;
    }

    for (int i = 0; i < _textComponents.length; i++) {
      final tabW = _getTabWidth(i);
      final centerX = currentX + (tabW / 2);

      _textComponents[i].position = Vector2(centerX, _getTabY(i));

      currentX += tabW + gap;
    }
  }

  /// Calculates the position of the first tab without applying it or showing tabs.
  Vector2 getFirstTabPosition(Vector2 screenSize, {double minX = 0}) {
    if (items.isEmpty) return Vector2.zero();
    return _textComponents.first.position;
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
