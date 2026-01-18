import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class SectionProgressIndicator extends PositionComponent with HasPaint, TapCallbacks {
  static const int totalSections = 6;
  static const double dotSize = 8.0;
  static const double dotSpacing = 20.0;
  static const double hitAreaRadius = 15.0; // Larger tap area
  static const double dropletSize = 12.0; // Water droplet size
  static const Color inactiveColor = Color(0x40FFFFFF); // White 25%
  static const Color activeColor = Color(0xFFFFC107); // Gold
  static const Color dropletColor = Color(0xFFFFD700); // Bright gold droplet

  double _scrollProgress = 0.0; // Continuous scroll progress (0.0 to totalSections-1)
  double _animationTime = 0.0; // For idle animation

  final Paint _inactivePaint = Paint()..color = inactiveColor;
  final Paint _activePaint = Paint()..color = activeColor;
  final Paint _dropletPaint = Paint()
    ..color = dropletColor
    ..style = PaintingStyle.fill;

  // Callback when a section is tapped
  void Function(int section)? onSectionTap;

  SectionProgressIndicator({this.onSectionTap}) {
    anchor = Anchor.topRight;
  }

  // Update with continuous scroll progress instead of discrete section
  void updateScrollProgress(double progress) {
    _scrollProgress = progress.clamp(0.0, totalSections - 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final totalHeight = (totalSections - 1) * dotSpacing;

    // Draw all dots
    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final center = Offset(0, y);

      // Calculate proximity to current scroll position
      final distanceFromProgress = (_scrollProgress - i).abs();

      // Dots closer to current position are more active
      if (distanceFromProgress < 0.5) {
        final proximity = 1.0 - (distanceFromProgress / 0.5);
        final color = Color.lerp(inactiveColor, activeColor, proximity)!;
        final paint = Paint()..color = color;
        canvas.drawCircle(center, dotSize / 2, paint);
      } else {
        // Inactive dots
        canvas.drawCircle(center, dotSize / 2, _inactivePaint);
      }
    }

    // Draw water droplet at continuous position
    final dropletY = (_scrollProgress * dotSpacing) - (totalHeight / 2);
    final dropletCenter = Offset(0, dropletY);

    // Breathing animation for droplet
    final breathe = math.sin(_animationTime * 3.0) * 0.15 + 1.0;
    final currentDropletSize = dropletSize * breathe;

    // Draw droplet glow (outer)
    final glowPaint = Paint()
      ..color = dropletColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(dropletCenter, currentDropletSize / 2 + 3, glowPaint);

    // Draw droplet core
    canvas.drawCircle(dropletCenter, currentDropletSize / 2, _dropletPaint);

    // Draw highlight on droplet (water effect)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6);
    final highlightOffset = Offset(-currentDropletSize * 0.15, -currentDropletSize * 0.15);
    canvas.drawCircle(
      dropletCenter + highlightOffset,
      currentDropletSize * 0.25,
      highlightPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Convert tap position to local coordinates
    final localPos = event.localPosition;

    // Calculate which dot was tapped
    final totalHeight = (totalSections - 1) * dotSpacing;

    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final dotCenter = Offset(0, y);

      // Check if tap is within hit area of this dot
      final distance = (localPos - dotCenter).distance;
      if (distance <= hitAreaRadius) {
        // Notify callback
        onSectionTap?.call(i);
        break;
      }
    }
  }
}
