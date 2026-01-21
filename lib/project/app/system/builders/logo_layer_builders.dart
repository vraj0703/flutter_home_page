import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';

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

class LogoComponentBuilder extends ComponentBuilder<LogoComponent> {
  @override
  String get id => ComponentIds.logo;

  @override
  int get priority => 0;

  @override
  Future<LogoComponent> build(ComponentContext context) async {
    final logoImage = await context.loadImage(GameAssets.logo);
    final logoShader = await context.loadShader(GameAssets.logoShader);

    final startZoom = GameLayout.logoInitialScale;
    final baseLogoSize = Vector2(
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final logoSize = baseLogoSize * startZoom;
    final tintColor = context.backgroundColorCallback();

    final component = LogoComponent(
      shader: logoShader,
      logoTexture: logoImage,
      tintColor: tintColor,
      size: logoSize,
      position: context.size / 2,
    );
    component.priority = GameLayout.zLogo;
    return component;
  }
}

class LogoOverlayBuilder extends ComponentBuilder<LogoOverlayComponent> {
  @override
  String get id => ComponentIds.logoOverlay;

  @override
  int get priority => 0;

  @override
  Future<LogoOverlayComponent> build(ComponentContext context) async {
    final component = LogoOverlayComponent(
      stateProvider: context.stateProvider,
      queuer: context.queuer,
    );
    component.position = context.size / 2;
    component.priority = GameLayout.zLogoOverlay;
    component.gameSize = context.size;
    return component;
  }
}

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
