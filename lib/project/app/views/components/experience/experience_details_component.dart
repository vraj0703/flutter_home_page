import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_description_item.dart';

class DetailCanvas extends PositionComponent with HasPaint {
  final List<ExperienceNode> data;
  final List<ExperienceDescriptionItem> _items = [];

  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.0;

  double _parentOpacity = 1.0;
  int _activeIndex = 0;

  DetailCanvas({required this.data, super.position});

  @override
  set opacity(double val) {
    if (super.opacity == val) return;
    super.opacity = val;
    _parentOpacity = val;
    // Update active item immediately
    if (_activeIndex < _items.length) {
      _items[_activeIndex].opacity = val;
    }
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < data.length; i++) {
      final item = ExperienceDescriptionItem(description: data[i].description);
      // Position them all at (0,0) or offset?
      // They should be positioned relative to this component.
      // ChronosGearComponent positions DetailCanvas at (0,0)?
      // No, ChronosGearComponent adds it.
      // We should center them or align them.
      // Let's assume Top-Left alignment for now, controlled by DetailCanvas position.
      item.position = Vector2(0, 0);
      item.opacity = (i == 0) ? activeOpacity : inactiveOpacity;
      _items.add(item);
      add(item);
    }
    _activeIndex = 0;
  }

  void show(int index) {
    if (index < 0 || index >= _items.length) return;

    // Fade out current
    if (_activeIndex < _items.length) {
      final oldItem = _items[_activeIndex];
      oldItem.add(
        OpacityEffect.to(
          0.0,
          EffectController(duration: 0.3, curve: Curves.easeOut),
        ),
      );
    }

    _activeIndex = index;

    // Fade in new
    final newItem = _items[index];
    newItem.opacity = 0.0; // Ensure starts at 0
    newItem.add(
      OpacityEffect.to(
        _parentOpacity,
        EffectController(duration: 0.4, curve: Curves.easeIn, startDelay: 0.2),
      ),
    );
  }
}
