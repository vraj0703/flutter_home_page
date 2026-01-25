import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/work_experience_title_controller.dart';

class WorkExperienceManager implements SectionManager {
  final WorkExperienceTitleController controller;

  // 4800 to 6400
  @override
  double get maxHeight => 1600.0;

  WorkExperienceManager({required this.controller});

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
