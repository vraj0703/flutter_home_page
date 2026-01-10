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

  VisionComponent? visionComponent;
  HelloWorldComponent? helloWorldComponent;
  TimelineComponent? timelineComponent;
  FooterComponent? footerComponent;

  // Layout
  final double itemHeight = 220.0;
  final double gap = 20.0;
  double topMargin = 0.0; // Set in _layout based on screen height

  // Scroll
  double _scrollY = 0.0;
  double _targetScrollY = 0.0;
  double _maxScroll = 0.0;

  // OpacityProvider override
  double _opacity = 0.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
  }

  final ScrollSystem scrollSystem;
  final ScrollOrchestrator scrollOrchestrator;

  GridComponent({
    this.shader,
    required this.scrollSystem,
    required this.scrollOrchestrator,
  });

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

    // Add Vision Component
    // Add Vision Component
    visionComponent = VisionComponent();
    add(visionComponent!);

    // Add Hello World Component
    helloWorldComponent = HelloWorldComponent();
    add(helloWorldComponent!);

    // Add Timeline Component
    timelineComponent = TimelineComponent();
    add(timelineComponent!);

    // Add Footer Component
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

    // Position children
    int i = 0;
    int rows = (items.length / cols).ceil();

    for (final child in children.whereType<GridCard>()) {
      int col = i % cols;
      int row = i ~/ cols;

      child.basePosition = Vector2(
        startX + col * (cardWidth + gap),
        topMargin + row * (itemHeight + gap),
      );
      child.size = Vector2(cardWidth, itemHeight);
      i++;
    }

    // Position Vision Component below grid
    double gridEndY = topMargin + rows * (itemHeight + gap);

    // Vision Component layout
    if (visionComponent != null) {
      visionComponent!.size = Vector2(size.x, 500);
      double visionBaseY = gridEndY + 80.0;
      _visionBaseY = visionBaseY;

      // Bind Scroll Effect (Standard Parallax/Scroll)
      scrollOrchestrator.removeBinding(visionComponent!);
      scrollOrchestrator.addBinding(
        visionComponent!,
        ParallaxScrollEffect(
          startScroll: 0,
          endScroll: 100000,
          initialPosition: Vector2(0, _visionBaseY),
          endOffset: Vector2(0, -100000),
        ),
      );
    }

    // Position Hello World Component below Vision
    if (helloWorldComponent != null) {
      helloWorldComponent!.size = Vector2(size.x, 500);
      double helloWorldBaseY =
          (_visionBaseY > 0 ? _visionBaseY : gridEndY) +
          (visionComponent?.size.y ?? 0) +
          80.0;
      _helloWorldBaseY = helloWorldBaseY;

      scrollOrchestrator.removeBinding(helloWorldComponent!);
      scrollOrchestrator.addBinding(
        helloWorldComponent!,
        ParallaxScrollEffect(
          startScroll: 0,
          endScroll: 100000,
          initialPosition: Vector2(0, _helloWorldBaseY),
          endOffset: Vector2(0, -100000),
        ),
      );
    }

    // Position Timeline Component
    double timelineHeight = 1500.0;
    if (timelineComponent != null && timelineComponent!.isLoaded) {
      timelineHeight = timelineComponent!.size.y;
    }

    if (timelineComponent != null) {
      double timelineBaseY =
          _helloWorldBaseY + (helloWorldComponent?.size.y ?? 0) + 80.0;
      if (_helloWorldBaseY == 0) timelineBaseY = gridEndY + 200; // Fallback
      _timelineBaseY = timelineBaseY;

      scrollOrchestrator.removeBinding(timelineComponent!);
      scrollOrchestrator.addBinding(
        timelineComponent!,
        ParallaxScrollEffect(
          startScroll: 0,
          endScroll: 100000,
          initialPosition: Vector2(0, _timelineBaseY),
          endOffset: Vector2(0, -100000),
        ),
      );
    }

    // Position Footer Component
    double footerHeight = 300.0; // Approx
    if (footerComponent != null) {
      footerComponent!.size = Vector2(size.x, footerHeight);
      double footerBaseY = _timelineBaseY + timelineHeight + 80.0;
      _footerBaseY = footerBaseY;

      scrollOrchestrator.removeBinding(footerComponent!);
      scrollOrchestrator.addBinding(
        footerComponent!,
        ParallaxScrollEffect(
          startScroll: 0,
          endScroll: 100000,
          initialPosition: Vector2(0, _footerBaseY),
          endOffset: Vector2(0, -100000),
        ),
      );
    }

    // Max Scroll
    double totalContentHeight =
        _footerBaseY + footerHeight + 0.0; // Last item bottom

    double visibleHeight = size.y;
    _maxScroll = (totalContentHeight - visibleHeight).clamp(
      0.0,
      double.infinity,
    );
  }

  double _visionBaseY = 0.0;
  double _helloWorldBaseY = 0.0;
  double _timelineBaseY = 0.0;
  double _footerBaseY = 0.0;

  void onScroll(double delta) {
    if (_opacity < 0.1) return; // Don't scroll if not visible

    _targetScrollY += delta * 1.5; // Multiplier/Speed
    _targetScrollY = _targetScrollY.clamp(0.0, _maxScroll);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth scroll
    final double diff = _targetScrollY - _scrollY;
    if (diff.abs() > 0.1) {
      _scrollY += diff * 10 * dt;
    } else {
      _scrollY = _targetScrollY;
    }

    // Sync ScrollSystem
    scrollSystem.setScrollOffset(_scrollY);

    // Update GridCards
    for (final child in children.whereType<GridCard>()) {
      child.position.y = child.basePosition.y - _scrollY;
      child.position.x = child.basePosition.x; // Ensure X is stable

      // culling
      bool isVisible =
          child.position.y + child.size.y > 0 && child.position.y < game.size.y;

      // Combine parent opacity with visibility
      child.opacity = _opacity * (isVisible ? 1.0 : 0.0);
    }

    // Components managed by ScrollSystem (Positioning)

    // Opacity Sync regarding page transition
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
          color: Colors.white.withOpacity(0.7),
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
        color: Colors.white.withOpacity(alpha),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    descText.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'ModrntUrban',
        color: Colors.white.withOpacity(0.7 * alpha),
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
      ..color = const Color(0xFF1A1A1A).withOpacity(0.4 * alpha)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.1 * alpha)
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
