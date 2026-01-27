import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/work_experience_title_controller.dart';

class WorkExperienceManager implements SectionManager {
  final WorkExperienceTitleController controller;

  static const double _maxHeight = 1600.0;

  WorkExperienceManager({required this.controller});

  @override
  double onActivate(bool reverse) {
    return reverse ? _maxHeight : 0.0;
  }

  @override
  void onDeactivate() {}

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
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
