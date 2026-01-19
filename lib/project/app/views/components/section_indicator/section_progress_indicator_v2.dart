import 'dart:ui';
import 'package:flame/components.dart';
import 'inactive_step_component.dart';
import 'fluid_indicator_component.dart';
import 'indicator_state.dart';

/// Main section progress indicator with fluid morphing animation
class SectionProgressIndicatorV2 extends PositionComponent {
  static const int totalSections = 6;
  static const double dotSpacing = 20.0;

  final List<InactiveStepComponent> _staticDots = [];
  late FluidIndicatorComponent _fluidIndicator;

  double _scrollProgress = 0.0;
  int _currentSection = 0;
  double _previousProgress = 0.0;

  // Callback when a section is tapped
  void Function(int section)? onSectionTap;

  // Section durations for animation timing (in scroll units)
  final List<double> _sectionDurations = [
    400.0, // Section 0->1
    1700.0, // Section 1->2
    1700.0, // Section 2->3
    2450.0, // Section 3->4
    3900.0, // Section 4->5
    200.0, // Section 5 (minimal)
  ];

  SectionProgressIndicatorV2({this.onSectionTap}) {
    anchor = Anchor.topRight;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final totalHeight = (totalSections - 1) * dotSpacing;

    // Create static dots
    for (int i = 0; i < totalSections; i++) {
      final y = i * dotSpacing - (totalHeight / 2);
      final dot = InactiveStepComponent(
        index: i,
        position: Vector2(0, y),
        onTap: _handleDotTap,
      );
      _staticDots.add(dot);
      add(dot);
    }

    // Create fluid indicator at first dot position
    final firstDotPos = _staticDots[0].position.clone();
    _fluidIndicator = FluidIndicatorComponent(initialPosition: firstDotPos);
    add(_fluidIndicator);
  }

  /// Handle dot tap - move to that section
  void _handleDotTap(int index) {
    if (index >= 0 && index < totalSections) {
      // Notify game to jump to section
      onSectionTap?.call(index);

      // Animate indicator to tapped position
      _animateToSection(index, immediate: false);
    }
  }

  /// Update scroll progress (continuous 0.0 to totalSections-1)
  void updateScrollProgress(double progress) {
    final newProgress = progress.clamp(0.0, totalSections - 1.0);
    final delta = newProgress - _scrollProgress;

    _previousProgress = _scrollProgress;
    _scrollProgress = newProgress;

    // Determine current section
    final newSection = _scrollProgress.floor().clamp(0, totalSections - 1);

    // Check if we crossed a section boundary
    if (newSection != _currentSection && delta.abs() > 0.01) {
      _currentSection = newSection;
      _animateToSection(newSection, immediate: false);
    } else if (_fluidIndicator.state == IndicatorState.idle) {
      // For continuous scrolling within a section, smoothly follow
      _updateFluidPosition();
    }
  }

  /// Animate fluid indicator to target section
  void _animateToSection(int targetSection, {required bool immediate}) {
    if (targetSection < 0 || targetSection >= totalSections) return;

    final targetPos = _staticDots[targetSection].position.clone();

    if (immediate) {
      _fluidIndicator.position = targetPos;
      _currentSection = targetSection;
    } else {
      // Calculate animation duration based on section duration
      // Use a base duration of 0.3 seconds, but scale with distance
      final distance = (targetSection - _currentSection).abs();
      final baseDuration = 0.3;
      final duration = baseDuration + (distance * 0.1);

      _fluidIndicator.moveTo(targetPos, duration);
      _currentSection = targetSection;
    }
  }

  /// Update fluid position for smooth continuous scrolling
  void _updateFluidPosition() {
    // Interpolate position based on fractional progress
    final sectionIndex = _scrollProgress.floor().clamp(0, totalSections - 2);
    final sectionFraction = _scrollProgress - sectionIndex;

    if (sectionIndex < totalSections - 1) {
      final startPos = _staticDots[sectionIndex].position;
      final endPos = _staticDots[sectionIndex + 1].position;
      final targetPos = Vector2.lerp(startPos, endPos, sectionFraction);

      // Only update if not currently in a move animation
      if (_fluidIndicator.state == IndicatorState.idle) {
        // Smooth follow with slight lag
        final currentPos = _fluidIndicator.position;
        final diff = targetPos - currentPos;
        _fluidIndicator.position = currentPos + diff * 0.15;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Continuously update position during idle state for smooth following
    if (_fluidIndicator.state == IndicatorState.idle) {
      _updateFluidPosition();
    }
  }
}
