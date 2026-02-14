import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_data.dart';
import 'package:flutter_home_page/project/app/models/experience_node.dart';
import 'package:flutter_home_page/project/app/views/components/experience/year_marker.dart';
import 'package:flutter_home_page/project/app/views/components/experience/information_stack.dart';
import 'package:flutter_home_page/project/app/views/components/experience/next_button_component.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class ExperienceContentComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  late final YearMarker _yearMarker;
  late final InformationStack _informationStack;
  late final NextButtonComponent _nextButton;

  int _currentIndex = 0;

  // Parallax Factors
  static const double _yearParallaxFactor = 0.02;
  static const double _infoParallaxFactor = 0.002; // Reduced for HUD lock

  ExperienceContentComponent() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // 1. Initialize Children
    _yearMarker = YearMarker();
    _informationStack = InformationStack();
    _nextButton = NextButtonComponent(onNext: _handleNextExperience);

    // 2. Add Layout
    add(_yearMarker);
    add(_informationStack);
    add(_nextButton);

    // 3. Initial Layout Setup (Will be refined in onGameResize)
    _updateLayout(game.size);

    // 4. Load Initial Data
    _updateContent(GameData.experienceNodes[_currentIndex]);

    // Start hidden, ExperienceSection handles entry
    opacity = 0.0;
  }

  void _updateLayout(Vector2 screenSize) {
    size = screenSize;

    // 1. Calculate the "Content Axis"
    // Shader rectPos 0.6 in UV space alignment.
    double contentLeft = screenSize.x * 0.58;

    // 2. Position InformationStack
    _informationStack.position = Vector2(contentLeft, screenSize.y * 0.22);
    _informationStack.updateLayout(
      screenSize,
    ); // Pass full size for vertical zoning

    // 3. Align Button to Bottom Right (Global Nav)
    _nextButton.position = Vector2(screenSize.x * 0.95, screenSize.y * 0.92);
    _nextButton.anchor = Anchor.bottomRight;

    // 4. Year Marker (Moved left to 15%)
    _yearMarker.position = Vector2(screenSize.x * 0.15, screenSize.y * 0.55);
    _yearMarker.scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Parallax Logic
    // Bind to cursorSystem
    final cursor = game.cursorSystem.lastKnownPosition;
    final center = size / 2;
    final offset = (cursor - center);

    // FIX: Use the same anchors as _updateLayout to prevent "jumping"
    final yearBase = Vector2(size.x * 0.2, size.y * 0.55);
    final infoBase = Vector2(size.x * 0.58, size.y * 0.22);

    _yearMarker.position = yearBase + (offset * -_yearParallaxFactor);
    _informationStack.position = infoBase + (offset * -_infoParallaxFactor);

    // Pass reveal progress to year marker
    //final reveal = game.experienceSection.circlesBackground.revealProgress;
    //_yearMarker.animateReveal(reveal);

    // Apply Opacity Propagation
    _informationStack.opacity = opacity;
    // _yearMarker.opacity is managed by animateReveal + parent opacity
    // But animateReveal sets it based on reveal progress.
    // We should probably letting animateReveal handle it, or multiply against a base.
    // For now, let's assume animateReveal drives it, and we just enforce visibility via renderTree.
    _nextButton.opacity = opacity;
  }

  @override
  void renderTree(Canvas canvas) {
    if (opacity <= 0.0) return;
    super.renderTree(canvas);
  }

  void _handleNextExperience() {
    game.experienceSection.nextExperience();
  }

  void cycleData() {
    _currentIndex = (_currentIndex + 1) % GameData.experienceNodes.length;
    final node = GameData.experienceNodes[_currentIndex];

    _updateContent(node);

    // Pass Theme Color to Shader
    // Shader Uniforms: 4, 5, 6 are RGB
    if (node.themeColor != null) {
      final c = node.themeColor!;
      game.experienceSection.circlesBackground.shader.setFloat(4, c.r / 255.0);
      game.experienceSection.circlesBackground.shader.setFloat(5, c.g / 255.0);
      game.experienceSection.circlesBackground.shader.setFloat(6, c.b / 255.0);
    }
  }

  void _updateContent(ExperienceNode node) {
    _yearMarker.text = node.year;
    _informationStack.updateData(node);
  }

  void animateEntry() {
    opacity = 1.0;
    _informationStack.animateIn();
  }

  void animateTextReveal() {
    _informationStack.animateIn();
  }
}
