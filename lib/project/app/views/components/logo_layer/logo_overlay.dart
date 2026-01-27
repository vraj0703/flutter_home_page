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

enum _LineOrientation { horizontal, vertical }

/// A component that renders an interactive UI element with circles, text,
/// and four lines that animate based on the cursor's position.
class LogoOverlayComponent extends PositionComponent
    with PointerMoveCallbacks
    implements OpacityProvider {
  final StateProvider stateProvider;
  final Queuer queuer;

  // --- Configuration ---
  final double horizontalLineLength = GameLayout.logoOverlayHLineLength;
  final double horizontalLineGap = GameLayout.logoOverlayHLineGap;
  final double horizontalThreshold = GameLayout.logoOverlayHThreshold;

  final double verticalLineLength = GameLayout.logoOverlayVLineLength;
  final double verticalLineGap = GameLayout.logoOverlayVLineGap;
  final double verticalThreshold = GameLayout.logoOverlayVThreshold;

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
  final BouncyLine _topLine = BouncyLine();
  final BouncyLine _bottomLine = BouncyLine();

  late final TextComponent _textComponent;
  late final flutter.TextStyle style;
  late final Shadow textShadow;
  late final Paint _materialPaint;

  final Path _rightPath = Path();
  final Path _leftPath = Path();
  final Path _topPath = Path();
  final Path _bottomPath = Path();

  Vector2 cursorPosition = Vector2.zero();
  Vector2 gameSize = Vector2.zero();

  double _textAnimationProgress = 0.0;
  final double _textAnimationSpeed = GamePhysics.logoOverlayTextAnimSpeed;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    _textComponent.textRenderer = TextPaint(
      style: style.copyWith(
        color: uiColor.withValues(alpha: _opacity),
        shadows: [
          textShadow.copyWith(
            color: GameStyles.logoOverlayShadow.withValues(alpha: _opacity),
          ),
        ],
      ),
    );
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
      shadows: [textShadow],
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
  void update(double dt) {
    super.update(dt);
    stateProvider.sceneState().maybeWhen(
      logo: () {
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

    if (gameSize.x == 0 || gameSize.y == 0) return;

    final maxDisplacementX = gameSize.x / 2;
    final maxDisplacementY = gameSize.y / 2;
    final proportionX = (cursorPosition.x.abs() / maxDisplacementX).clamp(
      0.0,
      1.0,
    );
    final proportionY = (cursorPosition.y.abs() / maxDisplacementY).clamp(
      0.0,
      1.0,
    );
    final horizontalOffset = proportionX * horizontalThreshold;
    final verticalOffset = proportionY * verticalThreshold;

    _rightLine.targetPosition = horizontalOffset;
    _leftLine.targetPosition = -horizontalOffset;
    _bottomLine.targetPosition = verticalOffset;
    _topLine.targetPosition = -verticalOffset;

    _rightLine.update(dt);
    _leftLine.update(dt);
    _topLine.update(dt);
    _bottomLine.update(dt);
  }

  void _updateRemovingStartState(double dt) {
    _textAnimationProgress += _textAnimationSpeed * dt;
    final charsToRemove = (_textAnimationProgress * fullText.length).floor();
    final remainingChars = fullText.length - charsToRemove;

    if (remainingChars > 0) {
      _textComponent.text = fullText.substring(0, remainingChars);
    } else {
      _textComponent.text = '';
      queuer.queue(event: SceneEvent.loadTitle());
      _textAnimationProgress = 0.0;
    }

    _rightLine.targetPosition = GamePhysics.bouncyLineMaxScale;
    _leftLine.targetPosition = GamePhysics.bouncyLineMaxScale;
    _bottomLine.targetPosition = GamePhysics.bouncyLineMaxScale;
    _topLine.targetPosition = GamePhysics.bouncyLineMaxScale;

    _rightLine.update(dt);
    _leftLine.update(dt);
    _topLine.update(dt);
    _bottomLine.update(dt);
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
        length: horizontalLineLength,
        gap: horizontalLineGap,
        orientation: _LineOrientation.horizontal,
      );
      _renderBouncyLine(
        canvas: canvas,
        line: _leftLine,
        path: _leftPath,
        length: horizontalLineLength,
        gap: -horizontalLineGap,
        orientation: _LineOrientation.horizontal,
      );
      _renderBouncyLine(
        canvas: canvas,
        line: _bottomLine,
        path: _bottomPath,
        length: verticalLineLength,
        gap: verticalLineGap,
        orientation: _LineOrientation.vertical,
      );
      _renderBouncyLine(
        canvas: canvas,
        line: _topLine,
        path: _topPath,
        length: verticalLineLength,
        gap: -verticalLineGap,
        orientation: _LineOrientation.vertical,
      );
    }
  }

  void _renderBouncyLine({
    required Canvas canvas,
    required BouncyLine line,
    required Path path,
    required double length,
    required double gap,
    required _LineOrientation orientation,
  }) {
    path.reset();
    final scaledLength = length * line.scale;
    final center = Vector2.zero();

    if (orientation == _LineOrientation.horizontal) {
      final startX = line.currentPosition + gap;
      final endX = startX + (gap > 0 ? scaledLength : -scaledLength);
      path.moveTo(startX, center.y - startThickness / 2);
      path.lineTo(endX, center.y - endThickness / 2);
      path.lineTo(endX, center.y + endThickness / 2);
      path.lineTo(startX, center.y + startThickness / 2);
      path.close();
      _materialPaint.shader = Gradient.linear(
        Offset(startX, center.y - startThickness),
        Offset(startX, center.y + startThickness),
        glassyColors,
        glassyStops,
      );
    } else {
      // Vertical
      final startY = line.currentPosition + gap;
      final endY = startY + (gap > 0 ? scaledLength : -scaledLength);
      path.moveTo(center.x - startThickness / 2, startY);
      path.lineTo(center.x - endThickness / 2, endY);
      path.lineTo(center.x + endThickness / 2, endY);
      path.lineTo(center.x + startThickness / 2, startY);
      path.close();
      _materialPaint.shader = Gradient.linear(
        Offset(center.x - startThickness, startY),
        Offset(center.x + startThickness, startY),
        glassyColors,
        glassyStops,
      );
    }

    canvas.drawPath(path, _materialPaint);
  }
}
