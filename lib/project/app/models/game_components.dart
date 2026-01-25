import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/cloud_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

class GameComponents {
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent interactiveUI;
  //final RectangleComponent dimLayer;
  final GodRayComponent godRay;
  final BackgroundTintComponent backgroundTint;
  final BoldTextRevealComponent boldTextReveal;
  final CloudBackgroundComponent cloudBackground;
  final PhilosophyTextComponent philosophyText;
  final PeelingCardStackComponent cardStack;
  final PhilosophyTrailComponent philosophyTrail;
  final WorkExperienceTitleComponent workExperienceTitle;
  final ExperiencePageComponent experiencePage;
  final TestimonialPageComponent testimonialPage;
  final ContactPageComponent contactPage;

  GameComponents({
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.interactiveUI,
    //required this.dimLayer,
    required this.godRay,
    required this.backgroundTint,
    required this.boldTextReveal,
    required this.cloudBackground,
    required this.philosophyText,
    required this.cardStack,
    required this.philosophyTrail,
    required this.workExperienceTitle,
    required this.experiencePage,
    required this.testimonialPage,
    required this.contactPage,
  });

  void hideAllSectionComponents() {
    // Reset all section components to hidden/transparent state
    cinematicTitle.opacity = 0.0;
    cinematicSecondaryTitle.opacity = 0.0;

    // BoldText might utilize scrollProgress for visibility, but setting opacity 0 ensures it's hidden.
    // Assuming BoldTextRevealComponent respects opacity (standard PositionComponent).
    boldTextReveal.opacity = 0.0;

    // cloudBackground is managed by PhilosophyManager, don't reset it here
    philosophyText.opacity = 0.0;
    cardStack.opacity = 0.0;
    philosophyTrail.opacity = 0.0;
    workExperienceTitle.opacity = 0.0;
    experiencePage.opacity = 0.0;
    testimonialPage.opacity = 0.0;
    contactPage.opacity = 0.0;

    // GodRay and BackgroundTint are global/persistent or handled separately?
    // User said "component of each section". GodRay is background.
    // BackgroundTint is background.
    // DimLayer is distinct.
    //dimLayer.opacity = 0.0;
  }
}
