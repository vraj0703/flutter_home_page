import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';

class PhilosophyTextComponent extends PositionComponent with HasPaint {
  final String text;
  final material.TextStyle style;
  final ui.FragmentShader shader;
  late final FadeTextComponent _fadeText;

  /// Enable reflection rendering (now handled by shader)
  bool showReflection = false;

  /// Water line Y position for reflection (passed to shader)
  double waterLineY = 0.0;

  /// Text texture for shader rendering
  ui.Image? textTexture;

  /// Track if texture needs updating
  bool _needsTextureUpdate = true;
  double _lastOpacity = 0.0;

  PhilosophyTextComponent({
    required this.text,
    required this.style,
    required this.shader,
    super.position,
    super.anchor,
  });

  @override
  Future<void> onLoad() async {
    // 1. Calculate intrinsic size of text
    final textPainter = material.TextPainter(
      text: material.TextSpan(text: text, style: style),
      textDirection: material.TextDirection.ltr,
    );
    textPainter.layout();

    // Set component size to text size + padding
    size = Vector2(textPainter.width + 40, textPainter.height + 40);

    // 2. Create child component
    _fadeText = FadeTextComponent(
      text: text,
      textStyle: style,
      shader: shader,
      baseColor: GameStyles.boldTextBase,
    );
    _fadeText.anchor = Anchor.center;
    _fadeText.position = size / 2; // Center in parent
    _fadeText.opacity = 0.0; // Invisible initially

    add(_fadeText);
    opacity = 0.0;
  }

  /// Forces texture generation for warmup
  Future<void> warmUp() async {
    if (!isLoaded) return;
    if (textTexture != null)
      return; // Skip if already generated (Startup optimization)

    _needsTextureUpdate = true;
    // Temporarily set opacity > 0 for _updateTextTexture check (safe because _fadeText.opacity is 0)
    final oldOpacity = opacity;
    opacity = 0.01;
    _fadeText.opacity = 1.0; // Needs to be visible for render capture

    await _updateTextTexture();

    // Restore
    opacity = oldOpacity;
    _fadeText.opacity = 0.0;
  }

  @override
  double get opacity => _fadeText.opacity;

  @override
  set opacity(double value) {
    if (value == super.opacity) return;
    if (isLoaded) {
      _fadeText.opacity = value;

      // Mark texture for update if opacity changed significantly
      if ((value - _lastOpacity).abs() > 0.1) {
        _needsTextureUpdate = true;
        _lastOpacity = value;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Update texture if needed
    if (showReflection && opacity > 0 && _needsTextureUpdate) {
      _updateTextTexture();
    }
  }

  /// Rasterize text to texture for shader
  Future<void> _updateTextTexture() async {
    if (!isLoaded || opacity <= 0) return;

    try {
      // Re-measure text to ensure correct size (fonts might have loaded)
      final textPainter = material.TextPainter(
        text: material.TextSpan(text: text, style: style),
        textDirection: material.TextDirection.ltr,
      );
      textPainter.layout();

      // Expand size if needed (preserve center anchor)
      final neededW = textPainter.width + 40;
      final neededH = textPainter.height + 40;

      if (neededW > size.x || neededH > size.y) {
        size = Vector2(max(size.x, neededW), max(size.y, neededH));
        _fadeText.position = size / 2; // Re-center child
      }

      // Create a picture recorder to capture the text rendering
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Render the fade text component
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2); // Center it in the texture
      _fadeText.render(canvas);
      canvas.restore();

      // Convert to picture
      final picture = recorder.endRecording();

      // Convert picture to image
      final image = await picture.toImage(
        size.x.toInt().clamp(1, 2048),
        size.y.toInt().clamp(1, 2048),
      );

      // Store texture
      // Defer disposal of old texture to allow shader to finish rendering
      final oldTexture = textTexture;
      if (oldTexture != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            oldTexture.dispose();
          } catch (_) {}
        });
      }
      textTexture = image;
      _needsTextureUpdate = false;
    } catch (e) {
      // Ignore texture error
    }
  }

  @override
  void onRemove() {
    textTexture?.dispose();
    super.onRemove();
  }
}
