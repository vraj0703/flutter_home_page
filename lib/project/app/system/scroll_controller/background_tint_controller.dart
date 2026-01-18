import 'dart:ui';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';

class BackgroundTintController implements ScrollObserver {
  final BackgroundTintComponent component;

  // Section tint colors (subtle overlays with very low alpha)
  static const Color _heroTint = Color(0x00000000); // Transparent - default gold
  static const Color _philosophyTint = Color(0x08D89563); // Warmer gold tint
  static const Color _workExpTint = Color(0x08A0C8E8); // Blue tint
  static const Color _contactTint = Color(0x10FFD700); // Pure gold tint

  BackgroundTintController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    // Determine section and set background tint accordingly
    if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      // Hero section - no tint (default)
      component.currentTint = _heroTint;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyEnd) {
      // Philosophy section - warmer gold tint
      final t = (scrollOffset - ScrollSequenceConfig.philosophyStart) / 200.0;
      component.currentTint = Color.lerp(_heroTint, _philosophyTint, t.clamp(0.0, 1.0))!;
    } else if (scrollOffset < ScrollSequenceConfig.experienceExitEnd) {
      // Work Experience + Experience section - blue tint
      final t = (scrollOffset - ScrollSequenceConfig.philosophyEnd) / 200.0;
      component.currentTint = Color.lerp(_philosophyTint, _workExpTint, t.clamp(0.0, 1.0))!;
    } else if (scrollOffset < ScrollSequenceConfig.contactEntranceStart) {
      // Between sections - fade back to default
      final t = (scrollOffset - ScrollSequenceConfig.experienceExitEnd) /
          (ScrollSequenceConfig.contactEntranceStart - ScrollSequenceConfig.experienceExitEnd);
      component.currentTint = Color.lerp(_workExpTint, _heroTint, t.clamp(0.0, 1.0))!;
    } else if (scrollOffset < ScrollSequenceConfig.contactExitEnd) {
      // Contact section - pure gold tint
      final t = (scrollOffset - ScrollSequenceConfig.contactEntranceStart) / 200.0;
      component.currentTint = Color.lerp(_heroTint, _contactTint, t.clamp(0.0, 1.0))!;
    } else {
      // After contact section
      component.currentTint = _contactTint;
    }
  }
}
