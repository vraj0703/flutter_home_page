import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/cursor/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';

import 'package:flutter_home_page/project/app/views/my_game.dart';
import 'package:flutter_home_page/project/app/sections/contact_section.dart';

class GameInputController extends Component with HasGameReference<MyGame> {
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
    if (!_shouldHandleInput) return;

    final state = stateProvider.sceneState();
    bool isGameState = false;
    state.maybeWhen(
      active: (_, __) => isGameState = true,
      orElse: () => isGameState = false,
    );

    final delta = info.scrollDelta.global.y;

    if (isGameState) {
      scrollSystem.onScroll(delta);

      final currentSection = game.primarySequenceRunner.currentSection;
      if (currentSection is ContactSection) {
        queuer.queue(event: const SceneEvent.toggleArrow(false));
      } else {
        queuer.queue(event: const SceneEvent.toggleArrow(true));
      }
    } else {
      queuer.queue(event: const SceneEvent.onScroll());
      LoggerUtil.log('Input', 'Scroll Delta: ${delta.toStringAsFixed(1)}');
      scrollSystem.onScroll(delta);
      audioSystem.playScrollTick();
    }
  }

  void handleTapDown(TapDownEvent event) {
    if (!_shouldHandleInput) {
      return;
    }

    audioSystem.playClick();
    LoggerUtil.log('Input', 'Tap Down at ${event.localPosition}');
    queuer.queue(event: SceneEvent.tapDown(event));
  }

  void handlePointerMove(PointerMoveEvent event) {
    // Cursor updates might be allowed even during transitions, but audio triggering should be guarded
    cursorSystem.setCursorPosition(event.localPosition);

    if (_shouldHandleInput) {
      audioSystem.playHover();
    }
  }

  void handleMouseMove(PointerHoverInfo info) {
    cursorSystem.setCursorPosition(info.eventPosition.global);

    if (_shouldHandleInput) {
      audioSystem.playHover();
    }
  }

  bool get _shouldHandleInput {
    final state = stateProvider.sceneState();
    return state.isScrollable || state.isInteractable;
  }
}
