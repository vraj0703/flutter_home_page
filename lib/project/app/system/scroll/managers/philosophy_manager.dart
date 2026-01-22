import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/cloud_background_component.dart';

class PhilosophyManager implements SectionManager {
  final PhilosophyPageController controller;
  final CloudBackgroundComponent cloudBackground;
  final void Function() playSound;

  @override
  double get maxHeight => 3000.0;

  PhilosophyManager({
    required this.controller,
    required this.cloudBackground,
    required this.playSound,
  });

  @override
  void onActivate() {
    // Cloud should already be at 1.0 from BoldTextManager fade-in
    // Just ensure it stays visible
    cloudBackground.opacity = 1.0;

    // Play philosophy entry sound
    playSound();
  }

  @override
  void onDeactivate() {
    // Hide beach shader background when leaving Philosophy
    cloudBackground.opacity = 0.0;
  }

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
    // Keep cloud fully visible throughout Philosophy section
    cloudBackground.opacity = 1.0;
  }
}
