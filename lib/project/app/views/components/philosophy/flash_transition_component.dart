import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class FlashTransitionComponent extends PositionComponent
    with HasGameReference<MyGame> {
  late FragmentProgram _program;
  late FragmentShader _shader;
  bool _isReady = false;

  double _timer = 0.0;
  double _intensity = 0.0;

  // Timing
  final double attackDuration = 0.1; // 100ms to full white
  final double sustainDuration = 0.3; // Hold white during swap
  final double decayDuration = 0.8; // 800ms fade to reveal

  VoidCallback? onPeakReached; // Called when flash reaches full intensity
  VoidCallback? onComplete; // Called when flash finishes

  bool _peakCalled = false;
  bool _completeCalled = false;

  @override
  bool get debugMode => true; // Help visualize if something is wrong

  Future<void> loadShader() async {
    _program = await FragmentProgram.fromAsset(
      'assets/shaders/flash_transition.frag',
    );
    _shader = _program.fragmentShader();
    _isReady = true;
  }

  @override
  Future<void> onLoad() async {
    await loadShader();
    size = game.size;
    priority = 1000; // Ensure it renders on top of everything
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isReady) return;

    _timer += dt;

    if (_timer < attackDuration) {
      // Attack: 0.0 → 1.0
      double progress = _timer / attackDuration;
      _intensity = Curves.easeIn.transform(progress);
    } else if (_timer < attackDuration + sustainDuration) {
      // Sustain: Hold at 1.0
      _intensity = 1.0;

      // Trigger peak callback once
      if (!_peakCalled) {
        _peakCalled = true;
        onPeakReached?.call();
      }
    } else if (_timer < attackDuration + sustainDuration + decayDuration) {
      // Decay: 1.0 → 0.0
      double decayStart = attackDuration + sustainDuration;
      double decayProgress = (_timer - decayStart) / decayDuration;
      _intensity = 1.0 - Curves.easeOut.transform(decayProgress);
    } else {
      // Complete
      _intensity = 0.0;

      if (!_completeCalled) {
        _completeCalled = true;
        onComplete?.call();
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isReady || _intensity <= 0.0) return;

    // Create a picture for the background scene
    final recorder = PictureRecorder();
    final bgCanvas = Canvas(recorder);

    // Render all game components except this flash
    // (In practice, we'd render the current scene here)
    // For now, we'll use a placeholder black background
    final paint = Paint()..color = const Color(0xFF000000);
    bgCanvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.x.toInt(), size.y.toInt());

    // Set shader uniforms
    _shader.setFloat(0, size.x); // iResolution.x
    _shader.setFloat(1, size.y); // iResolution.y
    _shader.setFloat(2, _timer); // iTime
    _shader.setFloat(3, _intensity); // iFlashIntensity
    _shader.setImageSampler(0, image); // iChannel0

    // Render the shader
    final shaderPaint = Paint()..shader = _shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shaderPaint);

    image.dispose();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize; // Update PositionComponent size
  }
}
