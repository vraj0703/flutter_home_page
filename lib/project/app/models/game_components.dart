import 'package:flame/components.dart';
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
import 'package:flutter_home_page/project/app/views/components/work_experience_title_component.dart';

class GameComponents {
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent interactiveUI;
  final RectangleComponent dimLayer;
  final BoldTextRevealComponent boldTextReveal;
  final PhilosophyTextComponent philosophyText;
  final PeelingCardStackComponent cardStack;
  final WorkExperienceTitleComponent workExperienceTitle;
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
    required this.workExperienceTitle,
    required this.experiencePage,
    required this.testimonialPage,
    required this.skillsPage,
    required this.contactPage,
  });
}
