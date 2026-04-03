import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/views/components/fade_text.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flame/events.dart';

class PhilosophyTextComponent extends PositionComponent
    with HasPaint, HasGameReference<MyGame>, HoverCallbacks {
  final String text;
  final material.TextStyle style;
  final ui.FragmentProgram shaderProgram;
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
    required this.shaderProgram,
    super.position,
    super.anchor,
  });

  @override
  void onHoverEnter() {
    game.audio.playPhilosophyTitleHover();
    game.philosophySection.triggerLightningEffect();
  }

  @override
  Future<void> onLoad() async {
    final textPainter = material.TextPainter(
      text: material.TextSpan(text: text, style: style),
      textDirection: material.TextDirection.ltr,
    );
    textPainter.layout();
    size = Vector2(textPainter.width + 40, textPainter.height + 40);

    _fadeText = FadeTextComponent(
      text: text,
      textStyle: style,
      shaderProgram: shaderProgram,
      baseColor: GameStyles.boldTextBase,
    );
    _fadeText.anchor = Anchor.center;
    _fadeText.position = size / 2;
    _fadeText.opacity = 0.0;

    add(_fadeText);
    opacity = 0.0;
  }

  /// Forces texture generation for warmup
  Future<void> warmUp() async {
    if (!isLoaded) return;
    if (textTexture != null) {
      return;
    }

    _needsTextureUpdate = true;
    final oldOpacity = opacity;
    opacity = 0.01;
    _fadeText.opacity = 1.0;

    await _updateTextTexture();
    opacity = oldOpacity;
    _fadeText.opacity = 0.0;
  }

  @override
  double get opacity => isLoaded ? _fadeText.opacity : 0.0;

  bool _hasPlayedEntrySound = false;

  @override
  set opacity(double value) {
    if (value == super.opacity) return;
    if (isLoaded) {
      _fadeText.opacity = value;

      if (value > 0.1 && !_hasPlayedEntrySound) {
        game.audio.playPhilosophyEntry();
        _hasPlayedEntrySound = true;
      } else if (value < 0.05 && _hasPlayedEntrySound) {
        _hasPlayedEntrySound = false;
      }

      if ((value - _lastOpacity).abs() > 0.1) {
        _needsTextureUpdate = true;
        _lastOpacity = value;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (showReflection && opacity > 0 && _needsTextureUpdate) {
      _updateTextTexture();
    }
  }

  /// Rasterize text to texture for shader
  Future<void> _updateTextTexture() async {
    if (!isLoaded || opacity <= 0) return;

    try {
      final textPainter = material.TextPainter(
        text: material.TextSpan(text: text, style: style),
        textDirection: material.TextDirection.ltr,
      );
      textPainter.layout();

      final neededW = textPainter.width + 40;
      final neededH = textPainter.height + 40;

      if (neededW > size.x || neededH > size.y) {
        size = Vector2(max(size.x, neededW), max(size.y, neededH));
        _fadeText.position = size / 2; // Re-center child
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.save();
      canvas.translate(size.x / 2, size.y / 2); // Center it in the texture
      _fadeText.render(canvas);
      canvas.restore();
      final picture = recorder.endRecording();

      final image = await picture.toImage(
        size.x.toInt().clamp(1, 2048),
        size.y.toInt().clamp(1, 2048),
      );

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
      debugPrint('Error updating text texture: $e');
    }
  }

  @override
  void onRemove() {
    textTexture?.dispose();
    super.onRemove();
  }
}
