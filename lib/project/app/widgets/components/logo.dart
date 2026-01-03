import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

class LogoComponent extends PositionComponent {
  final FragmentShader shader;
  final Image logoTexture;
  final Color tintColor;
  late final Paint _paint;

  LogoComponent({
    required this.shader,
    required this.logoTexture,
    required this.tintColor,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    // Create a Paint object that uses the shader and tints the result
    _paint = Paint()
      ..shader = shader
      ..colorFilter = ColorFilter.mode(
        tintColor,
        BlendMode.srcIn, // Apply tint to the shader's output
      );
  }

  @override
  void render(Canvas canvas) {
    // Set the uniforms for our logo.frag shader
    // Index 0: uSize (vec2)
    // Sampler 0: uLogoTexture (sampler2D)
    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setImageSampler(0, logoTexture);

    // Draw a rectangle covering the component's size
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}


class RayMarchingShadowComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final FragmentShader fragmentShader;
  final Image logoImage;
  Vector2 logoSize;
  Vector2 logoPosition = Vector2.zero();

  final Paint _paint = Paint();

  Vector2 lightPosition = Vector2.zero();
  Vector2 lightDirection = Vector2.zero();

  RayMarchingShadowComponent({
    required this.fragmentShader,
    required this.logoImage,
    required this.logoSize,
  });

  @override
  void render(Canvas canvas) {
    size = game.size;
    if (size.x == 0 || size.y == 0) return;

    // --- Uniform Mapping ---
    fragmentShader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, lightPosition.x)
      ..setFloat(3, lightPosition.y)
      ..setFloat(4, logoPosition.x)
      ..setFloat(5, logoPosition.y)
      ..setFloat(6, logoSize.x)
      ..setFloat(7, logoSize.y)
      ..setFloat(8, lightDirection.x)
      ..setFloat(9, lightDirection.y)
      ..setImageSampler(0, logoImage);

    _paint.shader = fragmentShader;
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}
