import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';

class CursorDependentComponents {
  final GodRayComponent godRay;
  final RayMarchingShadowComponent shadowScene;
  final LogoOverlayComponent interactiveUI;
  final LogoComponent logoComponent;
  final CinematicTitleComponent cinematicTitle;
  final CinematicSecondaryTitleComponent cinematicSecondaryTitle;

  CursorDependentComponents({
    required this.godRay,
    required this.shadowScene,
    required this.interactiveUI,
    required this.logoComponent,
    required this.cinematicTitle,
    required this.cinematicSecondaryTitle,
  });
}
