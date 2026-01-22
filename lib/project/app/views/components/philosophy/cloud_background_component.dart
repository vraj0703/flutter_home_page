import 'dart:ui';
import 'package:flame/components.dart';

class CloudBackgroundComponent extends PositionComponent with HasGameReference {
  CloudBackgroundComponent({super.size});

  late FragmentShader _shader;
  // late Image _blueNoise; // Unused in beach.frag
  // late Image _cloudNoise; // Unused in beach.frag

  /// 0.0 = Invisible, 1.0 = Fully Visible
  double opacity = 0.0;

  /// Time accumulator for shader animation
  double _time = 0.0;

  @override
  Future<void> onLoad() async {
    priority = -100; // Ensure it renders behind everything
    await super.onLoad();

    // 1. Load Shader (Already registered in pubspec)
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/beach.frag',
    );
    _shader = program.fragmentShader();

    // 2. Load Noise Textures - REMOVED for beach.frag (procedural)

    // Set size to game size (full screen)
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (opacity <= 0.0) return; // Optimization

    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;

    // Uniform mapping for beach.frag:
    // 0: uSize.x
    // 1: uSize.y
    // 2: uTime (float)

    // Set Float Uniforms
    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
    _shader.setFloat(2, _time);

    // No Samplers needed for beach.frag

    canvas.saveLayer(
      size.toRect(),
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
    );

    canvas.drawRect(size.toRect(), Paint()..shader = _shader);

    canvas.restore();
  }
}
