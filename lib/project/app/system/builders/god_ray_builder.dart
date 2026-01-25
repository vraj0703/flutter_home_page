import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';

class GodRayBuilder extends ComponentBuilder<GodRayComponent> {
  @override
  String get id => ComponentIds.godRay;

  @override
  int get priority => 0;

  @override
  Future<GodRayComponent> build(ComponentContext context) async {
    final component = GodRayComponent();
    component.priority = GameLayout.zGodRay;
    component.position = context.size / 2;
    return component;
  }
}
