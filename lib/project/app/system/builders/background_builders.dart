import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';

class BackgroundRunBuilder extends ComponentBuilder<BackgroundRunComponent> {
  @override
  String get id => ComponentIds.backgroundRun;

  @override
  int get priority => 0;

  @override
  Future<BackgroundRunComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.backgroundShader);
    return BackgroundRunComponent(
      shader: shader,
      size: context.size,
      priority: GameLayout.zBackground,
    );
  }
}

class BackgroundTintBuilder extends ComponentBuilder<BackgroundTintComponent> {
  @override
  String get id => ComponentIds.backgroundTint;

  @override
  int get priority => 0;

  @override
  Future<BackgroundTintComponent> build(ComponentContext context) async {
    final component = BackgroundTintComponent();
    component.size = context.size;
    component.priority = GameLayout.zBackground + 1;
    return component;
  }
}

class CloudBackgroundBuilder
    extends ComponentBuilder<BeachBackgroundComponent> {
  @override
  String get id => ComponentIds.cloudBackground;

  @override
  int get priority => 0;

  @override
  Future<BeachBackgroundComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.beachShader);
    final component = BeachBackgroundComponent(
      size: context.size,
      shader: shader,
    );
    component.opacity = 0.0;
    component.priority = 10;
    return component;
  }
}

class DimLayerBuilder extends ComponentBuilder<RectangleComponent> {
  @override
  String get id => ComponentIds.dimLayer;

  @override
  int get priority => 0;

  @override
  Future<RectangleComponent> build(ComponentContext context) async {
    return RectangleComponent(
      priority: GameLayout.zDimLayer,
      size: context.size,
      paint: Paint()..color = GameStyles.dimLayer.withValues(alpha: 0.0),
    );
  }
}
