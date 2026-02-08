import 'package:flutter_home_page/project/app/views/components/experience/circles_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/next_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/rain_transition_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_rotator_component.dart';

class GameComponents {
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent logoOverlay;
  final BackgroundTintComponent backgroundTint;
  final BackgroundRunComponent backgroundRun;
  final BoldTextRevealComponent boldTextReveal;
  final BeachBackgroundComponent beachBackground;
  final PhilosophyTextComponent philosophyText;
  final GodRayComponent godRay;
  final PhilosophyTrailComponent philosophyTrail;
  final NextButtonComponent nextButton;
  final RainTransitionComponent rainTransition;
  final CirclesBackgroundComponent circlesBackground;
  final ExperienceRotatorComponent experienceRotator;
  //final SkillsKeyboardComponent skillsKeyboard;
  //final TestimonialPageComponent testimonialPage;
  //final ContactPageComponent contactPage;

  GameComponents({
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.logoOverlay,
    required this.godRay,
    required this.backgroundTint,
    required this.backgroundRun,
    required this.boldTextReveal,
    required this.beachBackground,
    required this.philosophyText,
    required this.philosophyTrail,
    required this.nextButton,
    required this.rainTransition,
    required this.circlesBackground,
    required this.experienceRotator,
    //required this.skillsKeyboard,
    //required this.testimonialPage,
   // required this.contactPage,
  });
}
