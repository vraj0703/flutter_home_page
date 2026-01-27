import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/cursor/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';

class GameInputController extends Component {
  final Queuer queuer;
  final ScrollSystem scrollSystem;
  final GameAudioSystem audioSystem;
  final GameCursorSystem cursorSystem;
  final StateProvider stateProvider;

  GameInputController({
    required this.queuer,
    required this.scrollSystem,
    required this.audioSystem,
    required this.cursorSystem,
    required this.stateProvider,
  });

  // Handle Scroll (Delegated from Game)
  void handleScroll(PointerScrollInfo info) {
    queuer.queue(event: const SceneEvent.onScroll());

    final delta = info.scrollDelta.global.y;
    scrollSystem.onScroll(delta);
    audioSystem.playScrollTick();
  }

  void handleTapDown(TapDownEvent event) {
    audioSystem.playClick();
    queuer.queue(event: SceneEvent.tapDown(event));
  }

  void handlePointerMove(PointerMoveEvent event) {
    cursorSystem.setCursorPosition(event.localPosition);
    audioSystem.playHover();
  }

  void handleMouseMove(PointerHoverInfo info) {
    cursorSystem.setCursorPosition(info.eventPosition.global);
    audioSystem.playHover();
  }
}
