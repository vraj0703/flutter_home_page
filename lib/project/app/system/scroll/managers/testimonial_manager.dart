import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/testimonial_page_controller.dart';

class TestimonialManager implements SectionManager {
  final TestimonialPageController controller;

  static const double _maxHeight = 3900.0;

  TestimonialManager({required this.controller});

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
