import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/system/contact_page_controller.dart';
import 'package:flutter_home_page/project/app/system/experience_page_controller.dart';
import 'package:flutter_home_page/project/app/system/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/opacity.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/parallax.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/skills_page_controller.dart';
import 'package:flutter_home_page/project/app/system/testimonial_page_controller.dart';
import 'package:flutter_home_page/project/app/system/ui_opacity_observer.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';

class GameComponents {
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent interactiveUI;
  final RectangleComponent dimLayer;
  final BoldTextRevealComponent boldTextReveal;
  final PhilosophyTextComponent philosophyText;
  final PeelingCardStackComponent cardStack;
  final ExperiencePageComponent experiencePage;
  final TestimonialPageComponent testimonialPage;
  final SkillsKeyboardComponent skillsPage;
  final ContactPageComponent contactPage;

  GameComponents({
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.interactiveUI,
    required this.dimLayer,
    required this.boldTextReveal,
    required this.philosophyText,
    required this.cardStack,
    required this.experiencePage,
    required this.testimonialPage,
    required this.skillsPage,
    required this.contactPage,
  });
}

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
        endScroll: 800,
        initialPosition: components.cinematicTitle.position.clone(),
        endOffset: Vector2(0, -1000),
        curve: const SpringCurve(mass: 1.0, stiffness: 180.0, damping: 12.0),
      ),
    );

    scrollOrchestrator.addBinding(
      components.cinematicSecondaryTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: 1000,
        initialPosition: components.cinematicSecondaryTitle.position.clone(),
        endOffset: Vector2(0, -1000),
        curve: const SpringCurve(mass: 0.8, stiffness: 200.0, damping: 10.0),
      ),
    );

    // --- Opacity Effects ---
    scrollOrchestrator.addBinding(
      components.cinematicTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 500,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      components.cinematicSecondaryTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      components.interactiveUI,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      components.dimLayer,
      OpacityScrollEffect(
        startScroll: 1500,
        endScroll: 2000,
        startOpacity: 0.0,
        endOpacity: 0.6,
        curve: Curves.easeOutQuart,
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
