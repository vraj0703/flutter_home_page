import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/cloud_background_component.dart';

class BoldTextManager implements SectionManager {
  final BoldTextController controller;
  final CloudBackgroundComponent cloudBackground;

  @override
  double get maxHeight => 3200.0;

  BoldTextManager({required this.controller, required this.cloudBackground});

  @override
  void onActivate() {
    // Ensure cloud is hidden at start
    cloudBackground.opacity = 0.0;
  }

  @override
  void onDeactivate() {
    // Cloud should be at 1.0 already from onScroll fade-in
  }

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);

    // Fade in cloud background during bold text exit/flash
    // Flash happens at 2880-3040 (90-95% of 3200)
    // Start fading in slightly earlier at 2700 for smooth transition
    const fadeStart = 2700.0;
    const fadeEnd = 3200.0;

    if (localOffset < fadeStart) {
      cloudBackground.opacity = 0.0;
    } else if (localOffset < fadeEnd) {
      // Smooth fade from 0 to 1 over 500px
      final progress = (localOffset - fadeStart) / (fadeEnd - fadeStart);
      cloudBackground.opacity = progress.clamp(0.0, 1.0);
    } else {
      cloudBackground.opacity = 1.0;
    }
  }
}
