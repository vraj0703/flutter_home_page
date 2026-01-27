import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';

class BoldTextManager implements SectionManager {
  final BoldTextController controller;
  final BeachBackgroundComponent beachBackground;

  static const double _maxHeight = 3200.0;

  BoldTextManager({required this.controller, required this.beachBackground});

  @override
  double onActivate(bool reverse) {
    controller.component.opacity = 1.0;
    if (reverse) {
      beachBackground.opacity = 1.0;
      return _maxHeight;
    } else {
      beachBackground.opacity = 0.0;
      return 0.0;
    }
  }

  @override
  void onDeactivate() {
    controller.component.opacity = 0.0;
    // Cloud should be at 1.0 already from onScroll fade-in
  }

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
    const fadeStart = 2700.0;
    const fadeEnd = 3200.0;

    // Warm up 300 pixels before fade starts
    if (localOffset > fadeStart - 300) {
      beachBackground.warmUp();
    }

    if (localOffset < fadeStart) {
      beachBackground.opacity = 0.0;
    } else if (localOffset < fadeEnd) {
      // Smooth fade from 0 to 1 over 500px
      final progress = (localOffset - fadeStart) / (fadeEnd - fadeStart);
      beachBackground.opacity = progress.clamp(0.0, 1.0);
    } else {
      beachBackground.opacity = 1.0;
    }
  }

  @override
  ScrollResult handleScroll(double currentOffset, double delta) {
    final newOffset = currentOffset + delta;
    if (newOffset > _maxHeight) {
      return ScrollOverflow(newOffset - _maxHeight);
    } else if (newOffset < 0) {
      return ScrollUnderflow(newOffset);
    } else {
      return ScrollConsumed(newOffset);
    }
  }
}
