import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_carousel_component.dart';
import 'package:flutter_home_page/project/app/models/testimonial_node.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class TestimonialPageComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  TestimonialPageComponent({super.size, required this.shader});

  final FragmentShader shader;
  late FadeTextComponent titleText;
  late TestimonialCarouselComponent carousel;
  late RectangleComponent addButton;

  @override
  set opacity(double val) {
    if (val == super.opacity) return;
    super.opacity = val;

    if (!isLoaded) return;

    // Title Opacity
    titleText.opacity = val;

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
    titleText = FadeTextComponent(
      text: "TESTIMONIALS",
      textStyle: TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
      shader: shader,
      baseColor: const Color(0xFFCCCCCC),
    );
    titleText.anchor = Anchor.topCenter;
    titleText.position = Vector2(size.x / 2, size.y * 0.15);
    titleText.opacity = opacity; // Ensure correct initial opacity
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
  }

  void updateScroll(double delta) {
    if (isLoaded) {
      carousel.updateScroll(delta);
    }
  }
}
