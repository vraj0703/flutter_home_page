import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';

import 'bouncy_lines.dart';

enum _LineOrientation { horizontal, vertical }

/// A component that renders an interactive UI element with circles, text,
/// and four lines that animate based on the cursor's position.
class LogoOverlayComponent extends PositionComponent with PointerMoveCallbacks {
  final StateProvider stateProvider;
  final Queuer queuer;

  // --- Configuration ---
  final double ratio = 1;
  final double outerRadius = 135.0;
  final double innerRadius = 95.0;

  final double horizontalLineLength = 80.0;
  final double horizontalLineGap = 120.0;
  final double horizontalThreshold = 300.0;

  final double verticalLineLength = 70.0;
  final double verticalLineGap = 120.0;
  final double verticalThreshold = 150.0;

  final String _fullText = 'START';
  final Color uiColor = const Color(0xFF9A482F);

  final double startThickness = 3.0; // Thickness near the center
  final double endThickness = 0.5; // Thickness at the far end
  double inactivityOpacity = 1.0;

  final List<Color> glassyColors = [
    const Color.fromRGBO(214, 166, 95, 0.2), // Faint Edge Highlight
    const Color.fromRGBO(169, 95, 59, 0.05), // Darker transparent part
    const Color.fromRGBO(154, 72, 47, 0.7), // Sharp Central Highlight
    const Color.fromRGBO(169, 95, 59, 0.05), // Darker transparent part
    const Color.fromRGBO(214, 166, 95, 0.2), // Faint Edge Highlight
  ];
  final List<double> glassyStops = [
    0.0, // Start edge
    0.4, // Start of central highlight
    0.5, // Peak of highlight
    0.6, // End of central highlight
    1.0, // End edge
  ];

  final BouncyLine _rightLine = BouncyLine();
  final BouncyLine _leftLine = BouncyLine();
  final BouncyLine _topLine = BouncyLine();
  final BouncyLine _bottomLine = BouncyLine();

  late final TextComponent _textComponent;
  late final Paint _materialPaint;

  final Path _rightPath = Path();
  final Path _leftPath = Path();
  final Path _topPath = Path();
  final Path _bottomPath = Path();

  Vector2 cursorPosition = Vector2.zero();
  Vector2 gameSize = Vector2.zero();

  double _textAnimationProgress = 0.0;
  final double _textAnimationSpeed = 2; // Controls speed of typing/deleting

  LogoOverlayComponent({required this.stateProvider, required this.queuer});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set the component's anchor to its center for easy positioning.
    anchor = Anchor.center;

    // Configure the paint object for drawing circles and lines.
    _materialPaint = Paint()..style = PaintingStyle.fill;

    // Create and add the central text.
    _textComponent = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: flutter.TextStyle(
          fontSize: 15.0,
          color: uiColor,
          letterSpacing: 10.0,
          fontWeight: FontWeight.w900,
          fontFamily: 'Broadway',
          shadows: [
            Shadow(
              color: const Color(0xFFD6A65F), // Shadow color with opacity
              offset: const Offset(2.0, 2.0), // X and Y displacement
              blurRadius: 10.0, // Blur radius of the shadow
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2, // Positioned at the center of this component
    );
    add(_textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        _updateInteractiveState(dt);
      },
      logoOverlayRemoving: () {
        _updateRemovingStartState(dt);
      },
      titleLoading: () {},
      title: () {},
    );
  }

  void _updateInteractiveState(double dt) {
    var sceneProgress = stateProvider.revealProgress();
    var opacity = ((sceneProgress - 0.2) / 0.8).clamp(0.0, 1.0);
    if (opacity == 0.0) return;

    final textProgress = ((sceneProgress - 0.5) / 0.5).clamp(0.0, 1.0);
    final charCount = (_fullText.length * textProgress).floor();
    _textComponent.text = _fullText.substring(0, charCount);

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
    final charsToRemove = (_textAnimationProgress * _fullText.length).floor();
    final remainingChars = _fullText.length - charsToRemove;

    if (remainingChars > 0) {
      _textComponent.text = _fullText.substring(0, remainingChars);
    } else {
      _textComponent.text = '';
      queuer.queue(event: SceneEvent.loadTitle());
      _textAnimationProgress = 0.0;
    }

    // For now, let's reset lines to zero.
    _rightLine.targetPosition = 0;
    _leftLine.targetPosition = 0;
    _bottomLine.targetPosition = 0;
    _topLine.targetPosition = 0;

    _rightLine.update(dt);
    _leftLine.update(dt);
    _topLine.update(dt);
    _bottomLine.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    var sceneProgress = stateProvider.revealProgress();
    final revealFade = ((sceneProgress - 0.2) / 0.8).clamp(0.0, 1.0);
    if (revealFade <= 0.0) {
      return; // Exit early if not yet visible.
    }
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        _renderBouncyLines(canvas);
      },
      logoOverlayRemoving: () {
        _renderBouncyLines(canvas);
      },
      titleLoading: () {},
      title: () {},
    );
  }

  void _renderBouncyLines(Canvas canvas) {
    var sceneProgress = stateProvider.revealProgress();
    final lineFade = ((sceneProgress - 0.4) / 0.4).clamp(0.0, 1.0);
    if (lineFade > 0.0) {
      _materialPaint.color = flutter.Colors.white.withValues(alpha: lineFade);
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

    // The logic is split based on orientation, but it's all in one place.
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
