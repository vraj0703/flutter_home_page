import 'dart:ui';
import 'package:flame/components.dart';

class CloudBackgroundComponent extends PositionComponent with HasGameReference {
  CloudBackgroundComponent({super.size});

  late FragmentShader _shader;

  /// 0.0 = Invisible, 1.0 = Fully Visible
  double opacity = 0.0;

  /// Time accumulator for shader animation
  double _time = 0.0;

  late Image _dummyTexture;

  /// Text reflection data for shader
  Image? _textTexture;
  double _textX = 0.0;
  double _textY = 0.0;
  double _waterY = 0.0;
  double _textOpacity = 0.0;
  double _textScale = 1.0;
  double _centerX = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Load Shader (Already registered in pubspec)
    final program = await FragmentProgram.fromAsset(
      'assets/shaders/beach.frag',
    );
    _shader = program.fragmentShader();

    // 2. Create dummy 1x1 transparent texture for shader sampler
    final recorder = PictureRecorder();
    final _ = Canvas(recorder);
    final picture = recorder.endRecording();
    _dummyTexture = await picture.toImage(1, 1);

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

    canvas.saveLayer(
      size.toRect(),
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
    );

    // Default reflection values (fallback to dummy)
    double texW = 0.0;
    double texH = 0.0;
    Image samplerImage = _dummyTexture;

    try {
      // Try to use text texture if available
      if (_textTexture != null) {
        // Accessing width/height checks for disposal
        texW = _textTexture!.width.toDouble();
        texH = _textTexture!.height.toDouble();
        samplerImage = _textTexture!;
      }
    } catch (_) {
      // Texture was likely disposed, fallback to dummy
    }

    try {
      // Set uniforms (always safe)
      double dpr = game.canvasSize.x / game.size.x;

      // Convert World Coordinates (Logic) to Screen Coordinates (Logic)
      // Flame 1.33: localToGlobal converts from Component-Local to Global (Screen/World Root).
      // If passing a point in World space, we treat it as local to the world root.
      // Actually, camera.worldToScreen replacement is often camera.globalToLocal if Camera is Global?
      // No, camera Viewfinder transforms World to Local.
      // Proper replacement for worldToScreen:
      final screenPos = game.camera.viewfinder.transform.globalToLocal(
        Vector2(_centerX, _textY),
      );
      final screenWaterY = game.camera.viewfinder.transform
          .globalToLocal(Vector2(0, _waterY))
          .y;

      _shader.setFloat(0, size.x);
      _shader.setFloat(1, size.y);
      _shader.setFloat(2, _time);
      _shader.setFloat(3, _textY); // uTextY (Screen)
      _shader.setFloat(4, _waterY); // uWaterY (Screen)
      _shader.setFloat(5, _textOpacity);
      _shader.setFloat(6, _textScale);
      _shader.setFloat(7, texW);
      _shader.setFloat(8, texH);
      _shader.setFloat(9, screenPos.x); // uTextX (Screen)
      _shader.setFloat(10, dpr); // uPixelRatio

      // Set sampler (safe image)
      _shader.setImageSampler(0, samplerImage);

      // Always draw to prevent black screen
      canvas.drawRect(size.toRect(), Paint()..shader = _shader);
    } catch (_) {
      // If shader draw fails, we might get black screen, but better than app crash
      // print('Shader draw error: $e');
    }

    canvas.restore();
  }

  /// Set text reflection data for shader rendering
  void setTextReflection({
    required Image? texture,
    required double textX, // Added textX parameter
    required double textY,
    required double waterY,
    required double textOpacity,
    required double textScale,
    required double centerX,
  }) {
    _textTexture = texture;
    _textX = textX; // Assigned textX to _textX field
    _textY = textY;
    _waterY = waterY;
    _textOpacity = textOpacity;
    _textScale = textScale;
    _centerX = centerX;
  }
}
