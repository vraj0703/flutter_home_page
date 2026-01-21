import 'dart:ui' as ui;
import 'dart:ui' show Canvas, Color, Paint;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Cloud background component using clouds.frag shader
/// with cloud_noise.png texture sampler
class CloudBackgroundComponent extends PositionComponent {
  CloudBackgroundComponent({required Vector2 size}) : super(size: size);

  ui.FragmentShader? _shader;
  ui.Image? _noiseTexture;
  double _time = 0.0;
  double _opacity = 0.0;
  Vector2 _mousePosition = Vector2.zero();

  /// Control visibility (0.0 = invisible, 1.0 = fully visible)
  double get opacity => _opacity;
  set opacity(double value) {
    _opacity = value.clamp(0.0, 1.0);
  }

  /// Update mouse position for camera control
  void updateMousePosition(Vector2 position) {
    _mousePosition = position;
  }

  @override
  Future<void> onLoad() async {
    // Load shader
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/clouds.frag',
    );
    _shader = program.fragmentShader();

    // Load noise texture
    final ByteData data = await rootBundle.load(
      'assets/images/cloud_noise.png',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _noiseTexture = frame.image;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_shader == null || _noiseTexture == null || _opacity <= 0.0) return;

    // Set shader uniforms
    _shader!
      ..setFloat(0, size.x) // uSize.x
      ..setFloat(1, size.y) // uSize.y
      ..setFloat(2, _time) // uTime
      ..setFloat(3, _mousePosition.x) // uMouse.x
      ..setFloat(4, _mousePosition.y) // uMouse.y
      ..setImageSampler(0, _noiseTexture!); // uNoiseTexture

    // Apply opacity
    final paint = Paint()
      ..shader = _shader
      ..color = Color.fromRGBO(255, 255, 255, _opacity);

    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void onRemove() {
    _noiseTexture?.dispose();
    super.onRemove();
  }
}
