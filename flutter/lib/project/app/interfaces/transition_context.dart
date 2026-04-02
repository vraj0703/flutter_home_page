import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/sequence/sequence_runner.dart';

/// Minimal surface that [TransitionCoordinator] needs from the game.
///
/// Decouples the coordinator from the concrete [MyGame] class so it can be
/// tested independently and doesn't depend on the full game API.
abstract class TransitionContext {
  SequenceRunner get primarySequenceRunner;
  Queuer get queuer;
  GameAudioSystem get audio;
  CameraComponent get camera;
  void blockInput();
  void unblockInput();
}
