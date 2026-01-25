import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/experience_page_controller.dart';

class ExperienceManager implements SectionManager {
  final ExperiencePageController controller;

  @override
  double get maxHeight => 2350.0;

  ExperienceManager({required this.controller});

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
  }

  @override
  ScrollResult handleScroll(double currentOffset, double delta) {
    final newOffset = currentOffset + delta;
    if (newOffset > maxHeight) {
      return ScrollOverflow(newOffset - maxHeight);
    } else if (newOffset < 0) {
      return ScrollUnderflow(newOffset);
    } else {
      return ScrollConsumed(newOffset);
    }
  }
}
