import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'philosophy_card.dart';
import 'package:flutter/material.dart';

class PhilosophyTrailComponent extends PositionComponent
    with HasGameReference, HasPaint {
  final List<PhilosophyCard> cards = [];
  final List<bool> _hasPlayedAudio = [false, false, false, false];

  // Smoothing Logic
  double _targetScroll = 0.0;
  double _currentScroll = 0.0;
  void Function(double smoothedOffset)? onScrollUpdate;

  // 3D Anchors (X, Y, Depth)
  final List<Vector3> _targetAnchors = [];
  final List<double> _targetRotations = [];

  PhilosophyTrailComponent() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // 1. Ensure the component itself covers the whole screen
    size = game.size;

    for (int i = 0; i < 4; i++) {
      final card = PhilosophyCard(data: cardData[i], index: i, totalCards: 4);

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
    final centerY = size.y / 2;

    // Card Base Dimensions
    final cardWidth = (size.x * 0.15).clamp(120.0, 300.0);
    final cardHeight = size.y * 0.45; // Reduced from 0.6 for shorter cards

    // Hallway Configuration
    // Outer Cards (0, 3): Closer (Z=0), Wider (X offset large)
    final outerX = size.x * 0.35;
    final outerZ = 0.0;
    final outerRot = 0.4; // ~23 deg

    // Inner Cards (1, 2): Further (Z=300), Narrower (X offset small)
    final innerX = size.x * 0.15;
    final innerZ = 300.0;
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

    // Initial State (Off-screen/Hidden) handles by updateTrailAnimation
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Inertia Logic: Lerp current -> target
    // Smoothing factor of 5.0 gives a nice "fluid" feel
    const double smoothingSpeed = 5.0;

    // Optimization: Don't update if close enough
    if ((_targetScroll - _currentScroll).abs() < 0.01) {
      if (_currentScroll != _targetScroll) {
        _currentScroll = _targetScroll;
        onScrollUpdate?.call(_currentScroll);
      }
      return;
    }

    // Simple Lerp
    _currentScroll += (_targetScroll - _currentScroll) * smoothingSpeed * dt;

    // If very close, snap to avoid jitter
    if ((_targetScroll - _currentScroll).abs() < 0.5) {
      _currentScroll = _targetScroll;
    }

    // Notify controller to update visuals (Title + Trail) based on smoothed value
    onScrollUpdate?.call(_currentScroll);
  }

  void setTargetScroll(double scroll) {
    _targetScroll = scroll;
  }

  /// Call this from your Page/Game scroll listener (Now controlled by onScrollUpdate feedback)
  /// Tri-Phase Animation: Burst (0-0.3) -> Settle (0.3-0.7) -> Lock (0.7-1.0)
  void updateTrailAnimation(double progress) {
    // Shared center for burst origin
    final center = Vector3(size.x / 2, size.y / 2, 0);

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // Normalize progress: The entire sequence happens over the scroll range passed in.
      // We process all cards simultaneously but with slightly different chaotic offsets if desired.
      // For a "Singularity" burst, they usually explode together.
      double t = progress.clamp(0.0, 1.0);

      if (t <= 0) {
        card.opacity = 0;
        continue;
      }

      // Explicit fade in
      card.opacity = (t * 3.0).clamp(0.0, 1.0);

      // --- Tri-Phase Logic ---
      Vector3 currentPos;
      double currentRot;

      final target = _targetAnchors[i];
      final targetRot = _targetRotations[i];

      if (t < 0.3) {
        // PHASE 1: SINGULARITY BURST (0.0 -> 0.3)
        // Explode from center OUTWARD past the target (Overshoot)
        final phaseT = t / 0.3;
        final ease = Curves.easeOutExpo.transform(phaseT);

        // Direction from center to target
        final direction = (target - center);
        // Overshoot by 50%
        final overshootPos = center + (direction * 1.5);

        // Lerp: Center -> Overshoot
        currentPos = center + (overshootPos - center) * ease;

        // Rotation: Chaotic Spin -> Target Rotation
        // Starts wild (e.g. +2 radians), settles towards near-target
        currentRot = targetRot + (1.0 - ease) * 2.0;
      } else if (t < 0.7) {
        // PHASE 2: FLOATING SETTLE (0.3 -> 0.7)
        // Drift from Overshoot back to Target
        final phaseT = (t - 0.3) / 0.4;
        final ease = Curves.easeInOutSine.transform(phaseT);

        final direction = (target - center);
        final overshootPos = center + (direction * 1.5);

        // Lerp: Overshoot -> Target
        currentPos = overshootPos + (target - overshootPos) * ease;

        // Rotation: Settle to exact target rotation
        currentRot = targetRot;
      } else {
        // PHASE 3: PERSPECTIVE LOCK (0.7 -> 1.0)
        // Locked in place (plus subtle hover if we added it)
        currentPos = target;
        currentRot = targetRot;
      }

      // --- Apply 3D Transform ---
      _apply3DTransform(card, currentPos, currentRot);

      // Audio Trigger (Lock-in sound)
      if (t >= 0.9 && !_hasPlayedAudio[i]) {
        (game as MyGame).playTrailCardSound(i);
        _hasPlayedAudio[i] = true;
      } else if (t < 0.5) {
        _hasPlayedAudio[i] = false;
      }
    }
  }

  void _apply3DTransform(PhilosophyCard card, Vector3 pos, double rotY) {
    // Perspective Scale
    const focalLength = 800.0;
    // Z > 0 means further away -> smaller scale
    final depth = pos.z;
    if (depth + focalLength == 0) return; // Prevent divide by zero

    final scale = focalLength / (focalLength + depth);

    // Construct Matrix
    final matrix = Matrix4.identity();

    // 1. Translate to Position
    matrix.translate(pos.x, pos.y);

    // 2. Perspective Scale (Simulating Z distance)
    matrix.scale(scale, scale, 1.0);

    // 3. Rotation Y (Tilt)
    matrix.rotateY(rotY);

    // 4. Center Anchor Adjustment
    // Since we draw from (0,0), we must shift back by half size to center the card on 'pos'
    matrix.translate(-card.size.x / 2, -card.size.y / 2);

    // Apply to card
    card.transformMat = matrix;

    // Reset standard properties to avoid conflict
    card.position = Vector2.zero();
    card.angle = 0;
    card.scale = Vector2.all(1.0);
  }
}
