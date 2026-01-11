import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';
import 'vision_component.dart';
import 'hello_world_component.dart';
import 'timeline_component.dart';
import 'footer_component.dart';

import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';

class GridComponent extends PositionComponent
    with HasGameReference<MyGame>
    implements OpacityProvider {
  final FragmentShader? shader; // Optional shader

  // Data
  final List<GridItemData> items = [
    GridItemData("App Development", "Build high-performance apps."),
    GridItemData("Web Design", "Premium web experiences."),
    GridItemData("System Architecture", "Scalable backend solutions."),
    GridItemData("AI Integration", "Smart agents & automation."),
    GridItemData("Mentorship", "Guiding the next gen."),
    GridItemData("Consulting", "Strategic tech advice."),
  ];

  // Components
  VisionComponent? visionComponent;
  HelloWorldComponent? helloWorldComponent;
  TimelineComponent? timelineComponent;
  FooterComponent? footerComponent;
  final double itemHeight = 220.0;
  final double gap = 20.0;
  double topMargin = 0.0; // Set in _layout based on screen height

  // Scroll - Managed by ScrollOrchestrator

  // OpacityProvider override
  double _opacity = 0.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
  }

  final ScrollOrchestrator scrollOrchestrator;

  GridComponent({this.shader, required this.scrollOrchestrator});

  @override
  Future<void> onLoad() async {
    priority = 20;

    // Create cards
    for (int i = 0; i < items.length; i++) {
      final card = GridCard(data: items[i], index: i);
      // Set initial validation
      card.size = Vector2(300, itemHeight);
      add(card);
    }

    // Add Components
    visionComponent = VisionComponent();
    add(visionComponent!);

    helloWorldComponent = HelloWorldComponent();
    add(helloWorldComponent!);

    timelineComponent = TimelineComponent();
    add(timelineComponent!);

    footerComponent = FooterComponent();
    add(footerComponent!);

    // Start with opacity 0
    _opacity = 0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout(size);
  }

  void _layout(Vector2 size) {
    topMargin = size.y; // Ensure grid starts below the fold
    int cols = 2; // Fixed 2 columns for "premium" look (unless very narrow)
    if (size.x < 600) cols = 1;

    double contentWidth = size.x - 80; // 40px margin each side
    double cardWidth = (contentWidth - (gap * (cols - 1))) / cols;
    cardWidth = cardWidth.clamp(300.0, 600.0); // Constraint

    // Recalculate content width based on clamped card width
    double totalGridWidth = cols * cardWidth + (cols - 1) * gap;
    double startX = (size.x - totalGridWidth) / 2;

    // Position GridCards
    int i = 0;
    int rows = (items.length / cols).ceil();

    for (final child in children.whereType<GridCard>()) {
      int col = i % cols;
      int row = i ~/ cols;

      child.position = Vector2(
        startX + col * (cardWidth + gap),
        topMargin + row * (itemHeight + gap),
      );
      child.size = Vector2(cardWidth, itemHeight);
      i++;
    }

    // Position Custom Components below grid
    double currentY = topMargin + rows * (itemHeight + gap) + 80.0;

    // Helper to position and size component
    void layoutComponent(PositionComponent? comp, double height) {
      if (comp != null) {
        comp.size = Vector2(size.x, height);
        comp.position = Vector2(0, currentY);
        currentY += height + 80.0;
      }
    }

    // The instruction seems to imply a change around visionComponent layout.
    // Assuming the intent was to define visionBaseY locally for visionComponent.
    // The provided snippet was malformed, so I'm interpreting it as follows:
    // The line `visionComponent!.size = Vector2(size.x, 500);` is redundant here
    // as `layoutComponent` already sets the size.
    // The `double visionBaseY = gridEndY + 80.0;` line uses `gridEndY` which is not defined.
    // I will assume `visionBaseY` should be `currentY` at the point visionComponent is laid out.
    // Since `layoutComponent` already manages `currentY`, I will just ensure `visionComponent`
    // is laid out correctly and remove any non-existent field assignments.

    layoutComponent(visionComponent!, 500);
    layoutComponent(helloWorldComponent!, 500);
    layoutComponent(
      timelineComponent!,
      (timelineComponent != null && timelineComponent!.isLoaded)
          ? timelineComponent!.size.y
          : 1500.0,
    );
    layoutComponent(footerComponent, 300);

    // Bind Self to Scroll Orchestrator (Global Scroll Driver)
    // REMOVED: Managed externally in MyGame to ensure sequence timing.
    // scrollOrchestrator.removeBinding(this);
    // scrollOrchestrator.addBinding(...)
  }

  @override
  void update(double dt) {
    super.update(dt);

    final parentY = position.y;

    // Update Opacity and Culling for GridCards
    for (final child in children.whereType<GridCard>()) {
      // Calculate absolute Y position to determine visibility
      final absoluteY = parentY + child.position.y;

      // culling
      bool isVisible = absoluteY + child.size.y > 0 && absoluteY < game.size.y;

      // Combine parent opacity with visibility
      child.opacity = _opacity * (isVisible ? 1.0 : 0.0);
    }

    // Pass Opacity to other components
    if (_opacity > 0) {
      visionComponent?.opacity = _opacity;
      helloWorldComponent?.opacity = _opacity;
      timelineComponent?.opacity = _opacity;
      footerComponent?.opacity = _opacity;
    }
  }

  void show() {
    // Fade in
    add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.8, curve: Curves.easeOut),
      ),
    );
  }

  void hide() {
    add(OpacityEffect.to(0.0, EffectController(duration: 0.5)));
  }
}

class GridItemData {
  final String title;
  final String description;
  GridItemData(this.title, this.description);
}

class GridCard extends PositionComponent implements OpacityProvider {
  final GridItemData data;
  final int index;
  Vector2 basePosition = Vector2.zero();

  double _opacity = 1.0;
  double _lastOpacity = -1.0; // For dirty check

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
  }

  // Visuals
  late TextComponent titleText;
  late TextComponent descText;

  GridCard({required this.data, required this.index});

  @override
  Future<void> onLoad() async {
    // Setup text
    titleText = TextComponent(
      text: data.title,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'ModrntUrban',
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    // Set static positions once
    titleText.position = Vector2(24, 24);

    descText = TextComponent(
      text: data.description,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'ModrntUrban',
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
        ),
      ),
    );
    descText.position = Vector2(24, 64);

    add(titleText);
    add(descText);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only update text renderer if opacity changed effectively
    if ((_opacity - _lastOpacity).abs() > 0.01) {
      _updateTextOpacity();
      _lastOpacity = _opacity;
    }
  }

  void _updateTextOpacity() {
    // Base alpha
    final alpha = _opacity;

    titleText.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: Colors.white.withValues(alpha: alpha),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    descText.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: Colors.white.withValues(alpha: 0.7 * alpha),
        fontSize: 16,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    if (size.x == 0) return;

    final alpha = _opacity;
    if (alpha <= 0.01) return;

    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.4 * alpha)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(24),
    );

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);
  }
}
