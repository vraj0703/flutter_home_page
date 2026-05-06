import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_physics.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/utils/extension.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/bouncy_lines.dart';

/// A component that renders an interactive UI element with text and two
/// horizontal lines that animate based on the cursor's position. Anchors
/// to the bottom of the screen — see RAJ-82.
class LogoOverlayComponent extends PositionComponent
    with PointerMoveCallbacks
    implements OpacityProvider {
  final StateProvider stateProvider;
  final Queuer queuer;

  // --- Configuration ---
  final double horizontalLineLength = GameLayout.logoOverlayHLineLength;
  final double horizontalLineGap = GameLayout.logoOverlayHLineGap;
  final double horizontalThreshold = GameLayout.logoOverlayHThreshold;

  String fullText = GameStrings.bullet;
  final Color uiColor = GameStyles.logoOverlayUi;

  final double startThickness = GameLayout.logoOverlayStartThickness;
  final double endThickness = GameLayout.logoOverlayEndThickness;
  double inactivityOpacity = 1.0;
  double _opacity = 1.0;
  final List<Color> glassyColors = GameStyles.glassyColors;
  final List<double> glassyStops = GameStyles.glassyStops;

  final BouncyLine _rightLine = BouncyLine();
  final BouncyLine _leftLine = BouncyLine();

  late final TextComponent _textComponent;
  late final flutter.TextStyle style;
  late final Shadow textShadow;
  late final Paint _materialPaint;

  final Path _rightPath = Path();
  final Path _leftPath = Path();

  Vector2 cursorPosition = Vector2.zero();
  Vector2 gameSize = Vector2.zero();

  double _textAnimationProgress = 0.0;
  final double _textAnimationSpeed = GamePhysics.logoOverlayTextAnimSpeed;
  bool _exitComplete = false;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
  }

  LogoOverlayComponent({required this.stateProvider, required this.queuer});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    _materialPaint = Paint()..style = PaintingStyle.fill;
    textShadow = Shadow(
      color: GameStyles.logoOverlayShadow,
      offset: const Offset(
        GameStyles.logoOverlayShadowOffsetX,
        GameStyles.logoOverlayShadowOffsetY,
      ),
      blurRadius: GameStyles.logoOverlayShadowBlur,
    );
    style = flutter.TextStyle(
      fontSize: GameStyles.enterFontSize,
      color: uiColor,
      letterSpacing: GameStyles.enterLetterSpacing,
      fontWeight: FontWeight.w900,
      fontFamily: GameStyles.fontBroadway,
      shadows: [textShadow.copyWith(color: GameStyles.logoOverlayShadow)],
    );
    _textComponent = TextComponent(
      text: '',
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_textComponent);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, size.y - GameLayout.logoOverlayBottomMargin);
    gameSize = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    stateProvider.sceneState().maybeWhen(
      logo: () {
        // Reset exit state when re-entering logo
        if (_exitComplete) {
          _exitComplete = false;
          _textAnimationProgress = 0.0;
          _textComponent.textRenderer = TextPaint(style: style);
        }
        _updateInteractiveState(dt);
      },
      logoOverlayRemoving: () {
        _updateRemovingStartState(dt);
      },
      orElse: () {},
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    var sceneProgress = stateProvider.revealProgress();

    const double start = ScrollSequenceConfig.logoOverlayRevealStart;
    const double range = 1.0 - start;
    final revealFade = ((sceneProgress - start) / range).clamp(0.0, 1.0);

    if (revealFade <= 0.0) {
      return;
    }
    stateProvider.sceneState().maybeWhen(
      logo: () {
        _renderBouncyLines(canvas);
      },
      logoOverlayRemoving: () {
        _renderBouncyLines(canvas);
      },
      orElse: () {},
    );
  }

  void _updateInteractiveState(double dt) {
    var sceneProgress = stateProvider.revealProgress();

    // Reveal Fade Calculation
    const double start = ScrollSequenceConfig.logoOverlayRevealStart;
    const double range = 1.0 - start;
    var opacity = ((sceneProgress - start) / range).clamp(0.0, 1.0);

    if (opacity == 0.0) return;

    // Text Reveal Calculation
    const double textStart = ScrollSequenceConfig.logoOverlayTextStart;
    const double textRange = 1.0 - textStart;
    final textProgress = ((sceneProgress - textStart) / textRange).clamp(
      0.0,
      1.0,
    );

    final charCount = (fullText.length * textProgress).floor();
    _textComponent.text = fullText.substring(0, charCount);

    if (gameSize.x == 0) return;

    final maxDisplacementX = gameSize.x / 2;
    final proportionX = (cursorPosition.x.abs() / maxDisplacementX).clamp(
      0.0,
      1.0,
    );
    final horizontalOffset = proportionX * horizontalThreshold;

    _rightLine.targetPosition = horizontalOffset;
    _leftLine.targetPosition = -horizontalOffset;

    _rightLine.update(dt);
    _leftLine.update(dt);
  }

  void _updateRemovingStartState(double dt) {
    // Guard: once exit is complete, don't re-animate
    if (_exitComplete) return;

    _textAnimationProgress += _textAnimationSpeed * dt;
    final progress = _textAnimationProgress.clamp(0.0, 1.0);

    // Fade out text opacity
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    _textComponent.textRenderer = TextPaint(
      style: style.copyWith(color: uiColor.withValues(alpha: opacity)),
    );

    final charsToRemove = (progress * fullText.length).floor();
    final remainingChars = fullText.length - charsToRemove;

    if (remainingChars > 0) {
      _textComponent.text = fullText.substring(0, remainingChars);
    } else {
      _textComponent.text = '';
      _exitComplete = true; // Prevent re-entry
      queuer.queue(event: const SceneEvent.loadTitle());
    }

    _rightLine.targetPosition = GamePhysics.bouncyLineMaxScale;
    _leftLine.targetPosition = GamePhysics.bouncyLineMaxScale;

    _rightLine.update(dt);
    _leftLine.update(dt);
  }

  void _renderBouncyLines(Canvas canvas) {
    var sceneProgress = stateProvider.revealProgress();

    const double lineStart = ScrollSequenceConfig.logoOverlayLinesStart;

    final lineFade = ((sceneProgress - lineStart) / 0.4).clamp(0.0, 1.0);
    final combinedOpacity = lineFade * _opacity;

    if (combinedOpacity > 0.0) {
      _materialPaint.color = flutter.Colors.white.withValues(
        alpha: combinedOpacity,
      );
      _renderBouncyLine(
        canvas: canvas,
        line: _rightLine,
        path: _rightPath,
        gap: horizontalLineGap,
      );
      _renderBouncyLine(
        canvas: canvas,
        line: _leftLine,
        path: _leftPath,
        gap: -horizontalLineGap,
      );
    }
  }

  void _renderBouncyLine({
    required Canvas canvas,
    required BouncyLine line,
    required Path path,
    required double gap,
  }) {
    path.reset();
    final scaledLength = horizontalLineLength * line.scale;
    final centerY = 0.0;

    final startX = line.currentPosition + gap;
    final endX = startX + (gap > 0 ? scaledLength : -scaledLength);
    path.moveTo(startX, centerY - startThickness / 2);
    path.lineTo(endX, centerY - endThickness / 2);
    path.lineTo(endX, centerY + endThickness / 2);
    path.lineTo(startX, centerY + startThickness / 2);
    path.close();
    _materialPaint.shader = Gradient.linear(
      Offset(startX, centerY - startThickness),
      Offset(startX, centerY + startThickness),
      glassyColors,
      glassyStops,
    );

    canvas.drawPath(path, _materialPaint);
  }
}
