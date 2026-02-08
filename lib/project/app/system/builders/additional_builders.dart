import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';

class SkillsKeyboardBuilder extends ComponentBuilder<SkillsKeyboardComponent> {
  @override
  String get id => ComponentIds.skillsKeyboard;

  @override
  int get priority => 0;

  @override
  Future<SkillsKeyboardComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = SkillsKeyboardComponent(
      size: context.size,
      metallicShader: shader,
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}

class TestimonialPageBuilder extends ComponentBuilder<TestimonialPageComponent> {
  @override
  String get id => ComponentIds.testimonialPage;

  @override
  int get priority => 0;

  @override
  Future<TestimonialPageComponent> build(ComponentContext context) async {
    // Reusing metallic or shine shader for title text inside
    final shader = await context.loadShader(GameAssets.shineShader);
    final component = TestimonialPageComponent(
      size: context.size,
      shader: shader,
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}

class ContactPageBuilder extends ComponentBuilder<ContactPageComponent> {
  @override
  String get id => ComponentIds.contactPage;

  @override
  int get priority => 0;

  @override
  Future<ContactPageComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.shineShader);
    final component = ContactPageComponent(
      size: context.size,
      shader: shader,
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}
