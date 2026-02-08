import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';

class ContactSection implements GameSection {
  final ContactPageComponent contactComponent;
  Vector2 screenSize;

  double _scrollProgress = 0.0;
  static const double _fadeInEnd = 800.0;
  static const double _visibleDuration = 1000.0;
  static const double _fadeOutStart = _fadeInEnd + _visibleDuration;
  static const double _fadeOutEnd = _fadeOutStart + 800.0;
  static const double _totalHeight = _fadeOutEnd;

  ContactSection({
    required this.contactComponent,
    required this.screenSize,
  });

  @override
  double get maxScrollExtent => _totalHeight;

  @override
  List<Vector2> get snapRegions => [
        Vector2(0, 0),
        Vector2(_fadeInEnd, _fadeOutStart),
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
    contactComponent.opacity = 0.0;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _scrollProgress = 0.0;
    contactComponent.opacity = 0.0;
    contactComponent.position = screenSize / 2;
    contactComponent.size = screenSize;
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    _scrollProgress = _totalHeight;
    contactComponent.opacity = 0.0;
  }

  @override
  Future<void> exit() async {
    contactComponent.opacity = 0.0;
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
      contactComponent.opacity = t;
    }
    // Hold Visible
    else if (_scrollProgress < _fadeOutStart) {
      contactComponent.opacity = 1.0;
    }
    // Fade Out
    else {
      final t =
          ((_scrollProgress - _fadeOutStart) / (_fadeOutEnd - _fadeOutStart))
              .clamp(0.0, 1.0);
      contactComponent.opacity = 1.0 - t;
    }

    // Warm up next section
    if (_scrollProgress > _totalHeight - 500) {
      onWarmUpNextSection?.call();
    }
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    contactComponent.position = newSize / 2;
    contactComponent.size = newSize;
  }

  @override
  void update(double dt) {}
}
