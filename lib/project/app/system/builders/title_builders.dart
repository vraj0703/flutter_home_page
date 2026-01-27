import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';

class CinematicTitleBuilder extends ComponentBuilder<CinematicTitleComponent> {
  @override
  String get id => ComponentIds.cinematicTitle;

  @override
  int get priority => 0;

  @override
  Future<CinematicTitleComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = CinematicTitleComponent(
      primaryText: GameStrings.primaryTitle,
      shader: shader,
      position: context.size / 2,
    );
    component.priority = GameLayout.zTitle;
    return component;
  }
}

class CinematicSecondaryTitleBuilder
    extends ComponentBuilder<CinematicSecondaryTitleComponent> {
  @override
  String get id => ComponentIds.cinematicSecondaryTitle;

  @override
  int get priority => 0;

  @override
  Future<CinematicSecondaryTitleComponent> build(
    ComponentContext context,
  ) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = CinematicSecondaryTitleComponent(
      text: GameStrings.secondaryTitle,
      shader: shader,
      position: context.size / 2 + GameLayout.secTitleOffsetVector,
    );
    component.priority = GameLayout.zSecondaryTitle;
    return component;
  }
}
