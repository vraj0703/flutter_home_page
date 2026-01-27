import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/system/builders/god_ray_builder.dart';
import 'package:flutter_home_page/project/app/system/builders/philosophy_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/shader_scene_builder.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_background.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';

// Registration imports
import 'package:flutter_home_page/project/app/system/registration/component_registry.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/system/builders/background_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/logo_layer_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/title_builders.dart';

class GameComponentFactory {
  // Initialize all components
  final registry = ComponentRegistry();

  Future<void> initializeComponents({
    required Vector2 size,
    required StateProvider stateProvider,
    required Queuer queuer,
    required ScrollOrchestrator scrollOrchestrator,
    required material.Color Function() backgroundColorCallback,
    void Function(int section)? onSectionTap,
  }) async {
    // Register all builders
    registry.register(ShadowSceneBuilder());
    registry.register(LogoComponentBuilder());
    registry.register(LogoOverlayBuilder());
    registry.register(GodRayBuilder());

    registry.register(BackgroundRunBuilder());
    registry.register(BackgroundTintBuilder());
    registry.register(CloudBackgroundBuilder());

    registry.register(CinematicTitleBuilder());
    registry.register(CinematicSecondaryTitleBuilder());
    registry.register(BoldTextRevealBuilder());

    registry.register(PhilosophyTextBuilder());
    registry.register(PhilosophyTrailBuilder());

    final shaderCache = <String, FragmentProgram>{};

    final context = ComponentContext(
      size: size,
      stateProvider: stateProvider,
      queuer: queuer,
      scrollOrchestrator: scrollOrchestrator,
      backgroundColorCallback: backgroundColorCallback,
      loadShader: (path) async {
        if (!shaderCache.containsKey(path)) {
          shaderCache[path] = await FragmentProgram.fromAsset(path);
        }
        return shaderCache[path]!.fragmentShader();
      },
      loadImage: (path) async {
        return Flame.images.load(path);
      },
    );

    // Initialize all components via registry
    await registry.initializeAll(context);
  }

  Component component(String id) => registry.get(id);

  // Get all components for easy addition
  List<Component> get allComponents => registry.allComponents;

  RayMarchingShadowComponent get shadowScene =>
      registry.get(ComponentIds.shadowScene);

  LogoComponent get logoComponent => registry.get(ComponentIds.logo);

  GodRayComponent get godRay => registry.get(ComponentIds.godRay);

  LogoOverlayComponent get logoOverlay =>
      registry.get(ComponentIds.logoOverlay);

  BackgroundRunComponent get backgroundRun =>
      registry.get(ComponentIds.backgroundRun);

  BackgroundTintComponent get backgroundTint =>
      registry.get(ComponentIds.backgroundTint);

  BeachBackgroundComponent get beachBackground =>
      registry.get(ComponentIds.cloudBackground);

  CinematicTitleComponent get cinematicTitle =>
      registry.get(ComponentIds.cinematicTitle);

  CinematicSecondaryTitleComponent get cinematicSecondaryTitle =>
      registry.get(ComponentIds.cinematicSecondaryTitle);

  BoldTextRevealComponent get boldTextReveal =>
      registry.get(ComponentIds.boldTextReveal);

  PhilosophyTextComponent get philosophyText =>
      registry.get(ComponentIds.philosophyText);

  PhilosophyTrailComponent get philosophyTrail =>
      registry.get(ComponentIds.philosophyTrail);
}
