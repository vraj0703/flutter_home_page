import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter_home_page/project/app/utils/logger_util.dart';
import 'package:flutter_home_page/project/app/models/contact_card_data.dart';
import 'contact_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_home_page/project/app/views/my_game.dart';

class ContactTrailComponent extends PositionComponent
    with HasGameReference<MyGame>, HasPaint {
  final List<ContactCard> cards = [];

  // Smoothing Logic
  double _targetScroll = 0.0;
  double _currentScroll = 0.0;
  double _velocity = 0.0;
  void Function(double smoothedOffset)? onScrollUpdate;

  // 3D Anchors (X, Y, Depth)
  final List<Vector3> _targetAnchors = [];
  final List<double> _targetRotations = [];

  // Global Hover Management
  int? _hoveredCardIndex;

  double get maxScrollExtent {
    if (cards.isEmpty) {
      LoggerUtil.log('contactTrail', 'maxScrollExtent -> 3000.0 (No Cards)');
      return 3000.0;
    }
    // Last card lock point + padding
    // rangeEnd = 1500 + i*400
    final lastIndex = cards.length - 1;
    final lastCardLock = 1500.0 + (lastIndex * 400.0);
    // LoggerUtil.log('contactTrail', 'maxScrollExtent -> ${lastCardLock + 100.0} (Cards: ${cards.length})');
    return lastCardLock + 100.0; // 100px padding
  }

  ContactTrailComponent() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // 1. Ensure the component itself covers the whole screen
    size = game.size;

    for (int i = 0; i < 4; i++) {
      final card = ContactCard(data: cardData[i], index: i, totalCards: 4);

      card.opacity = 0.0;
      card.parentOpacity = 1.0;
      card.anchor = Anchor.center;
      cards.add(card);

      // Initialize 3D lists
      _targetAnchors.add(Vector3.zero());
      _targetRotations.add(0.0);

      add(card);
    }

    _layoutCards();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size; // Maintain full-screen size
    _layoutCards();
  }

  void _layoutCards() {
    if (cards.isEmpty) return;

    final centerX = size.x / 2;
    final centerY = size.y * 0.4; // Moved up from 0.5 for better spacing

    // Card Base Dimensions
    // Wider Cards (0.20) for more presence
    final cardWidth = (size.x * 0.20).clamp(180.0, 250.0);
    final cardHeight = size.y * 0.40;

    // Hallway Configuration
    // Outer Cards (0, 3): Tighter formation (0.30)
    final outerX = size.x * 0.38;
    final outerZ = 0.0;
    final outerRot = 0.4; // ~23 deg

    // Inner Cards (1, 2): Standard gap (0.15)
    final innerX = size.x * 0.18;
    final innerZ = 280.0;
    final innerRot = 0.2; // ~11 deg

    // 0: Far Left
    _configureCard(
      0,
      -outerX + centerX,
      centerY,
      outerZ,
      cardWidth,
      cardHeight,
      outerRot,
    );

    // 1: Inner Left
    _configureCard(
      1,
      -innerX + centerX,
      centerY,
      innerZ,
      cardWidth,
      cardHeight,
      innerRot,
    );

    // 2: Inner Right
    _configureCard(
      2,
      innerX + centerX,
      centerY,
      innerZ,
      cardWidth,
      cardHeight,
      -innerRot,
    );

    // 3: Far Right
    _configureCard(
      3,
      outerX + centerX,
      centerY,
      outerZ,
      cardWidth,
      cardHeight,
      -outerRot,
    );
  }

  void _configureCard(
    int index,
    double x,
    double y,
    double z,
    double w,
    double h,
    double rotY,
  ) {
    if (index >= cards.length) return;

    final card = cards[index];
    card.size = Vector2(w, h); // Base size

    _targetAnchors[index].setValues(x, y, z);
    _targetRotations[index] = rotY;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Optimization: Skip all logic if hidden
    if (opacity <= 0.0) return;

    // Manual Hover Check (Robust Fallback)
    // Only process inputs if we are actually visible
    if (opacity > 0.01) {
      final cursor = game.cursorPosition;
      bool foundHover = false;

      // Reverse check for z-order (topmost first)
      for (int i = cards.length - 1; i >= 0; i--) {
        final card = cards[i];
        if (!foundHover && card.containsPoint(cursor)) {
          if (_hoveredCardIndex != i) {
            // Previous card exit
            if (_hoveredCardIndex != null) {
              cards[_hoveredCardIndex!].onHoverExit();
            }
            _hoveredCardIndex = i;
            LoggerUtil.log('contactTrail', 'Hover Enter -> Card $i');
            card.onHoverEnter(); // Only call once on enter
          }
          foundHover = true;
        } else {
          // Ensure non-hovered cards are reset if they were previously hovered
          // But since we track _hoveredCardIndex, we handle exit strictly there or when foundHover is false
          if (_hoveredCardIndex == i) {
            // If this was the hovered card and now we lost it (or logic changed), handled by foundHover check below?
            // Actually, the loop continues.
            // Simpler logic: Just use onHoverExit for everyone else?
            // contactCard.onHoverExit is cheap (sets bools). Is it?
            // It doesn't play sound. So calling it repeatedly is fine?
            // Let's check contactCard.onHoverExit.
            card.onHoverExit();
          }
        }
      }

      if (!foundHover) {
        if (_hoveredCardIndex != null) {
          cards[_hoveredCardIndex!].onHoverExit();
          _hoveredCardIndex = null;
        }
      }
    }

    // Spring Physics Logic (Under-Damped for Organic Bounce)
    const double stiffness = 50.0;
    const double damping = 8.0; // Reduced from 15.0 to allow overshoot
    const double mass = 1.0;

    final displacement = _targetScroll - _currentScroll;
    final force = displacement * stiffness - _velocity * damping;
    final acceleration = force / mass;

    _velocity += acceleration * dt;
    _currentScroll += _velocity * dt;

    // Snap if close and slow to prevent micro-jitter
    if (displacement.abs() < 0.5 && _velocity.abs() < 10.0) {
      _currentScroll = _targetScroll;
      _velocity = 0.0;
    }

    // Notify controller to update visuals (Title + Trail) based on smoothed value
    onScrollUpdate?.call(_currentScroll);

    // Always update animation to apply hover flips (local matrix changes)
    updateTrailAnimation(_currentScroll);
  }

  void setTargetScroll(double scroll) {
    _targetScroll = scroll;
  }

  /// Call this from your Page/Game scroll listener (Now controlled by onScrollUpdate feedback)
  /// Tri-Phase Animation: Burst (0-0.3) -> Settle (0.3-0.7) -> Lock (0.7-1.0)
  /// Tri-Phase Animation driven by specific scroll ranges
  void updateTrailAnimation(double scrollOffset) {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // Parallax Overlap Logic
      // Parallax Overlap Logic
      // Stagger start points to create rhythm (Sound triggers when opacity > 0.1)
      final double rangeStart = 1000.0 + (i * 200.0);
      // Stagger the 'Lock' point (End of animation)
      final double rangeEnd = 1500.0 + (i * 400.0);

      // Calculate progress 0.0 -> 1.0 within range
      double t = ((scrollOffset - rangeStart) / (rangeEnd - rangeStart)).clamp(
        0.0,
        1.0,
      );

      if (t <= 0) {
        card.opacity = 0;
        continue;
      }

      // Explicit fade in
      card.opacity = (t * 4.0).clamp(0.0, 1.0);

      // --- Monotonic Interpolation (Physics-Driven) ---
      Vector3 currentPos;
      double currentRot;

      final target = _targetAnchors[i];
      final targetRot = _targetRotations[i];

      // Use a single smooth curve for the entire travel
      // EaseOutCubic gives a nice strong start and soft landing
      final ease = Curves.easeOutCubic.transform(t);

      // Unified Entrance (Same for all cards)
      // "Rise Up from Below" - simple, clean, and consistent
      const double verticalOffset = 300.0;
      const double zOffset = 50.0; // Slightly behind

      final entranceOrigin = Vector3(
        target.x,
        target.y + verticalOffset,
        target.z - zOffset,
      );

      const double entranceRotation = 0.05; // Subtle unified tilt

      // Interpolate Position: Entrance -> Target
      currentPos = entranceOrigin + (target - entranceOrigin) * ease;

      // Interpolate Rotation: (Target + EntranceRot) -> Target
      // Note: We want to spin *into* the target rotation
      final startRot = targetRot + (2.0 + entranceRotation);
      currentRot = startRot + (targetRot - startRot) * ease;

      // No manual overshoot math here!
      // The `t` itself will overshoot because `_currentScroll` overshoots due to physics.

      if (t > 0.5) {
        // Trigger haptic when unlocking flip
        if (!card.canFlip) {
          HapticFeedback.lightImpact();
        }
        card.canFlip = true;
      } else {
        card.canFlip = false;
        // Ensure card resets if we scroll back up
        if (card.isFlipped) card.forceResetFlip();
      }

      _apply3DTransform(card, currentPos, currentRot);
    }
  }

  void _apply3DTransform(ContactCard card, Vector3 pos, double rotY) {
    // Initial Hide Check
    // If Z is 0 and pos is 0, it might be uninitialized.
    // But our logic above sets position.

    // Perspective Scale
    const focalLength = 1000.0; // Matches React 'perspective:1000px'
    // Z > 0 means further away -> smaller scale
    final depth = pos.z;
    if (depth + focalLength == 0) return; // Prevent divide by zero

    final scale = focalLength / (focalLength + depth);

    // Construct Matrix
    final matrix = Matrix4.identity();

    matrix.multiply(Matrix4.translationValues(pos.x, pos.y, 0.0));

    matrix.multiply(Matrix4.diagonal3Values(scale, scale, 1.0));

    matrix.rotateY(rotY);

    // Apply Interactive Tilt (3D Hover)
    // Map -1..1 tilt to approx +/- 11 degrees (0.2 rad)
    matrix.rotateX(card.currentTilt.y * 0.25);
    matrix.rotateY(card.currentTilt.x * 0.25);

    final stableHitMatrix = matrix.clone();
    stableHitMatrix.multiply(
      Matrix4.translationValues(-card.size.x / 2, -card.size.y / 2, 0.0),
    );
    card.hitboxMatrix = stableHitMatrix;
    matrix.rotateY(card.flipProgress * math.pi);

    matrix.multiply(
      Matrix4.translationValues(-card.size.x / 2, -card.size.y / 2, 0.0),
    );

    card.transformMat = matrix;
    card.position = Vector2.zero();
    card.angle = 0;
    card.scale = Vector2.all(1.0);
  }
}
