import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flame/events.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/shatter_effect.dart';

class RainTransitionComponent extends PositionComponent
    with HasGameReference<MyGame>, DragCallbacks, HasPaint {
  final ui.FragmentShader shader;
  double _time = 0.0;
  double currentIntensity = 0.0;
  double lightningIntensity = 0.0;
  double _crackStrength = 0.0; // Synced from Orchestrator
  double shatterProgress = 0.0;
  double _waterY = 0.5;
  double _strikeSeed = 0.0;
  double _targetIntensity = 0.0;
  ui.VoidCallback? onShatterComplete;
  ui.Image? _noiseTexture;
  bool _isShattering = false;

  void setCrackStrength(double val) => _crackStrength = val;
  void setShatterProgress(double val) => shatterProgress = val;
  void setWaterY(double val) => _waterY = val;
  void setStrikeSeed(double val) => _strikeSeed = val;

  void triggerShatter() {
    if (_isShattering) return;
    _isShattering = true;

    // Add the ShatterEffect controller
    game.add(
      ShatterEffect(
        rainTransition: this,
        onFinish: () {
          // Cleanup after visual shatter is done
          opacity = 0.0;
          onShatterComplete?.call();
        },
      ),
    );
  }

  bool _textureInitialized = false;
  ui.Image? _backgroundTexture;
  final double _lerpFactor = 4.0;

  // Track finger position for the shader
  Vector2 _mousePos = Vector2(-1000, -1000); // Start off-screen

  RainTransitionComponent({required this.shader, super.size}) {
    _initEmptyBackground();
  }

  void setTarget(double val) => _targetIntensity = val;

  void reset() => _targetIntensity = 0.0;

  void setBackground(ui.Image image) {
    _backgroundTexture
        ?.dispose(); // Ensure we don't leak if called multiple times
    _backgroundTexture = image;
  }

  void updateBackgroundTexture(ui.Image newImg) {
    final oldImg = _backgroundTexture;
    _backgroundTexture = newImg;
    // Critical: Immediately release GPU handle of the previous frame
    oldImg?.dispose();
  }

  ui.Image? get backgroundTexture => _backgroundTexture;

  void disposeResources() {
    _backgroundTexture?.dispose();
    _backgroundTexture = null;
    _noiseTexture?.dispose();
    _noiseTexture = null;
    _textureInitialized = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _mousePos = event.localEndPosition;
    if (math.Random().nextDouble() < 0.15) {
      double normalizedX = (_mousePos.x / size.x).clamp(0.0, 1.0);
      game.audio.playSpatialWaterdrop(normalizedX);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _mousePos = Vector2(-1000, -1000); // Reset when finger leaves
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Initialize noise if needed
    if (!_textureInitialized && size.x > 0) {
      _textureInitialized = true;
      _generateNoiseTexture();
    }

    // Smoothly chase target (Spring-like lerp)
    if ((currentIntensity - _targetIntensity).abs() > 0.001) {
      currentIntensity = ui.lerpDouble(
        currentIntensity,
        _targetIntensity,
        dt * _lerpFactor,
      )!;
    } else {
      currentIntensity = _targetIntensity;

      // NEW: If intensity reached zero and we aren't holding anymore, hide the component
      if (currentIntensity <= 0.001) {
        opacity = 0.0;
      }
    }

    // Audio Logic
    if (currentIntensity > 0.1) {
      // Scalar for how many drops we want at 1.0 intensity
      // 0.25 at 60fps = ~15 sounds per second
      double spawnChance = currentIntensity * 0.25;

      if (math.Random().nextDouble() < spawnChance) {
        // Logic for Panning:
        // If finger is active, 50% chance to pan to finger, 50% to random screen width
        double panX;
        // _mousePos is (-1000, -1000) when inactive
        if (_mousePos.x > 0 && math.Random().nextBool()) {
          panX = (_mousePos.x / size.x).clamp(0.0, 1.0);
        } else {
          panX = math.Random().nextDouble();
        }

        game.audio.playSpatialWaterdrop(panX);
      }
    }
  }

  void updateMousePosition(Vector2 position) {
    _mousePos = position;
  }

  Future<void> _generateNoiseTexture() async {
    // Creating a more reliable noise texture for the shader
    final int width = 512;
    final int height = 512;
    final math.Random rng = math.Random();
    final pixels = Uint8List(width * height * 4);

    for (int i = 0; i < pixels.length; i += 4) {
      pixels[i] = rng.nextInt(255); // R
      pixels[i + 1] = rng.nextInt(255); // G
      pixels[i + 2] = rng.nextInt(255); // B
      pixels[i + 3] = 255; // A
    }

    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(pixels),
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    _noiseTexture = frame.image;
    _textureInitialized = true;
  }

  @override
  void render(ui.Canvas canvas) {
    // 1. Check for texture presence.
    // If either sampler is null, CanvasKit throws the 'Sd' error.
    if (!_textureInitialized ||
        _noiseTexture == null ||
        _backgroundTexture == null) {
      return;
    }

    // 2. Check for intensity. No point in drawing if it's invisible.
    if (currentIntensity < 0.001) return;

    // Uniforms
    shader.setFloat(0, size.x);
    shader.setFloat(1, size.y);
    shader.setFloat(2, _time);
    shader.setFloat(3, currentIntensity);
    shader.setFloat(4, _mousePos.x);
    shader.setFloat(5, _mousePos.y);
    shader.setFloat(6, opacity);
    shader.setFloat(7, lightningIntensity);
    shader.setFloat(8, _crackStrength); // From Orchestrator
    shader.setFloat(9, shatterProgress); // Driven by triggerShatter
    shader.setFloat(10, _waterY); // Horizon Anchor
    shader.setFloat(11, _strikeSeed); // Lightning Randomization

    // 3. SET SAMPLERS (Order must match the shader's uniform layout)
    // iChannel0: Background (Refraction)
    // iChannel1: Noise
    shader.setImageSampler(0, _backgroundTexture!);
    shader.setImageSampler(1, _noiseTexture!);

    final paint = ui.Paint()
      ..shader = shader
      ..filterQuality = ui.FilterQuality.medium;

    canvas.drawRect(size.toRect(), paint);
  }

  Future<void> _initEmptyBackground() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0x00000000), ui.BlendMode.src);
    final picture = recorder.endRecording();
    _backgroundTexture = await picture.toImage(1, 1);
  }
}
