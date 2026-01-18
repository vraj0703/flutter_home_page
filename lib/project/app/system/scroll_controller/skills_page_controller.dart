import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';

class SkillsPageController implements ScrollObserver {
  final SkillsKeyboardComponent component;

  static const double entranceStart = ScrollSequenceConfig.skillsEntranceStart;
  static const double entranceEnd = ScrollSequenceConfig.skillsEntranceEnd;
  static const double interactEnd = ScrollSequenceConfig.skillsInteractEnd;
  static const double exitEnd = ScrollSequenceConfig.skillsExitEnd;

  SkillsPageController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    const exponentialEaseOut = ExponentialEaseOut();
    const gentleSpring = GameCurves.skillsSpring;

    if (scrollOffset < entranceStart) {
      component.opacity = 0.0;
      component.scale = Vector2.all(GameLayout.skillsInitialScale);
      component.position = Vector2.zero();
    } else if (scrollOffset < entranceEnd) {
      final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
      final curvedT = exponentialEaseOut.transform(t);
      component.opacity = curvedT;
      component.scale = Vector2.all(
        GameLayout.skillsInitialScale +
            ((1.0 - GameLayout.skillsInitialScale) * curvedT),
      );
      component.position = Vector2.zero();
    } else if (scrollOffset < interactEnd) {
      // Hold Phase
      component.opacity = 1.0;
      component.scale = Vector2.all(1.0);
      component.position = Vector2.zero();
    } else if (scrollOffset < exitEnd) {
      final t = (scrollOffset - interactEnd) / (exitEnd - interactEnd);
      final curvedT = gentleSpring.transform(t);
      component.opacity = 1.0 - exponentialEaseOut.transform(t);
      component.position = Vector2(0, GameLayout.skillsExitY * curvedT);
    } else {
      component.opacity = 0.0;
      component.position = Vector2(0, GameLayout.skillsExitY);
    }
  }
}
