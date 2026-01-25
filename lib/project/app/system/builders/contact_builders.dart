import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';

class ContactPageBuilder extends ComponentBuilder<ContactPageComponent> {
  @override
  String get id => ComponentIds.contactPage;

  @override
  int get priority => 0;

  @override
  Future<ContactPageComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = ContactPageComponent(size: context.size, shader: shader);
    component.priority = GameLayout.zContact;
    component.position = Vector2(0, context.size.y);
    return component;
  }
}
