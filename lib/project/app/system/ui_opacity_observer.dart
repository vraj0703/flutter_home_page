import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import '../interfaces/scroll_observer.dart';

class UIOpacityObserver extends ScrollObserver {
  final StateProvider stateProvider;

  UIOpacityObserver({required this.stateProvider});

  @override
  void onScroll(double scrollOffset) {
    // Fades out over first 100 pixels
    final opacity = (1.0 - (scrollOffset / 100)).clamp(0.0, 1.0);
    stateProvider.updateUIOpacity(opacity);
  }
}
