import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
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
  // ignore: library_private_types_in_public_api
  late _TappableButton addButton;

  /// Convenience accessor — delegates to the game-level notifier so the
  /// Flutter overlay in [StatefulScene] can listen to the same instance.
  ValueNotifier<bool> get showFormNotifier => game.showTestimonialForm;

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
      text: GameStrings.testimonialsTitle,
      textStyle: TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.testimonialTitleFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: GameStyles.testimonialTitleSpacing,
      ),
      shader: shader,
      baseColor: GameStyles.silverText,
    );
    titleText.anchor = Anchor.topCenter;
    titleText.position = Vector2(
      size.x / 2,
      size.y * GameLayout.testimonialTitleRelY,
    );
    titleText.opacity = opacity;
    add(titleText);

    // Carousel — use live data from BLoC if available, else hardcoded fallback.
    final liveData = game.testimonialNodes;
    carousel = TestimonialCarouselComponent(data: liveData ?? testimonialData);
    carousel.position = Vector2(
      size.x / 2,
      size.y * GameLayout.testimonialCarouselRelY,
    );
    carousel.anchor = Anchor.center;
    carousel.opacity = opacity;
    add(carousel);

    // Add Button (tappable)
    addButton = _TappableButton(
      size: GameLayout.testimonialButtonSize,
      paint: Paint()..color = GameStyles.accentGold,
      position: Vector2(size.x / 2, size.y * GameLayout.testimonialButtonRelY),
      onTap: () => showFormNotifier.value = true,
    );
    addButton.anchor = Anchor.center;
    addButton.opacity = opacity;

    // Add label to button
    final btnLabel = TextComponent(
      text: GameStrings.addTestimonialButton,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GameStyles.fontInter,
          fontSize: GameStyles.buttonFontSize,
          fontWeight: FontWeight.bold,
          color: GameStyles.uiBlack.withValues(alpha: opacity),
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

  bool get allTestimonialsFocused => isLoaded && carousel.allFocused;

  /// Replace the carousel data with fresh nodes from the BLoC.
  ///
  /// Removes the old carousel, creates a new one with the updated data,
  /// and adds it back to the component tree.
  void updateData(List<TestimonialNode> data) {
    if (!isLoaded) return;

    final oldOpacity = carousel.opacity;
    remove(carousel);

    carousel = TestimonialCarouselComponent(data: data);
    carousel.position = Vector2(
      size.x / 2,
      size.y * GameLayout.testimonialCarouselRelY,
    );
    carousel.anchor = Anchor.center;
    carousel.opacity = oldOpacity;
    add(carousel);
  }
}

/// A [RectangleComponent] that responds to taps within the Flame game tree.
class _TappableButton extends RectangleComponent with TapCallbacks {
  final VoidCallback onTap;

  _TappableButton({
    required super.size,
    required super.paint,
    required super.position,
    required this.onTap,
  });

  @override
  void onTapUp(TapUpEvent event) {
    onTap();
  }
}
