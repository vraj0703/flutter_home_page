import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';

class PhilosophyTextBuilder extends ComponentBuilder<PhilosophyTextComponent> {
  @override
  String get id => ComponentIds.philosophyText;

  @override
  int get priority => 0;

  @override
  Future<PhilosophyTextComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = PhilosophyTextComponent(
      text: GameStrings.philosophyTitle,
      style: material.TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.philosophyFontSize,
        fontWeight: material.FontWeight.bold,
        color: GameStyles.philosophyText,
        letterSpacing: 1.5,
      ),
      shader: shader,
      anchor: Anchor.centerLeft,
      position: Vector2(
        context.size.x * GameLayout.philosophyTextXRatio,
        context.size.y / 2,
      ),
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}

class PeelingCardStackBuilder
    extends ComponentBuilder<PeelingCardStackComponent> {
  @override
  String get id => ComponentIds.cardStack;

  @override
  int get priority => 0;

  @override
  Future<PeelingCardStackComponent> build(ComponentContext context) async {
    final component = PeelingCardStackComponent(
      scrollOrchestrator: context.scrollOrchestrator,
      cardsData: cardData,
      size: Vector2(
        context.size.x * GameLayout.cardStackWidthRatio,
        context.size.y * GameLayout.cardStackHeightRatio,
      ),
      position: Vector2(
        context.size.x * GameLayout.cardStackXRatio,
        context.size.y / 2,
      ),
    );
    component.anchor = Anchor.center;
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}

class ExperiencePageBuilder extends ComponentBuilder<ExperiencePageComponent> {
  @override
  String get id => ComponentIds.experiencePage;

  @override
  int get priority => 0;

  @override
  Future<ExperiencePageComponent> build(ComponentContext context) async {
    final component = ExperiencePageComponent(size: context.size);
    component.priority = GameLayout.zContent;
    return component;
  }
}

class TestimonialPageBuilder
    extends ComponentBuilder<TestimonialPageComponent> {
  @override
  String get id => ComponentIds.testimonialPage;

  @override
  int get priority => 0;

  @override
  Future<TestimonialPageComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = TestimonialPageComponent(
      size: context.size,
      shader: shader,
    );
    component.priority = GameLayout.zContent;
    component.opacity = 0.0;
    return component;
  }
}

class ContactPageBuilder extends ComponentBuilder<ContactPageComponent> {
  @override
  String get id => ComponentIds.contactPage;

  @override
  int get priority => 0;

  @override
  Future<ContactPageComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.metallicShader);
    final component = ContactPageComponent(size: context.size, shader: shader);
    component.priority = GameLayout.zContact;
    component.position = Vector2(0, context.size.y);
    return component;
  }
}

class PhilosophyTrailBuilder
    extends ComponentBuilder<PhilosophyTrailComponent> {
  @override
  String get id => ComponentIds.philosophyTrail;

  @override
  int get priority => 0;

  @override
  Future<PhilosophyTrailComponent> build(ComponentContext context) async {
    final component =
        PhilosophyTrailComponent(); // Layout handled in onGameResize
    component.priority = -1; // Behind bold text? Or above?
    // Balloon is 20. Main content.
    // Trail cards should be above background (0) but maybe below balloon?
    // Or concurrent.
    // Let's set priority to GameLayout.zContent constant if available, or just 10.
    component.priority = GameLayout.zContent;
    component.opacity = 0.0; // Start hidden
    return component;
  }
}
