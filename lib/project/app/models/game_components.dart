import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';

class GameComponents {
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  final LogoOverlayComponent interactiveUI;
  final BackgroundTintComponent backgroundTint;
  final BackgroundRunComponent backgroundRun;
  final BoldTextRevealComponent boldTextReveal;
  final BeachBackgroundComponent beachBackground;
  final PhilosophyTextComponent philosophyText;
  final GodRayComponent godRay;
  final PhilosophyTrailComponent philosophyTrail;

  GameComponents({
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
    required this.interactiveUI,
    required this.godRay,
    required this.backgroundTint,
    required this.backgroundRun,
    required this.boldTextReveal,
    required this.beachBackground,
    required this.philosophyText,
    required this.philosophyTrail,
  });
}
