import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';

class ShadowSceneBuilder extends ComponentBuilder<RayMarchingShadowComponent> {
  @override
  String get id => ComponentIds.shadowScene;

  @override
  int get priority => 0;

  @override
  Future<RayMarchingShadowComponent> build(ComponentContext context) async {
    final logoImage = await context.loadImage(GameAssets.logo);
    final godRaysShader = await context.loadShader(GameAssets.godRaysShader);

    final startZoom = GameLayout.logoInitialScale;
    final baseLogoSize = Vector2(
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final logoSize = baseLogoSize * startZoom;

    final component = RayMarchingShadowComponent(
      fragmentShader: godRaysShader,
      logoImage: logoImage,
      logoSize: logoSize,
    );
    component.logoPosition = context.size / 2;
    return component;
  }
}
