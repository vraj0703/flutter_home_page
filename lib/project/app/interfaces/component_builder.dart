import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';

abstract class ComponentBuilder<T extends Component> {
  String get id;
  int get priority;
  Future<T> build(ComponentContext context);
}
