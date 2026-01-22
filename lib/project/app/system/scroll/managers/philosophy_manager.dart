import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';

class PhilosophyManager implements SectionManager {
  final PhilosophyPageController controller;

  // Derived from previous config: 4800 - 3200 = 1600
  @override
  double get maxHeight => 1600.0;

  PhilosophyManager({required this.controller});

  @override
  void onActivate() {
    // Ensure initial state is correct (e.g. visible)
    // controller.onActivate(); // If controller needs it
  }

  @override
  void onDeactivate() {
    // Hide or cleanup
  }

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
  }
}
