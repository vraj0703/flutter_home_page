import 'package:flame/components.dart';
import 'scroll_effects/scroll_effect.dart';
import '../interfaces/scroll_observer.dart';

/// Binds components to specific scroll effects and triggers them.
class ScrollOrchestrator implements ScrollObserver {
  final Map<PositionComponent, List<ScrollEffect>> _bindings = {};

  /// Bind a component to a single effect.
  void addBinding(PositionComponent component, ScrollEffect effect) {
    if (!_bindings.containsKey(component)) {
      _bindings[component] = [];
    }
    _bindings[component]!.add(effect);
  }

  /// Bind a component to multiple effects.
  void addBindings(PositionComponent component, List<ScrollEffect> effects) {
    if (!_bindings.containsKey(component)) {
      _bindings[component] = [];
    }
    _bindings[component]!.addAll(effects);
  }

  /// Remove all effects for a component.
  void removeBinding(PositionComponent component) {
    _bindings.remove(component);
  }

  @override
  void onScroll(double scrollOffset) {
    // Iterate over all bindings and apply effects
    _bindings.forEach((component, effects) {
      for (final effect in effects) {
        effect.apply(component, scrollOffset);
      }
    });
  }
}
