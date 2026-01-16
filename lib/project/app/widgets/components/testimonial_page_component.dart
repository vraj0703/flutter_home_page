import 'package:flame/components.dart';
import 'package:flame/effects.dart'; // Add this
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';
import 'package:flutter_home_page/project/app/widgets/components/testimonial_carousel_component.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';

class TestimonialPageComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  TestimonialPageComponent({super.size});

  late TextComponent titleText;
  late TestimonialCarouselComponent carousel;
  late RectangleComponent addButton;

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (!isLoaded) return;

    // Title Opacity
    final dimWhite = Colors.white.withValues(alpha: val);
    titleText.textRenderer = TextPaint(
      style: (titleText.textRenderer as TextPaint).style.copyWith(
        color: dimWhite,
      ),
    );

    // Children Opacity
    carousel.opacity = val;
    addButton.opacity = val;
    for (final child in addButton.children) {
      if (child is TextComponent) {
        child.textRenderer = TextPaint(
          style: (child.textRenderer as TextPaint).style.copyWith(
            color: Colors.black.withValues(alpha: val),
          ),
        );
      }
    }
  }

  @override
  Future<void> onLoad() async {
    // Title
    titleText = TextComponent(
      text: "TESTIMONIALS",
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'ModrntUrban',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(
            alpha: opacity,
          ), // Apply initial opacity
          letterSpacing: 2.0,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y * 0.15),
    );
    add(titleText);

    // Carousel
    carousel = TestimonialCarouselComponent(data: testimonialData);
    carousel.position = Vector2(size.x / 2, size.y * 0.5);
    carousel.anchor = Anchor.center;
    carousel.opacity = opacity; // Apply initial opacity
    add(carousel);

    // Add Button
    addButton = RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()..color = const Color(0xFFC78E53),
      position: Vector2(size.x / 2, size.y * 0.85),
      anchor: Anchor.center,
    );
    addButton.opacity = opacity;
    // Add label to button
    final btnLabel = TextComponent(
      text: "Add Testimonial",
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black.withValues(alpha: opacity),
        ),
      ),
      anchor: Anchor.center,
      position: addButton.size / 2,
    );
    addButton.add(btnLabel);
    add(addButton);

    // Make button interactive? Ideally use TapUser implementation but simple is fine.
  }

  void updateScroll(double delta) {
    if (isLoaded) {
      carousel.updateScroll(delta);
    }
  }
}
