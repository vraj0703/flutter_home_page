import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/bold_text_controller.dart';

class BoldTextManager implements SectionManager {
  final BoldTextController controller;

  // 0 to 3200
  @override
  double get maxHeight => 3200.0;

  BoldTextManager({required this.controller});

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
  }
}
