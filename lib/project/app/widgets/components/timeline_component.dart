import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/widgets/components/experience_data.dart';
import 'package:flutter_home_page/project/app/widgets/components/timeline_card.dart';
import 'package:flutter_home_page/project/app/widgets/components/timeline_node.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

class TimelineComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint
    implements OpacityProvider {
  // OpacityProvider
  double _opacity = 1.0;
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    _opacity = value;
    _updateOpacity(value);
  }

  late PositionComponent _contentContainer;
  final double spacing = 350.0; // Vertical spacing

  @override
  Future<void> onLoad() async {
    // Determine width based on game size or fixed
    width = game.size.x;

    _contentContainer = PositionComponent();
    add(_contentContainer);

    double currentY = 0;
    double centerX = width / 2;

    for (int i = 0; i < _experiences.length; i++) {
      final data = _experiences[i];

      // 1. Node (Center line)
      final node = TimelineNode(
        position: Vector2(centerX, currentY),
        isStart: i == 0,
        isEnd: i == _experiences.length - 1,
      );
      _contentContainer.add(node);

      // 2. Card
      // Alternating sides? Or just one side for simplicity?
      // Let's do alternating for "premium" feel.
      bool isLeft = i % 2 == 0;
      double cardX = isLeft ? centerX - 320 : centerX + 20;
      // Node width is small, let's say 20 padding from center.

      final card = TimelineCard(
        data: data,
        position: Vector2(cardX, currentY - 20), // Align top with node roughly
        size: Vector2(300, 300),
      );
      _contentContainer.add(card);

      currentY += spacing;
    }

    // Add connecting line
    // Vertical line at centerX
    final totalH = (spacing * (_experiences.length - 1));
    _contentContainer.add(TimelineLine(totalH, centerX)..priority = -1);

    // Set size
    size = Vector2(width, currentY); // height is total accumulated Y

    _opacity = 0;
  }

  void _updateOpacity(double alpha) {
    if (!isLoaded) return;

    // Propagate to children manually because not all might check parent opacity automatically
    // specially custom implementations like TimelineLine or Card text.

    for (final child in _contentContainer.children) {
      if (child is OpacityProvider) {
        (child as OpacityProvider).opacity = alpha;
      } else if (child is HasPaint) {
        child.opacity = alpha;
      }
      // GridCard/TimelineCard might handle their own opacity or need explicit set
      // Assuming TimelineCard implements OpacityProvider or similar logic check below.
    }
  }

  final List<ExperienceData> _experiences = [
    const ExperienceData(
      year: "09/2021 - Present",
      role: "Senior Software Engineer",
      company: "Twin Health",
      description:
          "Architected scalable mobile frameworks and real-time communication bridges between Flutter, Android, and medical sensors. Led cross-functional teams to deliver AI features and reduced APK size by 10% while achieving zero hotfixes via robust CI/CD.",
    ),
    const ExperienceData(
      year: "02/2017 - 08/2021",
      role: "Senior Software Developer",
      company: "Flick2Know Technologies",
      description:
          "Laid groundwork for 7 Android apps and mentored a team of engineers. Transformed platform APIs for low-latency communication and established streamlined CI/CD pipelines using Azure DevOps and Fastlane.",
    ),
    const ExperienceData(
      year: "06/2016 - 02/2017",
      role: "Software Developer",
      company: "PayU India",
      description:
          "Contributed to the PayU Cred Android app, focusing on secure credit card management and analytics capabilities within a 15-member team.",
    ),
    const ExperienceData(
      year: "2012 - 2016",
      role: "B.Tech in CSE",
      company: "MNNIT Allahabad",
      description:
          "Engineered algorithms for cloud scheduling and developed multiple Android apps including games and college festival applications.",
    ),
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Timeline might need relayout if width changes drastically,
    // but for now let's assume static width or simple centering.
    if (isLoaded) {
      this.width = size.x;
      // Updating children positions on resize is complex without full rebuild.
      // We'll leave it simple for now.
    }
  }
}

class TimelineLine extends PositionComponent with HasPaint {
  final double height;
  final double centerX;

  TimelineLine(this.height, this.centerX) {
    priority = -1;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) return;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, height),
      Paint()
        ..color = const Color(0xFFC78E53).withValues(alpha: 0.5 * opacity)
        ..strokeWidth = 2,
    );
  }
}
