import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';

class GameComponentFactory {
  // Fields to store component instances
  late RayMarchingShadowComponent shadowScene;
  late LogoComponent logoComponent;
  late GodRayComponent godRay;
  late LogoOverlayComponent interactiveUI;
  late BackgroundRunComponent backgroundRun;
  late CinematicTitleComponent cinematicTitle;
  late CinematicSecondaryTitleComponent cinematicSecondaryTitle;
  late BoldTextRevealComponent boldTextReveal;
  late RectangleComponent dimLayer;
  late PhilosophyTextComponent philosophyText;
  late PeelingCardStackComponent cardStack;
  late ExperiencePageComponent experiencePage;
  late TestimonialPageComponent testimonialPage;
  late SkillsKeyboardComponent skillsPage;
  late ContactPageComponent contactPage;

  late FragmentShader metallicShader;

  // Initialize all components
  Future<void> initializeComponents({
    required Vector2 size,
    required StateProvider stateProvider,
    required Queuer queuer,
    required ScrollOrchestrator scrollOrchestrator,
    required material.Color Function() backgroundColorCallback,
  }) async {
    // 1. Shaders & Images
    final logoImage = await _loadImage(GameAssets.logo);
    metallicShader = await _loadShader(GameAssets.metallicShader);
    final godRaysShader = await _loadShader(GameAssets.godRaysShader);
    final logoShader = await _loadShader(GameAssets.logoShader);
    final backgroundShader = await _loadShader(GameAssets.backgroundShader);

    // 2. Logo Layer
    final startZoom = GameLayout.logoInitialScale;
    final baseLogoSize = Vector2(
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final logoSize = baseLogoSize * startZoom;
    final tintColor = backgroundColorCallback();

    shadowScene = RayMarchingShadowComponent(
      fragmentShader: godRaysShader,
      logoImage: logoImage,
      logoSize: logoSize,
    );
    shadowScene.logoPosition = size / 2;

    logoComponent = LogoComponent(
      shader: logoShader,
      logoTexture: logoImage,
      tintColor: tintColor,
      size: logoSize,
      position: size / 2,
    );
    logoComponent.priority = GameLayout.zLogo;

    godRay = GodRayComponent();
    godRay.priority = GameLayout.zGodRay;
    godRay.position = size / 2;

    // 3. Interactive UI
    interactiveUI = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    interactiveUI.position = size / 2;
    interactiveUI.priority = GameLayout.zUI;
    interactiveUI.gameSize = size;

    // 4. Background & Titles
    backgroundRun = BackgroundRunComponent(
      shader: backgroundShader,
      size: size,
      priority: GameLayout.zBackground,
    );

    cinematicTitle = CinematicTitleComponent(
      primaryText: GameStrings.primaryTitle,
      shader: metallicShader,
      position: size / 2,
    );
    cinematicTitle.priority = GameLayout.zTitle;

    cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: GameStrings.secondaryTitle,
      shader: metallicShader,
      position: size / 2 + Vector2(0, GameLayout.secTitleYOffset),
    );
    cinematicSecondaryTitle.priority = GameLayout.zSecondaryTitle;

    boldTextReveal = BoldTextRevealComponent(
      text: GameStrings.boldText,
      textStyle: material.TextStyle(
        fontSize: GameStyles.titleFontSize,
        fontWeight: material.FontWeight.w500,
        fontFamily: GameStyles.fontInconsolata,
        letterSpacing: 2.0,
      ),
      shader: metallicShader,
      baseColor: GameStyles.boldTextBase,
      position: size / 2,
    );
    boldTextReveal.priority = GameLayout.zBoldText;
    boldTextReveal.opacity = 0.0;

    dimLayer = RectangleComponent(
      priority: GameLayout.zDimLayer,
      size: size,
      paint: Paint()..color = GameStyles.dimLayer.withValues(alpha: 0.0),
    );

    // 5. Scrollable Pages
    philosophyText = PhilosophyTextComponent(
      text: GameStrings.philosophyTitle,
      style: material.TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.philosophyFontSize,
        fontWeight: material.FontWeight.bold,
        color: GameStyles.philosophyText,
        letterSpacing: 1.5,
      ),
      shader: metallicShader,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * GameLayout.philosophyTextXRatio, size.y / 2),
    );
    philosophyText.priority = GameLayout.zContent;
    philosophyText.opacity = 0.0;

    cardStack = PeelingCardStackComponent(
      scrollOrchestrator: scrollOrchestrator,
      cardsData: cardData,
      size: Vector2(
        size.x * GameLayout.cardStackWidthRatio,
        size.y * GameLayout.cardStackHeightRatio,
      ),
      position: Vector2(size.x * GameLayout.cardStackXRatio, size.y / 2),
    );
    cardStack.anchor = Anchor.center;
    cardStack.priority = GameLayout.zContent;
    cardStack.opacity = 0.0;

    experiencePage = ExperiencePageComponent(size: size);
    experiencePage.priority = GameLayout.zContent;

    testimonialPage = TestimonialPageComponent(
      size: size,
      shader: metallicShader,
    );
    testimonialPage.priority = GameLayout.zContent;
    testimonialPage.opacity = 0.0;

    skillsPage = SkillsKeyboardComponent(size: size);
    skillsPage.priority = GameLayout.zSkills;
    skillsPage.opacity = 0.0;

    contactPage = ContactPageComponent(size: size, shader: metallicShader);
    contactPage.priority = GameLayout.zContact;
    contactPage.position = Vector2(0, size.y);
  }

  // Get all components for easy addition
  List<Component> get allComponents => [
    shadowScene,
    logoComponent,
    godRay,
    interactiveUI,
    backgroundRun,
    cinematicTitle,
    cinematicSecondaryTitle,
    boldTextReveal,
    dimLayer,
    philosophyText,
    cardStack,
    experiencePage,
    testimonialPage,
    skillsPage,
    contactPage,
  ];

  // Helper loading methods
  Future<FragmentShader> _loadShader(String path) async {
    final program = await FragmentProgram.fromAsset(path);
    return program.fragmentShader();
  }

  Future<Image> _loadImage(String path) async {
    final sprite = await Sprite.load(path);
    return sprite.image;
  }
}
