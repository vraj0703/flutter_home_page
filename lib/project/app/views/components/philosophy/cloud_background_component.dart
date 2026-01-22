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

  /// Flag to track if warmup render has occurred
  bool _hasWarmedUp = false;

  @override
  Future<void> onLoad() async {
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
    // Warmup: render once invisibly to compile shader
    if (!_hasWarmedUp) {
      _warmupShader(canvas);
      _hasWarmedUp = true;
    }

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

  /// Pre-compile shader by rendering it once invisibly
  void _warmupShader(Canvas canvas) {
    // Set minimal uniforms
    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
    _shader.setFloat(2, 0.0);

    // Render to tiny 1x1 rect at opacity 0 (invisible but compiles shader)
    final warmupPaint = Paint()
      ..shader = _shader
      ..color = const Color(0x00000000);

    canvas.saveLayer(const Rect.fromLTWH(0, 0, 1, 1), warmupPaint);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), warmupPaint);
    canvas.restore();
  }
}
