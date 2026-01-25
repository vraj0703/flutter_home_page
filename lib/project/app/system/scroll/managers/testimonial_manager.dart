import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/testimonial_page_controller.dart';

class TestimonialManager implements SectionManager {
  final TestimonialPageController controller;

  // 8750 to 12650
  @override
  double get maxHeight => 3900.0;

  TestimonialManager({required this.controller});

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
