import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
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
    final logoImage = await _loadImage('logo.png');
    metallicShader = await _loadShader('assets/shaders/metallic_text.frag');
    final godRaysShader = await _loadShader('assets/shaders/god_rays.frag');
    final logoShader = await _loadShader('assets/shaders/logo.frag');
    final backgroundShader = await _loadShader(
      'assets/shaders/background_run_v2.frag',
    );

    // 2. Logo Layer
    final startZoom = 3.0;
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
    logoComponent.priority = 10;

    godRay = GodRayComponent();
    godRay.priority = 20;
    godRay.position = size / 2;

    // 3. Interactive UI
    interactiveUI = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    interactiveUI.position = size / 2;
    interactiveUI.priority = 30;
    interactiveUI.gameSize = size;

    // 4. Background & Titles
    backgroundRun = BackgroundRunComponent(
      shader: backgroundShader,
      size: size,
      priority: 1,
    );

    cinematicTitle = CinematicTitleComponent(
      primaryText: "VISHAL RAJ",
      shader: metallicShader,
      position: size / 2,
    );
    cinematicTitle.priority = 25;

    cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: "Welcome to my space",
      shader: metallicShader,
      position: size / 2 + Vector2(0, 48),
    );
    cinematicSecondaryTitle.priority = 24;

    boldTextReveal = BoldTextRevealComponent(
      text: "Crafting Clarity from Chaos.",
      textStyle: material.TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w500,
        fontFamily: 'InconsolataNerd',
        letterSpacing: 2.0,
      ),
      shader: metallicShader,
      baseColor: const material.Color(0xFFE3E4E5),
      position: size / 2,
    );
    boldTextReveal.priority = 26;
    boldTextReveal.opacity = 0.0;

    dimLayer = RectangleComponent(
      priority: 2,
      size: size,
      paint: Paint()
        ..color = const material.Color(0xFF000000).withValues(alpha: 0.0),
    );

    // 5. Scrollable Pages
    philosophyText = PhilosophyTextComponent(
      text: "My Philosophy",
      style: material.TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: material.Colors.white,
        letterSpacing: 1.5,
      ),
      shader: metallicShader,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * 0.15, size.y / 2),
    );
    philosophyText.priority = 25;
    philosophyText.opacity = 0.0;

    cardStack = PeelingCardStackComponent(
      scrollOrchestrator: scrollOrchestrator,
      cardsData: cardData,
      size: Vector2(size.x * 0.4, size.y * 0.6),
      position: Vector2(size.x * 0.75, size.y / 2),
    );
    cardStack.anchor = Anchor.center;
    cardStack.priority = 25;
    cardStack.opacity = 0.0;

    experiencePage = ExperiencePageComponent(size: size);
    experiencePage.priority = 25;

    testimonialPage = TestimonialPageComponent(
      size: size,
      shader: metallicShader,
    );
    testimonialPage.priority = 25;
    testimonialPage.opacity = 0.0;

    skillsPage = SkillsKeyboardComponent(size: size);
    skillsPage.priority = 28;
    skillsPage.opacity = 0.0;

    contactPage = ContactPageComponent(size: size, shader: metallicShader);
    contactPage.priority = 30;
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
