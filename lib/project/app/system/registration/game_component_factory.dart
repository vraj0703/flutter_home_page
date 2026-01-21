import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/system/scroll/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/cloud_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';

// Registration imports
import 'package:flutter_home_page/project/app/system/registration/component_registry.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/system/builders/background_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/logo_layer_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/page_builders.dart';
import 'package:flutter_home_page/project/app/system/builders/title_builders.dart';

class GameComponentFactory {
  // Fields to store component instances
  late RayMarchingShadowComponent shadowScene;
  late LogoComponent logoComponent;
  late GodRayComponent godRay;
  late LogoOverlayComponent logoOverlay;
  late BackgroundRunComponent backgroundRun;
  late BackgroundTintComponent backgroundTint;
  late CinematicTitleComponent cinematicTitle;
  late CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  late BoldTextRevealComponent boldTextReveal;
  late RectangleComponent dimLayer;
  late CloudBackgroundComponent cloudBackground;
  late PhilosophyTextComponent philosophyText;
  late PeelingCardStackComponent cardStack;
  late WorkExperienceTitleComponent workExperienceTitle;
  late ExperiencePageComponent experiencePage;
  late TestimonialPageComponent testimonialPage;
  late ContactPageComponent contactPage;

  // Initialize all components
  Future<void> initializeComponents({
    required Vector2 size,
    required StateProvider stateProvider,
    required Queuer queuer,
    required ScrollOrchestrator scrollOrchestrator,
    required material.Color Function() backgroundColorCallback,
    void Function(int section)? onSectionTap,
  }) async {
    final registry = ComponentRegistry();

    // Register all builders
    registry.register(ShadowSceneBuilder());
    registry.register(LogoComponentBuilder());
    registry.register(LogoOverlayBuilder());
    registry.register(GodRayBuilder());

    registry.register(BackgroundRunBuilder());
    registry.register(BackgroundTintBuilder());
    registry.register(CloudBackgroundBuilder());
    registry.register(DimLayerBuilder());

    registry.register(CinematicTitleBuilder());
    registry.register(CinematicSecondaryTitleBuilder());
    registry.register(BoldTextRevealBuilder());
    registry.register(WorkExperienceTitleBuilder());

    registry.register(PhilosophyTextBuilder());
    registry.register(PeelingCardStackBuilder());
    registry.register(ExperiencePageBuilder());
    registry.register(TestimonialPageBuilder());
    registry.register(ContactPageBuilder());

    // Asset Caching
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

    // Assign to fields for backward compatibility
    shadowScene = registry.get(ComponentIds.shadowScene);
    logoComponent = registry.get(ComponentIds.logo);
    godRay = registry.get(ComponentIds.godRay);
    logoOverlay = registry.get(ComponentIds.logoOverlay);

    backgroundRun = registry.get(ComponentIds.backgroundRun);
    backgroundTint = registry.get(ComponentIds.backgroundTint);
    cloudBackground = registry.get(ComponentIds.cloudBackground);
    dimLayer = registry.get(ComponentIds.dimLayer);

    cinematicTitle = registry.get(ComponentIds.cinematicTitle);
    cinematicSecondaryTitle = registry.get(
      ComponentIds.cinematicSecondaryTitle,
    );
    boldTextReveal = registry.get(ComponentIds.boldTextReveal);
    workExperienceTitle = registry.get(ComponentIds.workExperienceTitle);

    philosophyText = registry.get(ComponentIds.philosophyText);
    cardStack = registry.get(ComponentIds.cardStack);
    experiencePage = registry.get(ComponentIds.experiencePage);
    testimonialPage = registry.get(ComponentIds.testimonialPage);
    contactPage = registry.get(ComponentIds.contactPage);
  }

  // Get all components for easy addition
  List<Component> get allComponents => [
    shadowScene,
    logoComponent,
    godRay,
    logoOverlay,
    backgroundRun,
    backgroundTint,
    cinematicTitle,
    cinematicSecondaryTitle,
    boldTextReveal,
    dimLayer,
    cloudBackground,
    philosophyText,
    cardStack,
    workExperienceTitle,
    experiencePage,
    testimonialPage,
    contactPage,
  ];
}
