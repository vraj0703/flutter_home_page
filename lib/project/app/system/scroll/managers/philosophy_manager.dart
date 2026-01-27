import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_controller/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';

class PhilosophyManager implements SectionManager {
  final PhilosophyPageController controller;
  //final BeachBackgroundComponent cloudBackground;
  final void Function() playSound;

  static const double _maxHeight = 3500.0;

  PhilosophyManager({
    required this.controller,
    //required this.cloudBackground,
    required this.playSound,
  });

  @override
  double onActivate(bool reverse) {
    // Cloud should already be at 1.0 from BoldTextManager fade-in
    // Just ensure it stays visible
    //cloudBackground.opacity = 1.0;

    // Ensure trail component is visible (cards handle their own opacity)
    controller.trailComponent.opacity = 1.0;

    if (!reverse) {
      // Play philosophy entry sound only on forward entry
      playSound();
      return 0.0;
    }

    return _maxHeight;
  }

  @override
  void onDeactivate() {
    // Hide beach shader background when leaving Philosophy
    // Switch back to Run (Gold) or let BoldText handle it
    //cloudBackground.opacity = 0.0;
    // Enforce clean exit for title/cards/reflection
    controller.reset();
  }

  bool _canReplayDo = false;

  @override
  void onScroll(double localOffset) {
    controller.onScroll(localOffset);
    // Keep cloud fully visible throughout Philosophy section
    //cloudBackground.opacity = 1.0;

    // Logic to replay "Do" when returning to 0
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
