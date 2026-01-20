import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class BoldTextRevealComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  final FragmentShader shader;
  final TextStyle textStyle;
  final String text;

  ui.Image? _textTexture;
  double _scrollProgress = 0.0;
  double _lastProgress = 0.0;
  bool _hasPlayedTing = false;

  BoldTextRevealComponent({
    required this.shader,
    required this.text,
    required this.textStyle,
    super.position,
    super.anchor = Anchor.center,
  });

  double get scrollProgress => _scrollProgress;

  set scrollProgress(double value) {
    if (_scrollProgress == value) return;
    double velocity = (value - _lastProgress).abs();

    _lastProgress = _scrollProgress;
    _scrollProgress = value;
    game.syncBoldTextAudio(value, velocity: velocity);
    if (value >= 0.42 && _lastProgress < 0.42 && !_hasPlayedTing) {
      _hasPlayedTing = true;
      game.playTing();
    }

    if (value < 0.35) {
      _hasPlayedTing = false;
    }
  }

  @override
  Future<void> onLoad() async {
    await _generateTextTexture();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  Future<void> _generateTextTexture() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paintStyle = textStyle.copyWith(color: const Color(0xFFDDDDDD));

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: paintStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const double padding = 60.0;
    final width = textPainter.width + padding * 2;
    final height = textPainter.height + padding * 2;
    textPainter.paint(canvas, const Offset(padding, padding));

    final picture = recorder.endRecording();
    _textTexture = await picture.toImage(width.ceil(), height.ceil());
  }

  @override
  void render(Canvas canvas) {
    if (_textTexture == null) return;

    final paint = Paint();

    // Shader Uniforms
    // 0: uSize (vec2) - Screen Size
    // 1: uScrollProgress (float)
    // 2: uTextSize (vec2) - Text Texture Size
    // 3: uTexture (sampler2D)

    shader.setFloat(0, size.x);
    shader.setFloat(1, size.y);
    shader.setFloat(2, _scrollProgress);
    shader.setFloat(3, _textTexture!.width.toDouble());
    shader.setFloat(4, _textTexture!.height.toDouble());
    shader.setImageSampler(0, _textTexture!);

    paint.shader = shader;

    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void onRemove() {
    _textTexture?.dispose();
    super.onRemove();
  }
}
