import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/models/game_components.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/contact_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/experience_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/background_tint_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/god_ray_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/work_experience_title_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_effects/opacity.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/opacity/opacity_observer.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/testimonial_page_controller.dart';
import 'scroll_effects/parallax.dart';

class GameScrollConfigurator {
  GodRayController? _godRayController;

  GodRayController? get godRayController => _godRayController;

  void configureGlobal({
    required ScrollOrchestrator scrollOrchestrator,
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // --- Global Effects ---
    scrollOrchestrator.addBinding(
      components.dimLayer,
      OpacityScrollEffect(
        startScroll: ScrollSequenceConfig.dimLayerStart,
        endScroll: ScrollSequenceConfig.dimLayerEnd,
        startOpacity: 0.0,
        endOpacity: ScrollSequenceConfig.dimLayerFinalAlpha,
        curve: GameCurves.smoothDecel,
      ),
    );

    // --- Controllers ---
    _godRayController = GodRayController(
      component: components.godRay,
      screenSize: screenSize,
    );
    scrollSystem.register(_godRayController!);

    scrollSystem.register(
      BackgroundTintController(component: components.backgroundTint),
    );
  }

  void configureTitle({required GameComponents components}) {
    // Restore opacity for Title state (after animation, before scroll)
    components.cinematicTitle.opacity = 1.0;
    components.cinematicTitle.scale = Vector2.all(1.0);
    components.cinematicSecondaryTitle.opacity = 1.0;
    components.cinematicSecondaryTitle.scale = Vector2.all(1.0);
  }

  void configureBoldText({
    required ScrollOrchestrator scrollOrchestrator,
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
    required StateProvider stateProvider,
  }) {
    // Reset positions for parallax components to ensure we don't strict-accumulate offsets
    // if re-entering state.
    // Title is centered.
    components.cinematicTitle.position = screenSize / 2;
    components.cinematicTitle.scale = Vector2.all(1.0);
    // Secondary title has offset.
    components.cinematicSecondaryTitle.position =
        screenSize / 2 + GameLayout.secTitleOffsetVector;
    components.cinematicSecondaryTitle.scale = Vector2.all(1.0);

    // --- Parallax Effects ---
    scrollOrchestrator.addBinding(
      components.cinematicTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.titleParallaxEnd,
        // Now it's safe to use current position which we just reset
        initialPosition: components.cinematicTitle.position.clone(),
        endOffset: GameLayout.parallaxEndVector,
        curve: GameCurves.defaultSpring,
      ),
    );

    scrollOrchestrator.addBinding(
      components.cinematicSecondaryTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.secondaryTitleParallaxEnd,
        initialPosition: components.cinematicSecondaryTitle.position.clone(),
        endOffset: GameLayout.parallaxEndVector,
        curve: GameCurves.logoSpring,
      ),
    );

    // --- Opacity Effects ---
    scrollOrchestrator.addBinding(
      components.cinematicTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.titleFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      components.cinematicSecondaryTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.secondaryTitleFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      components.interactiveUI,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.uiFadeEnd,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    components.boldTextReveal.opacity = 1.0;
    scrollSystem.register(
      BoldTextController(
        component: components.boldTextReveal,
        screenWidth: screenSize.x,
        centerPosition: screenSize / 2,
      ),
    );

    scrollSystem.register(OpacityObserver(stateProvider: stateProvider));
  }

  void configurePhilosophy({
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // Reset positions
    components.philosophyText.position = Vector2(
      screenSize.x * GameLayout.philosophyTextXRatio,
      screenSize.y / 2,
    );
    components.cardStack.position = Vector2(
      screenSize.x * GameLayout.cardStackXRatio,
      screenSize.y / 2,
    );

    scrollSystem.register(
      PhilosophyPageController(
        component: components.philosophyText,
        cardStack: components.cardStack,
        initialTextPos: components.philosophyText.position.clone(),
        initialStackPos: components.cardStack.position.clone(),
      ),
    );
  }

  void configureWorkExperience({
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // Reset position
    components.workExperienceTitle.position =
        screenSize / 2 + Vector2(0, screenSize.y);
    // Opacity managed by controller, but ensure it's "active" for logic if needed.
    // Actually, hideAll sets it to 0. Controller should set it to correct value on first frame.
    // No change needed here.

    scrollSystem.register(
      WorkExperienceTitleController(
        component: components.workExperienceTitle,
        screenHeight: screenSize.y,
        centerPosition: screenSize / 2,
      ),
    );
  }

  void configureExperience({
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // Reset position
    components.experiencePage.position = Vector2.zero();

    scrollSystem.register(
      ExperiencePageController(component: components.experiencePage),
    );
  }

  void configureTestimonials({
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // Reset position
    components.testimonialPage.position = Vector2.zero();

    scrollSystem.register(
      TestimonialPageController(component: components.testimonialPage),
    );
  }

  void configureContact({
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
  }) {
    // Reset position
    components.contactPage.position = Vector2(0, screenSize.y);

    scrollSystem.register(
      ContactPageController(
        component: components.contactPage,
        screenHeight: screenSize.y,
      ),
    );
  }
}
