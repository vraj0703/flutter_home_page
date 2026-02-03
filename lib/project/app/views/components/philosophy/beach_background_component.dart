import 'dart:ui';
import 'package:flame/components.dart';

import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_scene_orchestrator.dart';

class BeachBackgroundComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final FragmentShader shader;
  BeachSceneOrchestrator? orchestrator;
  double opacity = 0.0;

  /// Time accumulator for shader animation
  double _time = 0.0;
  late Image _dummyTexture;
  final List<PositionComponent> reflectionTargets = [];
  double _waterY = 0.0;
  int _warmupFrames = 0;

  // Ripple effect state
  Vector2 _rippleOrigin = Vector2.zero();
  double _rippleTime = -999.0; // Negative = no active ripple

  // Scroll progress for sky gradient
  double _scrollProgress = 0.0;

  BeachBackgroundComponent({super.size, required this.shader}) {
    opacity = 0.001;
  }

  /// Set the orchestrator and add it to component tree
  void setOrchestrator(BeachSceneOrchestrator orch) {
    orchestrator = orch;
    // Add orchestrator to component tree so it gets update() calls
    add(orch);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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

  bool _manualWarmup = false;
  int _manualWarmupFrames = 0;

  void warmUp() {
    // Keep alive logic: if called repeatedly, we stay in warmup mode.
    _manualWarmup = true;
    _manualWarmupFrames = 0; // Reset timer
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_warmupFrames < 3) {
      _warmupFrames++;
      if (_warmupFrames == 3) {
        if (opacity <= 0.002) {
          opacity = 0.0;
        }
      }
    }

    // Update time for shader animation
    _time += dt;

    // Update ripple animation time
    if (_rippleTime >= 0.0) {
      _rippleTime += dt;
      if (_rippleTime > 2.0) _rippleTime = -999.0; // Reset after 2 seconds
    }

    // warmup auto-off after 120 frames (~2sec @ 60fps)
    if (_manualWarmup) {
      _manualWarmupFrames++;
      if (_manualWarmupFrames > 120) {
        _manualWarmup = false;
      }
    }

    if (opacity <= 0.0 && !_manualWarmup) return;
  }

  /// Emit a ripple at the given screen position
  void emitRipple(Vector2 origin) {
    _rippleOrigin = origin.clone();
    _rippleTime = 0.0;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0 && !_manualWarmup) return;
    final effectiveOpacity = (opacity <= 0.0 && _manualWarmup) ? 0.01 : opacity;
    double texW = 0.0;
    double texH = 0.0;
    Image samplerImage = _dummyTexture;
    Image? reflTexture = orchestrator?.reflection.reflectionTexture;

    try {
      if (reflTexture != null) {
        texW = reflTexture.width.toDouble();
        texH = reflTexture.height.toDouble();
        samplerImage = reflTexture;
      }
    } catch (_) {}

    try {
      double dpr = game.canvasSize.x / game.size.x;
      shader.setFloat(0, size.x);
      shader.setFloat(1, size.y);
      shader.setFloat(2, _time);
      shader.setFloat(3, 0.0);
      shader.setFloat(4, _waterY);
      shader.setFloat(5, 1.0);
      shader.setFloat(6, 1.0);
      shader.setFloat(7, texW);
      shader.setFloat(8, texH);
      shader.setFloat(9, 0.0);
      shader.setFloat(10, dpr);
      shader.setFloat(11, effectiveOpacity);

      final lightningIntensity = orchestrator?.lightning.intensity ?? 0.0;
      final panicLevel = orchestrator?.birds.panicLevel ?? 0.0;

      shader.setFloat(12, lightningIntensity); // uLightning
      shader.setFloat(13, panicLevel); // uPanic
      shader.setFloat(14, _rippleOrigin.x); // uRippleOrigin.x
      shader.setFloat(15, _rippleOrigin.y); // uRippleOrigin.y
      shader.setFloat(16, _rippleTime); // uRippleTime
      shader.setFloat(17, _scrollProgress); // uScrollProgress

      // Set sampler (safe image)
      shader.setImageSampler(0, samplerImage);

      // Always draw to prevent black screen
      canvas.drawRect(size.toRect(), Paint()..shader = shader);
    } catch (_) {}
  }

  /// Set text reflection data for shader rendering
  /// Register a component to be reflected
  void registerReflectionTarget(PositionComponent target) {
    if (!reflectionTargets.contains(target)) {
      reflectionTargets.add(target);
    }
  }

  void setWaterLevel(double y) {
    _waterY = y;
  }

  void setScrollProgress(double progress) {
    _scrollProgress = progress.clamp(0.0, 1.0);
  }
}
