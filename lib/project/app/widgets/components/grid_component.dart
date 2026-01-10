import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';
import 'vision_component.dart';
import 'hello_world_component.dart';
import 'timeline_component.dart';
import 'footer_component.dart';

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

  late VisionComponent visionComponent;
  late HelloWorldComponent helloWorldComponent;
  late TimelineComponent timelineComponent;
  late FooterComponent footerComponent;

  // Layout
  final double itemHeight = 220.0;
  final double gap = 20.0;
  final double topMargin = 120.0; // Start below tabs

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

  GridComponent({this.shader});

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
    visionComponent = VisionComponent();
    add(visionComponent);

    // Add Hello World Component
    helloWorldComponent = HelloWorldComponent();
    add(helloWorldComponent);

    // Add Timeline Component
    timelineComponent = TimelineComponent();
    add(timelineComponent);

    // Add Footer Component
    footerComponent = FooterComponent();
    add(footerComponent);

    // Start with opacity 0
    _opacity = 0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout(size);
  }

  void _layout(Vector2 size) {
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
    visionComponent.size = Vector2(size.x, 500);
    double visionBaseY = gridEndY + 80.0;
    _visionBaseY = visionBaseY;

    // Position Hello World Component below Vision
    helloWorldComponent.size = Vector2(size.x, 500);
    double helloWorldBaseY = visionBaseY + visionComponent.size.y + 80.0;
    _helloWorldBaseY = helloWorldBaseY;

    // Position Timeline Component
    // Initial guess for height: 350 * 4 = 1400.
    // It sets its size in onLoad, but we might be layouting before that.
    // Let's force a size here if needed? No, let component handle internal.
    // We just need space.
    double timelineHeight = 1500.0;
    // Ideally Read from component if loaded?
    if (timelineComponent.isLoaded) {
      timelineHeight = timelineComponent.size.y;
    }
    double timelineBaseY =
        helloWorldBaseY + helloWorldComponent.size.y + 0.0; // No gap? or 80 gap
    _timelineBaseY = timelineBaseY;

    // Position Footer Component
    double footerHeight = 300.0; // Approx
    footerComponent.size = Vector2(size.x, footerHeight);
    double footerBaseY = timelineBaseY + timelineHeight + 80.0;
    _footerBaseY = footerBaseY;

    // Max Scroll
    double totalContentHeight =
        footerBaseY + footerHeight + 0.0; // Last item bottom

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

    // Update VisionComponent
    visionComponent.position.y = _visionBaseY - _scrollY;
    // Vision visibility check
    bool isVisionVisible =
        visionComponent.position.y + visionComponent.size.y > 0 &&
        visionComponent.position.y < game.size.y;
    visionComponent.opacity = _opacity * (isVisionVisible ? 1.0 : 0.0);

    // Update HelloWorldComponent
    helloWorldComponent.position.y = _helloWorldBaseY - _scrollY;
    bool isHelloVisible =
        helloWorldComponent.position.y + helloWorldComponent.size.y > 0 &&
        helloWorldComponent.position.y < game.size.y;
    helloWorldComponent.opacity = _opacity * (isHelloVisible ? 1.0 : 0.0);

    // Update TimelineComponent
    timelineComponent.position.y = _timelineBaseY - _scrollY;
    bool isTimelineVisible =
        timelineComponent.position.y + timelineComponent.size.y > 0 &&
        timelineComponent.position.y < game.size.y;
    timelineComponent.opacity = _opacity * (isTimelineVisible ? 1.0 : 0.0);

    // Update FooterComponent
    footerComponent.position.y = _footerBaseY - _scrollY;
    // Footer is always visible if we scroll to bottom?
    // Culling:
    bool isFooterVisible =
        footerComponent.position.y + footerComponent.size.y > 0 &&
        footerComponent.position.y < game.size.y;
    footerComponent.opacity = _opacity * (isFooterVisible ? 1.0 : 0.0);
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
