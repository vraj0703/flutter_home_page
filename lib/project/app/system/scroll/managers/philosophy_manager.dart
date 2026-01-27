import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';

class PhilosophyManager implements SectionManager {
  final PhilosophyPageController controller;
  final void Function() playSound;

  static const double _maxHeight = 3500.0;

  PhilosophyManager({
    required this.controller,
    //required this.cloudBackground,
    required this.playSound,
  });

  @override
  double onActivate(bool reverse) {
    controller.trailComponent.opacity = 1.0;

    if (!reverse) {
      playSound();
      return 0.0;
    }

    return _maxHeight;
  }

  @override
  void onDeactivate() {
    controller.reset();
  }

  bool _canReplayDo = false;

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
    if (localOffset > 50.0) {
      _canReplayDo = true;
    } else if (localOffset < 10.0 && _canReplayDo) {
      playSound();
      _canReplayDo = false;
    }
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
