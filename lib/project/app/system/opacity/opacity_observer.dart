import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';

class OpacityObserver extends ScrollObserver {
  final StateProvider stateProvider;

  OpacityObserver({required this.stateProvider});

  @override
  void onScroll(double scrollOffset) {
    // Fades out over first 100 pixels
    final opacity = (1.0 - (scrollOffset / ScrollSequenceConfig.uiFadeDistance))
        .clamp(0.0, 1.0);
    stateProvider.updateUIOpacity(opacity);
  }
}
