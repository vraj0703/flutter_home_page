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
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart'; // Needed for CardStack
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';

class GameComponentFactory {
  Future<FragmentShader> loadShader(String path) async {
    final program = await FragmentProgram.fromAsset(path);
    return program.fragmentShader();
  }

  Future<Image> loadImage(String path) async {
    final sprite = await Sprite.load(path);
    return sprite.image;
  }

  Future<RayMarchingShadowComponent> createShadowScene({
    required Vector2 size,
    required Image logoImage,
    required Vector2 logoSize,
  }) async {
    final shader = await loadShader('assets/shaders/god_rays.frag');
    final component = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: logoImage,
      logoSize: logoSize,
    );
    component.logoPosition = size / 2;
    return component;
  }

  Future<LogoComponent> createLogoComponent({
    required Vector2 size,
    required Image logoImage,
    required Vector2 logoSize,
    required Color tintColor,
  }) async {
    final shader = await loadShader('assets/shaders/logo.frag');
    final component = LogoComponent(
      shader: shader,
      logoTexture: logoImage,
      tintColor: tintColor,
      size: logoSize,
      position: size / 2,
    );
    component.priority = 10;
    return component;
  }

  GodRayComponent createGodRay(Vector2 size) {
    final component = GodRayComponent();
    component.priority = 20;
    component.position = size / 2;
    return component;
  }

  LogoOverlayComponent createInteractiveUI({
    required Vector2 size,
    required StateProvider stateProvider,
    required Queuer queuer,
  }) {
    final component = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    component.position = size / 2;
    component.priority = 30;
    component.gameSize = size;
    return component;
  }

  Future<BackgroundRunComponent> createBackgroundRun(Vector2 size) async {
    final shader = await loadShader('assets/shaders/background_run_v2.frag');
    return BackgroundRunComponent(shader: shader, size: size, priority: 1);
  }

  CinematicTitleComponent createCinematicTitle({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = CinematicTitleComponent(
      primaryText: "VISHAL RAJ",
      shader: shader,
      position: size / 2,
    );
    component.priority = 25;
    return component;
  }

  CinematicSecondaryTitleComponent createCinematicSecondaryTitle({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = CinematicSecondaryTitleComponent(
      text: "Welcome to my space",
      shader: shader,
      position: size / 2 + Vector2(0, 48),
    );
    component.priority = 24;
    return component;
  }

  BoldTextRevealComponent createBoldTextReveal({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = BoldTextRevealComponent(
      text: "Crafting Clarity from Chaos.",
      textStyle: material.TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w500,
        fontFamily: 'InconsolataNerd',
        letterSpacing: 2.0,
      ),
      shader: shader,
      baseColor: const Color(0xFFE3E4E5),
      position: size / 2,
    );
    component.priority = 26;
    component.opacity = 0.0;
    return component;
  }

  RectangleComponent createDimLayer(Vector2 size) {
    return RectangleComponent(
      priority: 2,
      size: size,
      paint: Paint()..color = const Color(0xFF000000).withValues(alpha: 0.0),
    );
  }

  PhilosophyTextComponent createPhilosophyText({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = PhilosophyTextComponent(
      text: "My Philosophy",
      style: material.TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: material.Colors.white,
        letterSpacing: 1.5,
      ),
      shader: shader,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * 0.15, size.y / 2),
    );
    component.priority = 25;
    component.opacity = 0.0;
    return component;
  }

  PeelingCardStackComponent createCardStack({
    required Vector2 size,
    required ScrollOrchestrator scrollOrchestrator,
  }) {
    final component = PeelingCardStackComponent(
      scrollOrchestrator: scrollOrchestrator,
      cardsData: cardData, // Global from card_data.dart
      size: Vector2(size.x * 0.4, size.y * 0.6),
      position: Vector2(size.x * 0.75, size.y / 2),
    );
    component.anchor = Anchor.center;
    component.priority = 25;
    component.opacity = 0.0;
    return component;
  }

  ExperiencePageComponent createExperiencePage(Vector2 size) {
    final component = ExperiencePageComponent(size: size);
    component.priority = 25;
    return component;
  }

  TestimonialPageComponent createTestimonialPage({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = TestimonialPageComponent(size: size, shader: shader);
    component.priority = 25;
    component.opacity = 0.0;
    return component;
  }

  SkillsKeyboardComponent createSkillsPage(Vector2 size) {
    final component = SkillsKeyboardComponent(size: size);
    component.priority = 28;
    component.opacity = 0.0;
    return component;
  }

  ContactPageComponent createContactPage({
    required Vector2 size,
    required FragmentShader shader,
  }) {
    final component = ContactPageComponent(size: size, shader: shader);
    component.priority = 30;
    component.position = Vector2(0, size.y);
    return component;
  }
}
