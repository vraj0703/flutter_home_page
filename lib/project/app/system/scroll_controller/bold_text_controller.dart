import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

class BoldTextController implements ScrollObserver {
  final BoldTextRevealComponent component;
  final double screenWidth;
  final Vector2 centerPosition;

  bool _hasPlayedEntrySound = false;
  bool _hasPlayedExitSound = false;

  BoldTextController({
    required this.component,
    required this.screenWidth,
    required this.centerPosition,
  });

  @override
  void onScroll(double scrollOffset) {
    final p = (scrollOffset / ScrollSequenceConfig.boldTextEnd).clamp(0.0, 1.0);
    component.scrollProgress = p;
    component.position = centerPosition;
  }
}
