import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

class ExperiencePageBuilder extends ComponentBuilder<ExperiencePageComponent> {
  @override
  String get id => ComponentIds.experiencePage;

  @override
  int get priority => 0;

  @override
  Future<ExperiencePageComponent> build(ComponentContext context) async {
    final component = ExperiencePageComponent(size: context.size);
    component.priority = GameLayout.zContent;
    return component;
  }
}

class WorkExperienceTitleBuilder
    extends ComponentBuilder<WorkExperienceTitleComponent> {
  @override
  String get id => ComponentIds.workExperienceTitle;

  @override
  int get priority => 0;

  @override
  Future<WorkExperienceTitleComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = WorkExperienceTitleComponent(
      text: GameStrings.workExperienceTitle,
      textStyle: material.TextStyle(
        fontSize: 90,
        fontWeight: material.FontWeight.bold,
        fontFamily: GameStyles.fontModernUrban,
        letterSpacing: 4.0,
      ),
      shader: shader,
      baseColor: GameStyles.boldTextBase,
      position: context.size / 2 + Vector2(0, context.size.y),
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}
