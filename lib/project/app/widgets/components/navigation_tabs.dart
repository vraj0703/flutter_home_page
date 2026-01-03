import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

import 'fade_text.dart';

class NavigationTabsComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final List<String> items = [
    "About me",
    "Coding",
    "Portfolio",
    "Contact me",
    "Resume",
  ];
  final List<FadeTextComponent> _textComponents = [];
  final FragmentShader shader;
  bool _isShown = false;

  NavigationTabsComponent({required this.shader}) {
    priority = 100; // Ensure it's above background and logo
  }

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < items.length; i++) {
      final text = FadeTextComponent(
        text: items[i],
        textStyle: const TextStyle(
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
        shader: shader,
        // Reuse metallic
        position: Vector2(500 + (i * 130), 70),
        // Adjust X starting position
        anchor: Anchor.center,
      )..opacity = 0;

      _textComponents.add(text);
      // add(text); // REMOVED: Lazy add in show()
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
  }

  void show() {
    if (_isShown) return; // Prevent re-triggering
    _isShown = true;

    for (int i = 0; i < _textComponents.length; i++) {
      // Lazy Add: Ensure component is in the tree
      if (_textComponents[i].parent == null) {
        add(_textComponents[i]);
      }

      _textComponents[i].removeAll(_textComponents[i].children.query<Effect>());

      // 1. Force Reset State
      _textComponents[i].opacity = 0;
      _textComponents[i].position.y = 70; // Reset to start Y

      // 2. Add Effects with startDelay (No WaitEffect needed)
      double delay = 0.5 + (i * 0.1);

      // Fade In
      _textComponents[i].add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: 0.6, startDelay: delay),
        ),
      );

      // Move Up (Target: 70 - 5 = 65)
      _textComponents[i].add(
        MoveToEffect(
          Vector2(_textComponents[i].position.x, 65),
          EffectController(duration: 0.4, startDelay: delay),
        ),
      );
    }
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
