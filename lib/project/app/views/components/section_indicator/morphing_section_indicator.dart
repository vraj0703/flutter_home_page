import 'package:flame/components.dart';
import 'static_dot.dart';
import 'fluid_morph_indicator.dart';

/// Main section progress indicator with vertical morphing animation
///
/// Architecture:
/// - 6 static dots (InactiveStepComponent) at fixed positions
/// - 1 fluid indicator (FluidMorphIndicator) that morphs and moves
/// - Scroll-driven with tap-to-jump functionality
class MorphingSectionIndicator extends PositionComponent {
  static const int totalSections = 6;
  static const double dotSpacing = 20.0;

  // Components
  final List<StaticDot> _dots = [];
  late FluidMorphIndicator _fluidIndicator;

  // State
  int _activeSection = 0;
  double _scrollProgress = 0.0; // Continuous 0.0 to 5.0

  // Callback for tap-to-jump
  final void Function(int section)? onSectionTap;

  MorphingSectionIndicator({this.onSectionTap}) {
    anchor = Anchor.topRight;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final totalHeight = (totalSections - 1) * dotSpacing;

    // Create static dots vertically arranged
    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final dot = StaticDot(
        sectionIndex: i,
        position: Vector2(0, y),
        onTapped: _onDotTapped,
      );
      _dots.add(dot);
      add(dot);
    }

    // Create fluid indicator starting at first dot
    _fluidIndicator = FluidMorphIndicator(
      initialPosition: _dots[0].position.clone(),
    );
    add(_fluidIndicator);
  }

  /// Handle tap on static dot
  void _onDotTapped(int index) {
    // Notify game to jump to section
    onSectionTap?.call(index);

    // Animate indicator to tapped position
    _transitionToSection(index);
  }

  /// Update continuous scroll progress (0.0 to 5.0)
  void updateScrollProgress(double progress) {
    _scrollProgress = progress.clamp(0.0, totalSections - 1.0);

    // Determine which section we're in
    final newSection = _scrollProgress.floor().clamp(0, totalSections - 1);

    // If we crossed a section boundary, animate the indicator
    if (newSection != _activeSection) {
      _activeSection = newSection;
      _transitionToSection(newSection);
    } else if (_fluidIndicator.state == MorphState.idle) {
      // Smooth follow during continuous scrolling
      _smoothFollow();
    }
  }

  /// Transition indicator to target section with animation
  void _transitionToSection(int targetSection) {
    if (targetSection < 0 || targetSection >= totalSections) return;

    final targetPos = _dots[targetSection].position.clone();

    // Calculate duration based on distance
    final distance = (targetSection - _activeSection).abs();
    final duration = 0.4 + (distance * 0.1); // 0.4s base + 0.1s per section

    _fluidIndicator.moveTo(targetPos, duration);
    _activeSection = targetSection;
  }

  /// Smooth interpolated following during continuous scroll
  void _smoothFollow() {
    // Get fractional position between sections
    final sectionIndex = _scrollProgress.floor().clamp(0, totalSections - 2);
    final fraction = _scrollProgress - sectionIndex;

    final startPos = _dots[sectionIndex].position;
    final endPos = _dots[sectionIndex + 1].position;

    // Interpolate with slight lag for smooth feel
    final targetPos = Vector2.lerp(startPos, endPos, fraction);
    final currentPos = _fluidIndicator.position;
    final diff = targetPos - currentPos;

    // Apply smooth following (15% per frame)
    _fluidIndicator.position = currentPos + diff * 0.15;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Continuously update smooth following when idle
    if (_fluidIndicator.state == MorphState.idle) {
      _smoothFollow();
    }
  }
}
