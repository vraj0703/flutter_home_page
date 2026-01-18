import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/models/game_components.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/contact_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/experience_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/work_experience_title_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/opacity.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/parallax.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll_controller/skills_page_controller.dart';
import 'package:flutter_home_page/project/app/system/ui_opacity_observer.dart';
import 'scroll_controller/testimonial_page_controller.dart';

class GameScrollConfigurator {
  void configureScroll({
    required ScrollOrchestrator scrollOrchestrator,
    required ScrollSystem scrollSystem,
    required GameComponents components,
    required Vector2 screenSize,
    required StateProvider stateProvider,
  }) {
    // Reset Scroll
    scrollSystem.setScrollOffset(0.0);

    // Initial Show
    components.cinematicTitle.show(() {});
    components.cinematicSecondaryTitle.show(() {});

    // --- Parallax Effects ---
    scrollOrchestrator.addBinding(
      components.cinematicTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: ScrollSequenceConfig.titleParallaxEnd,
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
    scrollSystem.register(
      BoldTextController(
        component: components.boldTextReveal,
        screenWidth: screenSize.x,
        centerPosition: screenSize / 2,
      ),
    );

    scrollSystem.register(
      PhilosophyPageController(
        component: components.philosophyText,
        cardStack: components.cardStack,
        initialTextPos: components.philosophyText.position.clone(),
        initialStackPos: components.cardStack.position.clone(),
      ),
    );

    scrollSystem.register(
      WorkExperienceTitleController(
        component: components.workExperienceTitle,
        screenHeight: screenSize.y,
        centerPosition: screenSize / 2,
      ),
    );

    scrollSystem.register(
      ExperiencePageController(component: components.experiencePage),
    );

    scrollSystem.register(UIOpacityObserver(stateProvider: stateProvider));

    scrollSystem.register(
      TestimonialPageController(component: components.testimonialPage),
    );

    scrollSystem.register(
      SkillsPageController(component: components.skillsPage),
    );

    scrollSystem.register(
      ContactPageController(
        component: components.contactPage,
        screenHeight: screenSize.y,
      ),
    );
  }
}
