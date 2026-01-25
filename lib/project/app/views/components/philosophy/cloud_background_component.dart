import 'dart:ui';
import 'package:flame/components.dart';

class CloudBackgroundComponent extends PositionComponent with HasGameReference {
  final FragmentShader shader;

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

  /// Warmup logic
  int _warmupFrames = 0;

  CloudBackgroundComponent({super.size, required this.shader}) {
    // Start with tiny opacity to force a render path (warmup)
    opacity = 0.001;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Set size to game size (full screen)
    final recorder = PictureRecorder();
    final _ = Canvas(recorder);
    final picture = recorder.endRecording();
    _dummyTexture = await picture.toImage(1, 1);

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

    // Shader Warmup: Render the first few frames to compile pipeline state
    if (_warmupFrames < 3) {
      _warmupFrames++;
      if (_warmupFrames == 3) {
        // Only reset if it hasn't been changed externally (e.g. by manager)
        if (opacity <= 0.002) {
          opacity = 0.0;
        }
      }
    }

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

    double texW = 0.0;
    double texH = 0.0;
    Image samplerImage = _dummyTexture;

    try {
      if (_textTexture != null) {
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
      final screenPos = game.camera.viewfinder.transform.globalToLocal(
        Vector2(_centerX, _textY),
      );
      final screenWaterY = game.camera.viewfinder.transform
          .globalToLocal(Vector2(0, _waterY))
          .y;

      shader.setFloat(0, size.x);
      shader.setFloat(1, size.y);
      shader.setFloat(2, _time);
      shader.setFloat(3, _textY); // uTextY (Screen)
      shader.setFloat(4, _waterY); // uWaterY (Screen)
      shader.setFloat(5, _textOpacity);
      shader.setFloat(6, _textScale);
      shader.setFloat(7, texW);
      shader.setFloat(8, texH);
      shader.setFloat(9, screenPos.x); // uTextX (Screen)
      shader.setFloat(10, dpr); // uPixelRatio

      // Set sampler (safe image)
      shader.setImageSampler(0, samplerImage);

      // Always draw to prevent black screen
      canvas.drawRect(size.toRect(), Paint()..shader = shader);
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
