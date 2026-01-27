import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/contact_page_controller.dart';

class ContactManager implements SectionManager {
  final ContactPageController controller;

  static const double _maxHeight = 3000.0;

  ContactManager({required this.controller});

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
