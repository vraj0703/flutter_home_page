import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';

class SkillsSection implements GameSection {
  final SkillsKeyboardComponent keyboardComponent;
  Vector2 screenSize;

  double _scrollProgress = 0.0;
  static const double _fadeInStart = 0.0;
  static const double _fadeInEnd = 800.0;
  static const double _visibleDuration = 1000.0; // Hold visible
  static const double _fadeOutStart = _fadeInEnd + _visibleDuration;
  static const double _fadeOutEnd = _fadeOutStart + 800.0;
  static const double _totalHeight = _fadeOutEnd;

  SkillsSection({required this.keyboardComponent, required this.screenSize});

  @override
  double get maxScrollExtent => _totalHeight;

  @override
  List<Vector2> get snapRegions => [
    Vector2(0, 0),
    Vector2(_fadeInEnd, _fadeOutStart), // Snap while visible
  ];

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onReverseComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  Future<void> warmUp() async {
    _scrollProgress = 0.0;
    keyboardComponent.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _scrollProgress = 0.0;
    keyboardComponent.opacity = 0.0;
    keyboardComponent.position = screenSize / 2;
    // Reset internal animation state if needed
    keyboardComponent.setEntranceProgress(0.0);
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _scrollProgress = _totalHeight;
    keyboardComponent.opacity = 0.0;
  }

  @override
  Future<void> exit() async {
    keyboardComponent.opacity = 0.0;
  }

  @override
  ScrollResult handleScroll(double delta) {
    final newScroll = _scrollProgress + delta;

    if (newScroll < 0) return ScrollUnderflow(newScroll);
    if (newScroll > _totalHeight) {
      return ScrollOverflow(newScroll - _totalHeight);
    }

    setScrollOffset(newScroll);
    return ScrollConsumed(newScroll);
  }

  @override
  void setScrollOffset(double offset) {
    _scrollProgress = offset;

    // Fade In
    if (_scrollProgress < _fadeInEnd) {
      final t = (_scrollProgress / _fadeInEnd).clamp(0.0, 1.0);
      keyboardComponent.opacity = t;
      // Animate keys entrance
      keyboardComponent.setEntranceProgress(t * 1.5); // Accelerate key entrance
    }
    // Hold Visible
    else if (_scrollProgress < _fadeOutStart) {
      keyboardComponent.opacity = 1.0;
      keyboardComponent.setEntranceProgress(1.0);
    }
    // Fade Out
    else {
      final t =
          ((_scrollProgress - _fadeOutStart) / (_fadeOutEnd - _fadeOutStart))
              .clamp(0.0, 1.0);
      keyboardComponent.opacity = 1.0 - t;
    }

    // Warm up next section
    if (_scrollProgress > _totalHeight - 500) {
      onWarmUpNextSection?.call();
    }
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    keyboardComponent.position = newSize / 2;
  }

  @override
  void update(double dt) {}

  @override
  void dispose() {}
}
