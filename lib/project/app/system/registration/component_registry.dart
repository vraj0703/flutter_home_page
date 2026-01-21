import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';

class ComponentRegistry {
  final Map<String, ComponentBuilder> _builders = {};
  final Map<String, Component> _instances = {};

  void register(ComponentBuilder builder) {
    _builders[builder.id] = builder;
  }

  Future<void> initializeAll(ComponentContext context) async {
    // Sort builders by priority if needed, or just iterate
    // But some components might depend on others?
    // The original factory initialized sequentially.
    // We'll iterate through registered keys.

    // Note: If dependency management is needed, we might need a topological sort.
    // For now, we assume independent initialization or managed order via priority/list.
    // However, map order is not guaranteed.
    // Let's rely on explicit order or priority if provided, or simple iteration.

    // Better: Sort builders by priority.
    final sortedBuilders = _builders.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final builder in sortedBuilders) {
      final component = await builder.build(context);
      _instances[builder.id] = component;
    }
  }

  T get<T extends Component>(String id) {
    final component = _instances[id];
    if (component == null) {
      throw Exception('Component not found: $id');
    }
    if (component is! T) {
      throw Exception('Component $id is not of type $T');
    }
    return component;
  }

  List<Component> get allComponents => _instances.values.toList();
}
