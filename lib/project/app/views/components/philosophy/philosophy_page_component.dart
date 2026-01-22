import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/cloud_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_card_stack.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class PhilosophyPageComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  final PhilosophyTextComponent textComponent;
  final PhilosophyCardStack cardStack;
  final CloudBackgroundComponent cloudBackground;

  PhilosophyPageComponent({
    required this.textComponent,
    required this.cardStack,
    required this.cloudBackground,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    // Add in order: Background -> Stack -> Text (Text on top? Stack is 3D, Text is 2D overlay title)
    // Cloud Background first
    add(cloudBackground);

    // Card Stack (3D elements)
    add(cardStack);

    // Text component
    add(textComponent);

    // Ensure visibility is reset
    cloudBackground.opacity = 0.0;
    cardStack.opacity = 0.0;
    textComponent.opacity = 0.0;
  }
}
